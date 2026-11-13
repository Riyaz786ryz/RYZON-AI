import http from "node:http";
import { timingSafeEqual } from "node:crypto";

const PORT = Number(process.env.PORT || 8080);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.8-flash";
const BACKEND_TOKEN = process.env.RYZON_BACKEND_TOKEN;
const MAX_BODY_BYTES = 32 * 1024;
const WINDOW_MS = 60_000;
const MAX_REQUESTS_PER_WINDOW = 10;
const requestsByIp = new Map();

const TASKS = {
  story: {
    required: "idea",
    max: 2000,
    instruction: (input) =>
      `Write an original, engaging cartoon story in ${input.language || "Tamil"}. Audience: ${input.audience || "family"}. Theme: ${input.genre || "adventure"}. Story idea: ${input.idea}. Return a title, short character list, beginning, middle, ending, and a simple moral if suitable. Do not claim to create a video or image.`,
  },
  dialogue: {
    required: "scene",
    max: 2000,
    instruction: (input) =>
      `Write natural cartoon character dialogue in ${input.language || "Tamil"}. Scene: ${input.scene}. Characters: ${input.characters || "Create suitable characters"}. Tone: ${input.tone || "expressive and family-friendly"}. Label each speaker clearly and include brief emotion cues in brackets.`,
  },
  scenes: {
    required: "story",
    max: 5000,
    instruction: (input) =>
      `Turn this story into a practical cartoon storyboard in ${input.language || "Tamil"}: ${input.story}. Create ${Math.min(Math.max(Number(input.sceneCount) || 5, 3), 12)} scenes. For each scene give location, characters, action, expression, camera framing, and dialogue. Keep character appearance consistent. This is a text storyboard only, not a rendered video.`,
  },
};

function send(res, status, payload) {
  res.writeHead(status, {
    "content-type": "application/json; charset=utf-8",
    "cache-control": "no-store",
    "x-content-type-options": "nosniff",
  });
  res.end(JSON.stringify(payload));
}

function isAuthorized(req) {
  const header = req.headers.authorization || "";
  const supplied = Buffer.from(header.startsWith("Bearer ") ? header.slice(7) : "");
  const expected = Buffer.from(BACKEND_TOKEN || "");
  return expected.length >= 32 &&
    supplied.length === expected.length &&
    timingSafeEqual(supplied, expected);
}

function allowRequest(req) {
  const ip = req.socket.remoteAddress || "unknown";
  const now = Date.now();
  const current = requestsByIp.get(ip);
  if (!current || now - current.startedAt >= WINDOW_MS) {
    requestsByIp.set(ip, { startedAt: now, count: 1 });
    return true;
  }
  if (current.count >= MAX_REQUESTS_PER_WINDOW) return false;
  current.count += 1;
  return true;
}

async function readJson(req) {
  let body = "";
  for await (const chunk of req) {
    body += chunk;
    if (Buffer.byteLength(body, "utf8") > MAX_BODY_BYTES) {
      const error = new Error("Request body too large");
      error.statusCode = 413;
      throw error;
    }
  }
  try {
    return JSON.parse(body || "{}");
  } catch {
    const error = new Error("Invalid JSON body");
    error.statusCode = 400;
    throw error;
  }
}

async function generateWithGemini(prompt) {
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(GEMINI_MODEL)}:generateContent?key=${encodeURIComponent(GEMINI_API_KEY)}`;
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "content-type": "application/json" },
    signal: AbortSignal.timeout(45_000),
    body: JSON.stringify({
      contents: [{ role: "user", parts: [{ text: prompt }] }],
      generationConfig: { temperature: 0.8, maxOutputTokens: 4096 },
    }),
  });

  if (!response.ok) {
    // Do not forward provider response bodies: they may contain sensitive diagnostics.
    const error = new Error(
      response.status === 429
        ? "Gemini usage limit reached. Please try again later."
        : response.status >= 500
          ? "Gemini service is temporarily unavailable."
          : "Gemini request was rejected. Check the server model and API configuration."
    );
    error.statusCode = response.status === 429 ? 429 : 502;
    throw error;
  }

  const data = await response.json();
  const text = (data.candidates?.[0]?.content?.parts || [])
    .map((part) => part.text || "")
    .join("")
    .trim();

  if (!text) {
    const error = new Error("Gemini returned no text for this request.");
    error.statusCode = 502;
    throw error;
  }
  return text;
}

const server = http.createServer(async (req, res) => {
  if (req.method === "GET" && req.url === "/health") {
    return send(res, 200, { ok: true, service: "ryzon-ai-cloud-backend" });
  }

  const taskName = req.url?.split("?")[0]?.match(/^\/v1\/ai\/(story|dialogue|scenes)$/)?.[1];
  if (req.method !== "POST" || !taskName) {
    return send(res, 404, { error: "Route not found" });
  }

  if (!isAuthorized(req)) {
    return send(res, 401, { error: "Unauthorized" });
  }
  if (!allowRequest(req)) {
    return send(res, 429, { error: "Too many requests. Please wait and try again." });
  }

  try {
    const input = await readJson(req);
    const task = TASKS[taskName];
    const value = input?.[task.required];
    if (typeof value !== "string" || value.trim().length < 3 || value.length > task.max) {
      return send(res, 400, {
        error: `"${task.required}" must be text between 3 and ${task.max} characters.`,
      });
    }

    const result = await generateWithGemini(task.instruction(input));
    return send(res, 200, {
      ok: true,
      task: taskName,
      model: GEMINI_MODEL,
      result,
    });
  } catch (error) {
    const status = Number.isInteger(error.statusCode) ? error.statusCode : 500;
    if (status === 500) {
      // Keep API keys, prompts, and provider diagnostics out of application logs.
      console.error("RYZON AI backend request failed:", error.name || "Error");
    }
    return send(res, status, {
      error: status === 500 ? "Internal server error" : error.message,
    });
  }
});

if (!GEMINI_API_KEY) {
  console.error("Missing GEMINI_API_KEY. Configure it in the hosting environment.");
  process.exit(1);
}
if (!BACKEND_TOKEN || BACKEND_TOKEN.length < 32) {
  console.error("RYZON_BACKEND_TOKEN must be at least 32 characters.");
  process.exit(1);
}

server.listen(PORT, "0.0.0.0", () => {
  console.log(`RYZON AI backend listening on port ${PORT}`);
});
