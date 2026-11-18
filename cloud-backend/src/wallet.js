function assertPaise(value, name) {
  if (!Number.isSafeInteger(value) || value <= 0) {
    throw new TypeError(`${name} must be a positive integer number of paise`);
  }
}

function assertJobId(jobId) {
  if (typeof jobId !== "string" || !/^[A-Za-z0-9_-]{8,120}$/.test(jobId)) {
    throw new TypeError("jobId must be 8-120 safe characters");
  }
}

export async function reserveWalletFunds(db, { uid, jobId, amountPaise }) {
  if (!uid || typeof uid !== "string") throw new TypeError("uid is required");
  assertJobId(jobId);
  assertPaise(amountPaise, "amountPaise");

  const walletRef = db.collection("wallets").doc(uid);
  const jobRef = db.collection("walletJobs").doc(jobId);
  const ledgerRef = db.collection("walletLedger").doc(`${jobId}_reserve`);

  return db.runTransaction(async (tx) => {
    const [walletSnap, jobSnap] = await Promise.all([tx.get(walletRef), tx.get(jobRef)]);
    if (jobSnap.exists) {
      const existing = jobSnap.data();
      if (existing.uid !== uid || existing.reservedPaise !== amountPaise) {
        throw new Error("Idempotency key already used with different request data");
      }
      return { status: existing.status, reservedPaise: existing.reservedPaise, duplicate: true };
    }
    if (!walletSnap.exists) throw new Error("Wallet not found");
    const wallet = walletSnap.data();
    const balance = wallet.balancePaise;
    const reserved = wallet.reservedPaise || 0;
    if (wallet.status !== "active") throw new Error("Wallet is not active");
    if (!Number.isSafeInteger(balance) || !Number.isSafeInteger(reserved) || balance < 0 || reserved < 0) {
      throw new Error("Wallet balance data is invalid");
    }
    if (balance - reserved < amountPaise) {
      const error = new Error("Insufficient wallet balance");
      error.code = "INSUFFICIENT_FUNDS";
      throw error;
    }
    const now = new Date();
    tx.update(walletRef, { reservedPaise: reserved + amountPaise, updatedAt: now });
    tx.create(jobRef, {
      uid, jobId, reservedPaise: amountPaise, chargedPaise: 0,
      status: "reserved", createdAt: now, updatedAt: now,
    });
    tx.create(ledgerRef, {
      uid, jobId, type: "reserve", amountPaise, createdAt: now,
    });
    return { status: "reserved", reservedPaise: amountPaise, duplicate: false };
  });
}

export async function settleWalletReservation(db, { uid, jobId, chargePaise }) {
  if (!uid || typeof uid !== "string") throw new TypeError("uid is required");
  assertJobId(jobId);
  if (!Number.isSafeInteger(chargePaise) || chargePaise < 0) {
    throw new TypeError("chargePaise must be a non-negative integer number of paise");
  }
  const walletRef = db.collection("wallets").doc(uid);
  const jobRef = db.collection("walletJobs").doc(jobId);
  const debitRef = db.collection("walletLedger").doc(`${jobId}_debit`);
  const releaseRef = db.collection("walletLedger").doc(`${jobId}_release`);

  return db.runTransaction(async (tx) => {
    const [walletSnap, jobSnap] = await Promise.all([tx.get(walletRef), tx.get(jobRef)]);
    if (!walletSnap.exists || !jobSnap.exists) throw new Error("Wallet reservation not found");
    const job = jobSnap.data();
    if (job.uid !== uid) throw new Error("Wallet job owner mismatch");
    if (job.status === "settled" || job.status === "released") {
      if (job.status === "settled" && job.chargedPaise !== chargePaise) {
        throw new Error("Job already settled with a different charge");
      }
      return { status: job.status, chargedPaise: job.chargedPaise, duplicate: true };
    }
    if (job.status !== "reserved") throw new Error("Wallet job is not reservable");
    if (chargePaise > job.reservedPaise) throw new Error("Final charge exceeds reserved amount");
    const wallet = walletSnap.data();
    const balance = wallet.balancePaise;
    const reserved = wallet.reservedPaise || 0;
    if (!Number.isSafeInteger(balance) || !Number.isSafeInteger(reserved) ||
        balance < job.reservedPaise || reserved < job.reservedPaise) {
      throw new Error("Wallet reservation accounting is inconsistent");
    }
    const releasedPaise = job.reservedPaise - chargePaise;
    const now = new Date();
    tx.update(walletRef, {
      balancePaise: balance - chargePaise,
      reservedPaise: reserved - job.reservedPaise,
      updatedAt: now,
    });
    tx.update(jobRef, { status: "settled", chargedPaise: chargePaise, releasedPaise, updatedAt: now });
    if (chargePaise > 0) tx.create(debitRef, { uid, jobId, type: "debit", amountPaise: chargePaise, createdAt: now });
    if (releasedPaise > 0) tx.create(releaseRef, { uid, jobId, type: "release", amountPaise: releasedPaise, createdAt: now });
    return { status: "settled", chargedPaise: chargePaise, releasedPaise, duplicate: false };
  });
}

export async function releaseWalletReservation(db, { uid, jobId, reason = "failed" }) {
  if (!uid || typeof uid !== "string") throw new TypeError("uid is required");
  assertJobId(jobId);
  const walletRef = db.collection("wallets").doc(uid);
  const jobRef = db.collection("walletJobs").doc(jobId);
  const releaseRef = db.collection("walletLedger").doc(`${jobId}_release`);

  return db.runTransaction(async (tx) => {
    const [walletSnap, jobSnap] = await Promise.all([tx.get(walletRef), tx.get(jobRef)]);
    if (!walletSnap.exists || !jobSnap.exists) throw new Error("Wallet reservation not found");
    const job = jobSnap.data();
    if (job.uid !== uid) throw new Error("Wallet job owner mismatch");
    if (job.status === "released" || job.status === "settled") {
      return { status: job.status, duplicate: true };
    }
    if (job.status !== "reserved") throw new Error("Wallet job is not reservable");
    const wallet = walletSnap.data();
    const reserved = wallet.reservedPaise || 0;
    if (!Number.isSafeInteger(reserved) || reserved < job.reservedPaise) {
      throw new Error("Wallet reservation accounting is inconsistent");
    }
    const now = new Date();
    tx.update(walletRef, { reservedPaise: reserved - job.reservedPaise, updatedAt: now });
    tx.update(jobRef, { status: "released", releasedPaise: job.reservedPaise, releaseReason: String(reason).slice(0, 80), updatedAt: now });
    tx.create(releaseRef, { uid, jobId, type: "release", amountPaise: job.reservedPaise, reason: String(reason).slice(0, 80), createdAt: now });
    return { status: "released", releasedPaise: job.reservedPaise, duplicate: false };
  });
}
