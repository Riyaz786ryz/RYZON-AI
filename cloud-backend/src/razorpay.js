import { createHmac, timingSafeEqual } from "node:crypto";

export const CREDIT_PACKAGES = Object.freeze({
  starter: Object.freeze({ id: "starter", name: "Starter", amountPaise: 29900, credits: 100 }),
  creator: Object.freeze({ id: "creator", name: "Creator", amountPaise: 54900, credits: 200 }),
  pro: Object.freeze({ id: "pro", name: "Pro Creator", amountPaise: 129900, credits: 500 }),
});

export function verifyRazorpayWebhookSignature(rawBody, signature, secret) {
  if (!Buffer.isBuffer(rawBody) || typeof signature !== "string" ||
      !/^[a-f0-9]{64}$/i.test(signature) || typeof secret !== "string" || !secret) {
    return false;
  }
  const expected = createHmac("sha256", secret).update(rawBody).digest();
  const received = Buffer.from(signature, "hex");
  return received.length === expected.length && timingSafeEqual(received, expected);
}

export function parseCapturedRazorpayPayment(payload) {
  if (!payload || payload.event !== "payment.captured") return null;
  const payment = payload.payload?.payment?.entity;
  if (!payment || payment.status !== "captured" ||
      typeof payment.id !== "string" || typeof payment.order_id !== "string" ||
      !Number.isSafeInteger(payment.amount) || payment.amount <= 0 ||
      payment.currency !== "INR") {
    throw new Error("Invalid captured Razorpay payment payload");
  }
  return {
    paymentId: payment.id,
    orderId: payment.order_id,
    amountPaise: payment.amount,
    currency: payment.currency,
  };
}
