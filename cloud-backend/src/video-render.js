import { spawn } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import os from "node:os";
import path from "node:path";

const MAX_IMAGE_BYTES = 4 * 1024 * 1024;
const MAX_AUDIO_BYTES = 6 * 1024 * 1024;
const MAX_VIDEO_BYTES = 12 * 1024 * 1024;

export function validateVideoRenderInput(input) {
  if (!input || !Array.isArray(input.images) || input.images.length < 1 || input.images.length > 6) {
    return "Provide between 1 and 6 cartoon scene images.";
  }
  for (const image of input.images) {
    if (!image || !["image/png", "image/jpeg", "image/webp"].includes(image.mimeType) ||
        typeof image.imageBase64 !== "string" ||
        !/^[A-Za-z0-9+/]+={0,2}$/.test(image.imageBase64)) {
      return "Each scene must be a valid PNG, JPG, or WebP image.";
    }
    const bytes = Buffer.from(image.imageBase64, "base64");
    if (!bytes.length || bytes.length > MAX_IMAGE_BYTES) return "Each scene image must be 4 MB or smaller.";
    const valid = image.mimeType === "image/png"
      ? bytes.length >= 8 && bytes.subarray(0, 8).equals(Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]))
      : image.mimeType === "image/jpeg"
        ? bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff
        : bytes.length >= 12 && bytes.toString("ascii", 0, 4) === "RIFF" && bytes.toString("ascii", 8, 12) === "WEBP";
    if (!valid) return "A scene image's contents do not match its file type.";
  }
  const secondsPerImage = Number(input.secondsPerImage ?? 3);
  if (!Number.isFinite(secondsPerImage) || secondsPerImage < 1 || secondsPerImage > 5) {
    return "Each scene duration must be between 1 and 5 seconds.";
  }
  if (input.audioBase64 !== undefined && input.audioBase64 !== null) {
    if (!["audio/wav", "audio/mpeg", "audio/aac"].includes(input.audioMimeType) ||
        typeof input.audioBase64 !== "string" ||
        !/^[A-Za-z0-9+/]+={0,2}$/.test(input.audioBase64)) {
      return "Audio must be a valid WAV, MP3, or AAC file.";
    }
    const audio = Buffer.from(input.audioBase64, "base64");
    if (!audio.length || audio.length > MAX_AUDIO_BYTES) return "Audio must be 6 MB or smaller.";
  }
  return null;
}

function runFfmpeg(args, cwd) {
  return new Promise((resolve, reject) => {
    const child = spawn("ffmpeg", args, { cwd, stdio: ["ignore", "ignore", "pipe"] });
    let errorOutput = "";
    child.stderr.on("data", (chunk) => { errorOutput = (errorOutput + chunk.toString()).slice(-4000); });
    child.on("error", (error) => reject(error));
    child.on("close", (code) => code === 0 ? resolve() : reject(new Error("FFmpeg rendering failed: " + errorOutput)));
  });
}

export async function renderSlideshowMp4(input) {
  const validationError = validateVideoRenderInput(input);
  if (validationError) {
    const error = new Error(validationError);
    error.statusCode = 400;
    throw error;
  }
  const workDir = await mkdtemp(path.join(os.tmpdir(), "ryzone-render-"));
  try {
    const lines = [];
    for (let index = 0; index < input.images.length; index += 1) {
      const image = input.images[index];
      const extension = image.mimeType === "image/png" ? "png" : image.mimeType === "image/jpeg" ? "jpg" : "webp";
      const filename = `scene-${index + 1}.${extension}`;
      await writeFile(path.join(workDir, filename), Buffer.from(image.imageBase64, "base64"), { mode: 0o600 });
      lines.push(`file '${filename}'`, `duration ${Number(input.secondsPerImage ?? 3)}`);
    }
    // Repeat the final still so the concat demuxer honours its requested duration.
    lines.push(`file 'scene-${input.images.length}.${input.images.at(-1).mimeType === "image/png" ? "png" : input.images.at(-1).mimeType === "image/jpeg" ? "jpg" : "webp"}'`);
    await writeFile(path.join(workDir, "scenes.txt"), lines.join("\n") + "\n", { mode: 0o600 });
    const args = [
      "-hide_banner", "-loglevel", "error", "-y",
      "-f", "concat", "-safe", "0", "-i", "scenes.txt",
    ];
    if (input.audioBase64) {
      const audioExtension = input.audioMimeType === "audio/wav" ? "wav" : input.audioMimeType === "audio/mpeg" ? "mp3" : "aac";
      await writeFile(path.join(workDir, `voice.${audioExtension}`), Buffer.from(input.audioBase64, "base64"), { mode: 0o600 });
      args.push("-i", `voice.${audioExtension}`);
    }
    args.push(
      "-vf", "scale=720:1280:force_original_aspect_ratio=decrease,pad=720:1280:(ow-iw)/2:(oh-ih)/2,format=yuv420p,fps=24",
      "-t", String(input.images.length * Number(input.secondsPerImage ?? 3)),
      "-c:v", "libx264", "-preset", "ultrafast", "-crf", "28",
    );
    if (input.audioBase64) args.push("-map", "0:v:0", "-map", "1:a:0?", "-c:a", "aac", "-b:a", "96k", "-shortest");
    args.push("-movflags", "+faststart", "output.mp4");
    await runFfmpeg(args, workDir);
    const video = await readFile(path.join(workDir, "output.mp4"));
    if (!video.length || video.length > MAX_VIDEO_BYTES) {
      const error = new Error("Rendered video is too large. Use fewer or smaller scenes.");
      error.statusCode = 413;
      throw error;
    }
    return video.toString("base64");
  } finally {
    await rm(workDir, { recursive: true, force: true });
  }
}
