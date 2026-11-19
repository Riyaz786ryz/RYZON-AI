import test from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import {
  CREDIT_PACKAGES,
  verifyRazorpayWebhookSignature,
  parseCapturedRazorpayPayment,
} from "../src/razorpay.js";

test("credit packages are fixed server-side amounts", () => {
  assert.deepEqual(
    Object.values(CREDIT_PACKAGES).map(({ amountPaise, credits }) => [amountPaise, credits]),
    [[29900, 100], [54900, 200], [129900, 500]],
  );
});

test("Razorpay webhook signature accepts only the matching raw body", () => {
  const body = Buffer.from(JSON.stringify({ event: "payment.captured" }));
  const secret = "test-webhook-secret";
  const signature = createHmac("sha256", secret).update(body).digest("hex");
  assert.equal(verifyRazorpayWebhookSignature(body, signature, secret), true);
  assert.equal(verifyRazorpayWebhookSignature(body, signature, "wrong-secret"), false);
  assert.equal(verifyRazorpayWebhookSignature(body, "not-a-signature", secret), false);
});

test("only captured INR payment events are parsed", () => {
  assert.equal(parseCapturedRazorpayPayment({ event: "payment.failed" }), null);
  assert.deepEqual(parseCapturedRazorpayPayment({
    event: "payment.captured",
    payload: { payment: { entity: {
      id: "pay_12345678",
      order_id: "order_12345678",
      amount: 29900,
      currency: "INR",
      status: "captured",
    } } },
  }), {
    paymentId: "pay_12345678",
    orderId: "order_12345678",
    amountPaise: 29900,
    currency: "INR",
  });
  assert.throws(() => parseCapturedRazorpayPayment({
    event: "payment.captured",
    payload: { payment: { entity: {
      id: "pay_12345678", order_id: "order_12345678",
      amount: 29900, currency: "USD", status: "captured",
    } } },
  }), /Invalid captured/);
});
