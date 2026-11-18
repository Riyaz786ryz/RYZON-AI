import test from "node:test";
import assert from "node:assert/strict";
import { boundedText, isValidTextInput } from "../src/validation.js";

test("isValidTextInput accepts trimmed text within limits", () => {
  assert.equal(isValidTextInput("hello", 10), true);
  assert.equal(isValidTextInput("  hello  ", 10), true);
});

test("isValidTextInput rejects non-text, blank, short, and oversized input", () => {
  assert.equal(isValidTextInput(null, 10), false);
  assert.equal(isValidTextInput("   ", 10), false);
  assert.equal(isValidTextInput("ab", 10), false);
  assert.equal(isValidTextInput("12345678901", 10), false);
});

test("isValidTextInput supports a custom minimum length", () => {
  assert.equal(isValidTextInput("ab", 10, 1), true);
  assert.equal(isValidTextInput("ab", 10, 3), false);
});

test("boundedText normalizes whitespace and trims to the maximum length", () => {
  assert.equal(boundedText("  hello   world  ", 20, "fallback"), "hello world");
  assert.equal(boundedText("abcdefgh", 4, "fallback"), "abcd");
});

test("boundedText uses fallback for missing or blank input", () => {
  assert.equal(boundedText(undefined, 10, "fallback"), "fallback");
  assert.equal(boundedText("   ", 10, "fallback"), "fallback");
});
