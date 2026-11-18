import test from "node:test";
import assert from "node:assert/strict";
import { validateVideoRenderInput } from "../src/video-render.js";

const png = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 0]).toString("base64");
const image = { mimeType: "image/png", imageBase64: png };

test("accepts one valid PNG scene with default duration", () => {
  assert.equal(validateVideoRenderInput({ images: [image] }), null);
});

test("rejects missing or too many scenes", () => {
  assert.match(validateVideoRenderInput({ images: [] }), /between 1 and 6/);
  assert.match(validateVideoRenderInput({ images: Array(7).fill(image) }), /between 1 and 6/);
});

test("rejects invalid image mime type or bytes", () => {
  assert.match(validateVideoRenderInput({ images: [{ mimeType: "image/gif", imageBase64: png }] }), /PNG, JPG, or WebP/);
  assert.match(validateVideoRenderInput({ images: [{ mimeType: "image/png", imageBase64: "YWJj" }] }), /file type/);
});

test("rejects scene duration outside the safe range", () => {
  assert.match(validateVideoRenderInput({ images: [image], secondsPerImage: 0.5 }), /between 1 and 5/);
  assert.match(validateVideoRenderInput({ images: [image], secondsPerImage: 8 }), /between 1 and 5/);
});

test("rejects unsupported or oversized audio", () => {
  assert.match(validateVideoRenderInput({ images: [image], audioMimeType: "audio/ogg", audioBase64: png }), /WAV, MP3, or AAC/);
});
