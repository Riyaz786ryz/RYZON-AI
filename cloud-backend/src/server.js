import http from "node:http";
import { randomUUID } from "node:crypto";
import { initializeApp, applicationDefault } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { getFirestore, FieldValue } from "firebase-admin/firestore";
import { boundedText, isValidTextInput } from "./validation.js";
import { renderSlideshowMp4, validateVideoRenderInput } from "./video-render.js";
import { getWalletSummary, creditWalletCreditsFromVerifiedPayment } from "./wallet.js";
import { CREDIT_PACKAGES, verifyRazorpayWebhookSignature, parseCapturedRazorpayPayment } from "./razorpay.js";

const PORT = Number(process.env.PORT || 8080);
const GEMINI_API_KEY = process.env.GEMINI_API_KEY;
const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-3.8-flash";
const GEMINI_TTS_MODEL = process.env.GEMINI_TTS_MODEL || "gemini-3.8-flash-tts";
const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_IMAGE_MODEL = process.env.OPENAI_IMAGE_MODEL || "gpt-image-2";
const FIREBASE_PROJECT_ID = process.env.FIREBASE_PROJECT_ID || "ryzon-ai";
const RAZORPAY_KEY_ID = process.env.RAZORPAY_KEY_ID;
const RAZORPAY_KEY_SECRET = process.env.RAZORPAY_KEY_SECRET;
const RAZORPAY_WEBHOOK_SECRET = process.env.RAZORPAY_WEBHOOK_SECRET;

initializeApp({ credential: applicationDefault(), projectId: FIREBASE_PROJECT_ID });
const firebaseAuth = getAuth();
const firebaseDb = getFirestore();
const MAX_BODY_BYTES = 32 * 1024;
const MAX_TTS_BODY_BYTES = 64 * 1024;
const WINDOW_MS = 60_000;
const MAX_REQUESTS_PER_WINDOW = 10;
const requestsByIp = new Map();

const TASKS = {
  story: {
    required: "idea",
    max: 2000,
    instruction: (input) =>
      `Write an original, engaging cartoon story in ${boundedText(input.language, 40, "Tamil")}. Audience: ${boundedText(input.audience, 40, "family")}. Theme: ${boundedText(input.genre, 60, "adventure")}. Story idea: ${input.idea}. Return a title, short character list, beginning, middle, ending, and a simple moral if suitable. Do not claim to create a video or image.`,
  },
  dialogue: {
    required: "scene",
    max: 2000,
    instruction: (input) =>
      `Write natural cartoon character dialogue in ${input.language || "Tamil"}. Scene: ${input.scene}. Characters: ${boundedText(input.characters, 500, "Create suitable characters")}. Tone: ${boundedText(input.tone, 80, "expressive and family-friendly")}. Label each speaker clearly and include brief emotion cues in brackets.`,
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
    return {
      uid: decoded.uid,
      email: decoded.email || null,
      displayName: decoded.name || null,
      photoURL: decoded.picture || null,
    };
  } catch {
    return null;
  }
}


