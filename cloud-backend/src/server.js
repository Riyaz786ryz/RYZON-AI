import http from "node:http";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";

const PORT = Number(process.env.PORT || 8080);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.8-flash";
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_IMAGE_MODEL = process.env.OPENAI_IMAGE_MODEL || "gpt-image-2";
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "ryzon-ai";

initializeApp({ credential: applicationDefault(), projectId: FIREBASE_PROJECT_ID });
const firebaseAuth = getAuth();
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

async function verifyUser(req) {
  const header = req.headers.authorization || "";
  if (!header.startsWith("Bearer ")) return null;
  try {
    const decoded = await firebaseAuth.verifyIdToken(header.slice(7), true);
    return { uid: decoded.uid, email: decoded.email || null };
  } catch {
    return null;
  }
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

async function readJson(req, maxBytes = MAX_BODY_BYTES) {
  let body = "";
  for await (const chunk of req) {
    body += chunk;
    if (Buffer.byteLength(body, "utf8") > maxBytes) {
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

async function generateCartoonImage(input) {
  if (!OPENAI_API_KEY) {
    const error = new Error("Photo-to-Cartoon is not enabled yet. Configure OPENAI_API_KEY securely on the backend.");
    error.statusCode = 503;
    throw error;
  }

  const mimeType = input.mimeType;
  if (!["image/jpeg", "image/png", "image/webp"].includes(mimeType)) {
    const error = new Error("Photo must be a JPG, PNG, or WebP image.");
    error.statusCode = 400;
    throw error;
  }
  if (typeof input.imageBase64 !== "string" ||
      !/^[A-Za-z0-9+/]+={0,2}$/.test(input.imageBase64)) {
    const error = new Error("A valid base64 photo is required.");
    error.statusCode = 400;
    throw error;
  }

  const imageBytes = Buffer.from(input.imageBase64, "base64");
  if (!imageBytes.length || imageBytes.length > 12 * 1024 * 1024) {
    const error = new Error("Photo must be smaller than 12 MB.");
    error.statusCode = 413;
    throw error;
  }
  const isPng = imageBytes.length >= 8 &&
    imageBytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]));
  const isJpeg = imageBytes.length >= 3 &&
    imageBytes[0] === 0xff && imageBytes[1] === 0xd8 && imageBytes[2] === 0xff;
  const isWebp = imageBytes.length >= 12 &&
    imageBytes.toString("ascii", 0, 4) === "RIFF" &&
    imageBytes.toString("ascii", 8, 12) === "WEBP";
  if ((mimeType === "image/png" && !isPng) ||
      (mimeType === "image/jpeg" && !isJpeg) ||
      (mimeType === "image/webp" && !isWebp)) {
    const error = new Error("The photo content does not match its file type.");
    error.statusCode = 400;
    throw error;
  }

  const styles = {
    "3d": "high-quality polished 3D animated family movie character",
    anime: "beautiful hand-drawn anime animation style",
    pixar: "expressive cinematic 3D family animation style",
    comic: "colorful comic-book illustration style",
    watercolor: "soft detailed watercolor cartoon illustration",
  };
  const style = styles[input.style] || styles["3d"];
  const prompt = [
    "Transform the provided photograph into a polished cartoon character image.",
    "Preserve the person's recognizable facial identity, age appearance, hairstyle, pose, and clothing as closely as possible.",
    "Do not add extra people. Keep the same number of visible people as in the source photo.",
    "Style: " + style + ".",
    "Create a clean, detailed image suitable as a character reference for a cartoon movie.",
    "Do not add text, logos, or watermarks.",
  ].join(" ");

  const dataUrl = `data:${mimeType};base64,${imageBytes.toString("base64")}`;
  const response = await fetch("https://api.openai.com/v1/images/edits", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      authorization: `Bearer ${OPENAI_API_KEY}`,
    },
    signal: AbortSignal.timeout(180_000),
    body: JSON.stringify({
      model: OPENAI_IMAGE_MODEL,
      images: [{ image_url: dataUrl }],
      prompt,
      size: "1024x1024",
      quality: "medium",
      output_format: "png",
    }),
  });

  if (!response.ok) {
    const error = new Error(
      response.status === 429
        ? "Image generation limit reached. Please try again later."
        : response.status >= 500
          ? "Image generation service is temporarily unavailable."
          : "Image generation request was rejected. Check the server model and API access."
    );
    error.statusCode = response.status === 429 ? 429 : 502;
    throw error;
  }

  const data = await response.json();
  const imageBase64 = data.data?.[0]?.b64_json;
  if (typeof imageBase64 !== "string" || !imageBase64.length) {
    const error = new Error("Image provider returned no generated image.");
    error.statusCode = 502;
    throw error;
  }
  return imageBase64;
}

async function generateWithGemini(prompt) {
  if (!GEMINI_API_KEY) {
    const error = new Error("Story and dialogue AI is not enabled yet. Configure GEMINI_API_KEY securely on the backend.");
    error.statusCode = 503;
    throw error;
  }
  const endpoint = `https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(GEMINI_MODEL)}:generateContent`;
  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-goog-api-key": GEMINI_API_KEY,
    },
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
    return send(res, 200, { ok: true, service: "ryzone-cloud-backend" });
  }

  const taskName = req.url?.split("?")[0]?.match(/^\/v1\/ai\/(story|dialogue|scenes)$/)?.[1];
  if (req.method !== "POST" || !taskName) {
    return send(res, 404, { error: "Route not found" });
  }

  const user = await verifyUser(req);
  if (!user) {
    return send(res, 401, { error: "Valid Firebase sign-in required" });
  }
  if (!allowRequest(req)) {
    return send(res, 429, { error: "Too many requests. Please wait and try again." });
  }

  try {
    const input = await readJson(req, isPhotoToCartoon ? 17 * 1024 * 1024 : MAX_BODY_BYTES);
    if (isPhotoToCartoon) {
      if (typeof input?.imageBase64 !== "string" || typeof input?.mimeType !== "string") {
        return send(res, 400, { error: "Photo data and MIME type are required." });
      }
      const imageBase64 = await generateCartoonImage(input);
      return send(res, 200, { ok: true, task: "photo-to-cartoon", mimeType: "image/png", imageBase64 });
    }
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
      userId: user.uid,
      task: taskName,
      model: GEMINI_MODEL,
      result,
    });
  } catch (error) {
    const status = Number.isInteger(error.statusCode) ? error.statusCode : 500;
    if (status === 500) {
      // Keep API keys, prompts, and provider diagnostics out of application logs.
      console.error("RYZONE backend request failed:", error.name || "Error");
    }
    return send(res, status, {
      error: status === 500 ? "Internal server error" : error.message,
    });
  }
});

if (!GEMINI_API_KEY && !OPENAI_API_KEY) {
  console.error("Configure GEMINI_API_KEY and/or OPENAI_API_KEY in the hosting environment.");
  process.exit(1);
}
// Firebase Admin uses Application Default Credentials from the hosting platform.


server.listen(PORT, "0.0.0.0", () => {
  console.log(`RYZONE backend listening on port ${PORT}`);
});
