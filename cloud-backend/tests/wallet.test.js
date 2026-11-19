import test from "node:test";
import assert from "node:assert/strict";
import { reserveWalletFunds, settleWalletReservation, releaseWalletReservation, creditWalletFromVerifiedPayment, creditWalletCreditsFromVerifiedPayment, getWalletSummary } from "../src/wallet.js";

function fakeDb(initialBalance = 1000) {
  const data = new Map([
    [`wallets/user-1`, { uid: "user-1", balancePaise: initialBalance, reservedPaise: 0, status: "active" }],
  ]);
  const ref = (collection, id) => ({
    key: `${collection}/${id}`,
    collection, id,
    async get() { return { exists: data.has(`${collection}/${id}`), data: () => data.get(`${collection}/${id}`) }; },
  });
  const db = {
    collection(name) {
      return { doc(id) { return ref(name, id); } };
    },
    async runTransaction(callback) {
      const writes = [];
      const tx = {
        async get(r) { return { exists: data.has(r.key), data: () => data.get(r.key) }; },
        create(r, value) { writes.push(["create", r.key, value]); },
        update(r, value) { writes.push(["update", r.key, value]); },
      };
      const result = await callback(tx);
      for (const [op, key, value] of writes) {
        if (op === "create" && data.has(key)) throw new Error("already exists");
        data.set(key, op === "update" ? { ...data.get(key), ...value } : value);
      }
      return result;
    },
  };
  return { db, data };
}

test("reservation holds funds and blocks insufficient balance", async () => {
  const { db, data } = fakeDb(500);
  const result = await reserveWalletFunds(db, { uid: "user-1", jobId: "job_00000001", amountPaise: 400 });
  assert.equal(result.status, "reserved");
  assert.equal(data.get("wallets/user-1").reservedPaise, 400);
  await assert.rejects(
    reserveWalletFunds(db, { uid: "user-1", jobId: "job_00000002", amountPaise: 200 }),
    /Insufficient wallet balance/,
  );
});

test("settlement debits actual charge and releases unused hold exactly once", async () => {
  const { db, data } = fakeDb(1000);
  await reserveWalletFunds(db, { uid: "user-1", jobId: "job_00000003", amountPaise: 500 });
  const result = await settleWalletReservation(db, { uid: "user-1", jobId: "job_00000003", chargePaise: 320 });
  assert.equal(result.chargedPaise, 320);
  assert.equal(result.releasedPaise, 180);
  assert.equal(data.get("wallets/user-1").balancePaise, 680);
  assert.equal(data.get("wallets/user-1").reservedPaise, 0);
  const retry = await settleWalletReservation(db, { uid: "user-1", jobId: "job_00000003", chargePaise: 320 });
  assert.equal(retry.duplicate, true);
});

test("failed job releases its reservation without charging", async () => {
  const { db, data } = fakeDb(1000);
  await reserveWalletFunds(db, { uid: "user-1", jobId: "job_00000004", amountPaise: 250 });
  const result = await releaseWalletReservation(db, { uid: "user-1", jobId: "job_00000004", reason: "provider_failed" });
  assert.equal(result.status, "released");
  assert.equal(data.get("wallets/user-1").balancePaise, 1000);
  assert.equal(data.get("wallets/user-1").reservedPaise, 0);
});

test("rejects unsafe job ids and charges above the reservation", async () => {
  const { db } = fakeDb(1000);
  await assert.rejects(
    reserveWalletFunds(db, { uid: "user-1", jobId: "../bad", amountPaise: 10 }),
    /jobId/,
  );
  await reserveWalletFunds(db, { uid: "user-1", jobId: "job_00000005", amountPaise: 100 });
  await assert.rejects(
    settleWalletReservation(db, { uid: "user-1", jobId: "job_00000005", chargePaise: 101 }),
    /exceeds reserved/,
  );
});


test("verified top-up credits the wallet once and is idempotent", async () => {
  const { db, data } = fakeDb(100);
  const payment = { uid: "user-1", paymentId: "pay_00000001", amountPaise: 2500, provider: "razorpay" };
  const first = await creditWalletFromVerifiedPayment(db, payment);
  assert.equal(first.status, "credited");
  assert.equal(first.duplicate, false);
  assert.equal(data.get("wallets/user-1").balancePaise, 2600);
  const retry = await creditWalletFromVerifiedPayment(db, payment);
  assert.equal(retry.duplicate, true);
  assert.equal(data.get("wallets/user-1").balancePaise, 2600);
  assert.equal(data.get("walletLedger/topup_pay_00000001").type, "topup");
});

test("wallet summary reports available balance after reservations", async () => {
  const { db } = fakeDb(1000);
  await reserveWalletFunds(db, { uid: "user-1", jobId: "job_00000006", amountPaise: 275 });
  const summary = await getWalletSummary(db, "user-1");
  assert.deepEqual(summary, {
    currency: "INR",
    credits: 0,
    balancePaise: 1000,
    reservedPaise: 275,
    availablePaise: 725,
    status: "active",
  });
});

test("top-up rejects invalid payment data and reused payment IDs", async () => {
  const { db } = fakeDb(1000);
  await assert.rejects(
    creditWalletFromVerifiedPayment(db, { uid: "user-1", paymentId: "bad/id", amountPaise: 100, provider: "razorpay" }),
    /paymentId/,
  );
  await creditWalletFromVerifiedPayment(db, { uid: "user-1", paymentId: "pay_00000002", amountPaise: 100, provider: "razorpay" });
  await assert.rejects(
    creditWalletFromVerifiedPayment(db, { uid: "user-1", paymentId: "pay_00000002", amountPaise: 200, provider: "razorpay" }),
    /different payment data/,
  );
});

test("verified Razorpay payment adds purchased credits once", async () => {
  const { db, data } = fakeDb(0);
  data.set("razorpayOrders/order_12345678", {
    uid: "user-1",
    amountPaise: 29900,
    credits: 100,
    currency: "INR",
    status: "created",
  });
  const payment = {
    uid: "user-1",
    paymentId: "pay_12345678",
    orderId: "order_12345678",
    amountPaise: 29900,
    credits: 100,
  };
  const first = await creditWalletCreditsFromVerifiedPayment(db, payment);
  assert.equal(first.duplicate, false);
  assert.equal(data.get("wallets/user-1").credits, 100);
  assert.equal(data.get("walletLedger/topup_credits_pay_12345678").credits, 100);
  const retry = await creditWalletCreditsFromVerifiedPayment(db, payment);
  assert.equal(retry.duplicate, true);
  assert.equal(data.get("wallets/user-1").credits, 100);
});

test("verified Razorpay top-up rejects amount or package mismatch", async () => {
  const { db, data } = fakeDb(0);
  data.set("razorpayOrders/order_12345679", {
    uid: "user-1", amountPaise: 29900, credits: 100, currency: "INR", status: "created",
  });
  await assert.rejects(
    creditWalletCreditsFromVerifiedPayment(db, {
      uid: "user-1", paymentId: "pay_12345679", orderId: "order_12345679",
      amountPaise: 54900, credits: 200,
    }),
    /do not match/,
  );
  assert.equal(data.get("wallets/user-1").credits, undefined);
});