async function getOrCreateUserData(user) {
  const profileRef = firebaseDb.collection("users").doc(user.uid);
  const walletRef = firebaseDb.collection("wallets").doc(user.uid);

  return firebaseDb.runTransaction(async (transaction) => {
    const [profileSnapshot, walletSnapshot] = await Promise.all([
      transaction.get(profileRef),
      transaction.get(walletRef),
    ]);

    const now = FieldValue.serverTimestamp();
    if (!profileSnapshot.exists) {
      transaction.create(profileRef, {
        uid: user.uid,
        email: user.email,
        displayName: user.displayName,
        photoURL: user.photoURL,
        createdAt: now,
        updatedAt: now,
      });
    } else {
      const profile = profileSnapshot.data() || {};
      const updates = { updatedAt: now };
      if (user.email && profile.email !== user.email) updates.email = user.email;
      if (user.displayName && profile.displayName !== user.displayName) updates.displayName = user.displayName;
      if (user.photoURL && profile.photoURL !== user.photoURL) updates.photoURL = user.photoURL;
      transaction.set(profileRef, updates, { merge: true });
    }

    if (!walletSnapshot.exists) {
      transaction.create(walletRef, {
        uid: user.uid,
        currency: "INR",
        balancePaise: 0,
        reservedPaise: 0,
        status: "active",
        createdAt: now,
        updatedAt: now,
      });
    }

    const profileData = profileSnapshot.exists
      ? { ...profileSnapshot.data(), email: user.email || profileSnapshot.data()?.email || null,
          displayName: user.displayName || profileSnapshot.data()?.displayName || null,
          photoURL: user.photoURL || profileSnapshot.data()?.photoURL || null }
      : { uid: user.uid, email: user.email, displayName: user.displayName, photoURL: user.photoURL };
    const walletData = walletSnapshot.exists
      ? walletSnapshot.data()
      : { uid: user.uid, currency: "INR", balancePaise: 0, reservedPaise: 0, status: "active" };

    return { profile: profileData, wallet: walletData };
  });
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


async function readRawBody(req, maxBytes = 1024 * 1024) {
  const chunks = [];
  let total = 0;
  for await (const chunk of req) {
    total += chunk.length;
    if (total > maxBytes) {
      const error = new Error("Request body too large");
      error.statusCode = 413;
      throw error;
    }
    chunks.push(chunk);
  }
  return Buffer.concat(chunks, total);
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

async function generateSpeech(input) {
  if (!GEMINI_API_KEY) {
    const error = new Error("AI voice is not enabled yet. Configure GEMINI_API_KEY securely on the backend.");
    error.statusCode = 503;
    throw error;
  }
  const text = typeof input.text === "string" ? input.text.trim() : "";
  if (!isValidTextInput(text, 3000, 1)) {
    const error = new Error("Voice text must contain between 1 and 3000 characters.");
    error.statusCode = 400;
    throw error;
  }
  const voices = new Set(["Kore", "Puck", "Charon", "Aoede", "Fenrir", "Leda", "Orus", "Zephyr"]);
  const voiceName = voices.has(input.voiceName) ? input.voiceName : "Kore";
  const language = typeof input.language === "string" ? input.language.slice(0, 40) : "Tamil";
  // Gemini 3.8 TTS uses the Interactions API and returns a complete WAV file
  // for non-streaming requests (24 kHz, mono, 16-bit PCM).
  const response = await fetch(
    "https://generativelanguage.googleapis.com/v1beta/interactions",
    {
      method: "POST",
      headers: { "content-type": "application/json", "x-goog-api-key": GEMINI_API_KEY },
      signal: AbortSignal.timeout(180_000),
      body: JSON.stringify({
        model: GEMINI_TTS_MODEL,
        input: [{
          type: "user_input",
          content: [{
            type: "text",
            text,
            annotations: [{
              type: "speech_metadata",
              style: "Speak clearly and naturally in " + language + ".",
            }],
          }],
        }],
        response_format: { type: "audio" },
        generation_config: { speech_config: [{ voice: voiceName }] },
      }),
    },
  );
  if (!response.ok) {
    const error = new Error(response.status === 429
      ? "AI voice usage limit reached. Please try again later."
      : "AI voice service rejected the request or is temporarily unavailable.");
    error.statusCode = response.status === 429 ? 429 : 502;
    throw error;
  }
  const data = await response.json();
  const audioPart = (data.steps || [])
    .filter((step) => step.type === "model_output")
    .flatMap((step) => step.content || [])
    .filter((part) => part.type === "audio" && typeof part.data === "string")
    .at(-1);
  if (!audioPart?.data) {
    const error = new Error("AI voice service returned no playable audio. Please try a shorter text.");
    error.statusCode = 502;
    throw error;
  }
  return { audioBase64: audioPart.data, mimeType: "audio/wav" };
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

  const route = req.url?.split("?")[0] || "";
  const taskName = route.match(/^\/v1\/ai\/(story|dialogue|scenes)$/)?.[1];
  const isMe = route === "/v1/me";
  const isWallet = route === "/v1/wallet";
  const isWalletTransactions = route === "/v1/wallet/transactions";
  const isRazorpayOrder = route === "/v1/payments/razorpay/order";
  const isRazorpayWebhook = route === "/v1/webhooks/razorpay";
  const isPhotoToCartoon = route === "/v1/media/photo-to-cartoon";
  const isTextToSpeech = route === "/v1/media/text-to-speech";
  const isVideoRender = route === "/v1/media/render-video";
  if ((req.method !== "POST" && !(req.method === "GET" && (isMe || isWallet || isWalletTransactions))) || (!taskName && !isPhotoToCartoon && !isTextToSpeech && !isVideoRender && !isMe && !isWallet && !isWalletTransactions && !isRazorpayOrder)) {
    return send(res, 404, { error: "Route not found" });
  }

  if (isRazorpayWebhook) {
    if (req.method !== "POST") return send(res, 405, { error: "Method not allowed" });
    if (!RAZORPAY_WEBHOOK_SECRET) return send(res, 503, { error: "Payment webhook is not configured" });
    try {
      const rawBody = await readRawBody(req);
      const signature = req.headers["x-razorpay-signature"] || "";
      if (!verifyRazorpayWebhookSignature(rawBody, signature, RAZORPAY_WEBHOOK_SECRET)) {
        return send(res, 400, { error: "Invalid payment webhook signature" });
      }
      let payload;
      try { payload = JSON.parse(rawBody.toString("utf8")); }
      catch { return send(res, 400, { error: "Invalid webhook JSON" }); }
      const payment = parseCapturedRazorpayPayment(payload);
      if (!payment) return send(res, 200, { received: true, ignored: true });
      const orderSnapshot = await firebaseDb.collection("razorpayOrders").doc(payment.orderId).get();
      if (!orderSnapshot.exists) return send(res, 400, { error: "Payment order not found" });
      const order = orderSnapshot.data();
      if (order.amountPaise !== payment.amountPaise || order.currency !== payment.currency) {
        return send(res, 400, { error: "Payment amount or currency mismatch" });
      }
      const result = await creditWalletCreditsFromVerifiedPayment(firebaseDb, {
        uid: order.uid,
        paymentId: payment.paymentId,
        orderId: payment.orderId,
        amountPaise: payment.amountPaise,
        credits: order.credits,
      });
      return send(res, 200, { received: true, credited: !result.duplicate, duplicate: result.duplicate });
    } catch (error) {
      const status = Number.isInteger(error.statusCode) ? error.statusCode : 500;
      if (status === 500) console.error("RYZONE Razorpay webhook failed:", error.name || "Error");
      return send(res, status, { error: status === 500 ? "Webhook processing failed" : error.message });
    }
  }

  const user = await verifyUser(req);
  if (!user) {
    return send(res, 401, { error: "Valid Firebase sign-in required" });
  }
  if (!allowRequest(req)) {
    return send(res, 429, { error: "Too many requests. Please wait and try again." });
  }

  try {
    if (isMe) {
      const account = await getOrCreateUserData(user);
      return send(res, 200, { ok: true, ...account });
    }
    if (isWallet) {
      const wallet = await getWalletSummary(firebaseDb, user.uid);
      return send(res, 200, { ok: true, wallet });
    }
    if (isWalletTransactions) {
      const snapshot = await firebaseDb.collection("walletLedger")
        .where("uid", "==", user.uid)
        .orderBy("createdAt", "desc")
        .limit(50)
        .get();
      const transactions = snapshot.docs
        .map((doc) => {
          const item = doc.data();
          const createdAt = item.createdAt?.toDate
            ? item.createdAt.toDate().toISOString()
            : item.createdAt instanceof Date
              ? item.createdAt.toISOString()
              : null;
          return {
            id: doc.id,
            type: item.type || "transaction",
            amountPaise: Number.isSafeInteger(item.amountPaise) ? item.amountPaise : 0,
            createdAt,
          };
        })
        .sort((a, b) => (b.createdAt || "").localeCompare(a.createdAt || ""))
        .slice(0, 50);
      return send(res, 200, { ok: true, transactions });
    }
    if (isRazorpayOrder) {
      if (!RAZORPAY_KEY_ID || !RAZORPAY_KEY_SECRET) {
        return send(res, 503, { error: "Razorpay payments are not configured yet" });
      }
      const input = await readJson(req);
      const selectedPackage = CREDIT_PACKAGES[input?.packageId];
      if (!selectedPackage) return send(res, 400, { error: "Choose a valid credit package" });
      await getOrCreateUserData(user);
      const receipt = "rz_" + randomUUID().replace(/-/g, "").slice(0, 24);
      const razorpayResponse = await fetch("https://api.razorpay.com/v1/orders", {
        method: "POST",
        headers: {
          "content-type": "application/json",
          authorization: "Basic " + Buffer.from(RAZORPAY_KEY_ID + ":" + RAZORPAY_KEY_SECRET).toString("base64"),
        },
        signal: AbortSignal.timeout(20_000),
        body: JSON.stringify({
          amount: selectedPackage.amountPaise,
          currency: "INR",
          receipt,
          notes: { uid: user.uid, packageId: selectedPackage.id },
        }),
      });
      if (!razorpayResponse.ok) {
        const error = new Error("Razorpay could not create the payment order");
        error.statusCode = 502;
        throw error;
      }
      const razorpayOrder = await razorpayResponse.json();
      if (typeof razorpayOrder.id !== "string" || razorpayOrder.amount !== selectedPackage.amountPaise ||
          razorpayOrder.currency !== "INR") {
        const error = new Error("Razorpay returned an invalid payment order");
        error.statusCode = 502;
        throw error;
      }
      await firebaseDb.collection("razorpayOrders").doc(razorpayOrder.id).create({
        uid: user.uid,
        packageId: selectedPackage.id,
        packageName: selectedPackage.name,
        amountPaise: selectedPackage.amountPaise,
        credits: selectedPackage.credits,
        currency: "INR",
        status: "created",
        createdAt: new Date(),
      });
      return send(res, 200, {
        ok: true,
        keyId: RAZORPAY_KEY_ID,
        orderId: razorpayOrder.id,
        amount: selectedPackage.amountPaise,
        currency: "INR",
        packageName: selectedPackage.name,
        credits: selectedPackage.credits,
      });
    }
    const input = await readJson(req, isPhotoToCartoon ? 17 * 1024 * 1024 : isTextToSpeech ? MAX_TTS_BODY_BYTES : isVideoRender ? 40 * 1024 * 1024 : MAX_BODY_BYTES);
    if (isPhotoToCartoon) {
      if (typeof input?.imageBase64 !== "string" || typeof input?.mimeType !== "string") {
        return send(res, 400, { error: "Photo data and MIME type are required." });
      }
      const imageBase64 = await generateCartoonImage(input);
      return send(res, 200, { ok: true, task: "photo-to-cartoon", mimeType: "image/png", imageBase64 });
    }
    if (isTextToSpeech) {
      const audio = await generateSpeech(input || {});
      return send(res, 200, { ok: true, task: "text-to-speech", ...audio });
    }
    if (isVideoRender) {
      const validationError = validateVideoRenderInput(input);
      if (validationError) return send(res, 400, { error: validationError });
      const videoBase64 = await renderSlideshowMp4(input);
      return send(res, 200, { ok: true, task: "render-video", mimeType: "video/mp4", videoBase64 });
    }
    const task = TASKS[taskName];
    const value = input?.[task.required];
    if (!isValidTextInput(value, task.max, 3)) {
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
