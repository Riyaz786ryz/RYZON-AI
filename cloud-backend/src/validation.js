export function isValidTextInput(value, maxLength, minLength = 3) {
  return typeof value === "string" &&
    value.trim().length >= minLength &&
    value.length <= maxLength;
}
