import test from "node:test";
import assert from "node:assert/strict";
import { isValidTextInput } from "./validation.js";

test("accepts normal text within bounds", () => {
  assert.equal(isValidTextInput("A cartoon story", 2000), true);
});

test("rejects non-string values", () => {
  assert.equal(isValidTextInput(null, 2000), false);
  assert.equal(isValidTextInput(123, 2000), false);
});

test("rejects blank and too-short text", () => {
  assert.equal(isValidTextInput("   ", 2000), false);
  assert.equal(isValidTextInput("ab", 2000), false);
});

test("enforces the maximum character count", () => {
  assert.equal(isValidTextInput("1234", 4), true);
  assert.equal(isValidTextInput("12345", 4), false);
});

test("supports one-character minimum for speech text", () => {
  assert.equal(isValidTextInput("A", 3000, 1), true);
  assert.equal(isValidTextInput("", 3000, 1), false);
});
