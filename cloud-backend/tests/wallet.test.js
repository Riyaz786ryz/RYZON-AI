import test from "node:test";
import assert from "node:assert/strict";
import { reserveWalletFunds, settleWalletReservation, releaseWalletReservation } from "../src/wallet.js";

function fakeDb(initialBalance = 1000) {
  const data = new Map([
    [`wallets/user-1`, { uid: "user-1", balancePaise: initialBalance, reservedPaise: 0, status: "active" }],
  ]);
  const ref = (collection, id) => ({
    key: `${collection}/${id}`,
    collection, id,
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
