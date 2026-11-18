export function isValidTextInput(value, maxLength, minLength = 3) {
  return typeof value === "string" &&
    value.trim().length >= minLength &&
    value.length <= maxLength;
}

export function boundedText(value, maxLength, fallback) {
  if (typeof value !== "string") return fallback;
  const normalized = value.trim().replace(/\\s+/g, " ");
  return normalized ? normalized.slice(0, maxLength) : fallback;
}
