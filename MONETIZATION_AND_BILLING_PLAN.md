# RYZONE — Monetization and Billing Plan

Status: product direction approved; prices are provisional; no purchases or paid entitlements are active yet.

## Product model

RYZONE will launch with three access paths:

1. **Free plan** — lets new users try the product with strict daily limits.
2. **Premium monthly subscription** — unlocks a larger monthly generation allowance and premium tools.
3. **Pay per video** — one-time consumable generation credits for users who do not want a subscription.

Do not advertise unlimited generation. AI providers, rendering, storage, bandwidth, payment fees, refunds, and taxes all create costs.

## Draft launch offer (not final prices)

| Plan | Draft offer | Notes |
|---|---:|---|
| Free | ₹0 | Initial trial limits: up to 5 short AI reels/day, 5 photo-cartoon attempts/day, basic styles/voices, and storyboard preview. Limits must be enforced on the backend. |
| Premium Monthly | ₹299/month (provisional) | Higher monthly allowance, longer output options when supported, premium styles/voices and advanced tools. Final limits depend on measured unit costs. |
| Single Video | from ₹29/video (provisional) | Final price/credit cost depends on duration, resolution, provider cost and rendering time. |

These are discussion prices only. Do not publish them, create Play products, or charge users until provider costs, taxes, store fees, refund handling, and contribution margin have been calculated from real test generations.

## Purchase and entitlement architecture

- Android app uses Google Play Billing for digital features and services when distributed through Google Play, unless RYZONE separately enrolls in and satisfies an eligible alternative-billing programme.
- Keep product IDs stable, for example `ryzone_premium_monthly` and `ryzone_video_credit_1`; create them in Play Console only when the developer account and product details are ready.
- The app starts a purchase and sends the purchase token to the authenticated backend.
- The backend verifies purchase tokens with Google Play Developer APIs, checks package name, product ID, purchase state, acknowledgement/consumption state, expiry and cancellation, then writes the entitlement to the user's Firebase UID.
- Never unlock Premium based only on a client-side success callback or a local preference.
- Process Real-time Developer Notifications (RTDN) for renewals, cancellations, refunds, revocations and expiry. Reconcile entitlements with Google Play.
- For one-time video credits, grant credits only after verified purchase. Reserve credits before paid generation; consume only on successful completion under a documented retry/refund policy.
- For subscriptions, store entitlement status and expiry on the server. Check entitlement on every paid generation request.
- Keep an auditable ledger of purchase events, credit grants, reservations, successful charges, refunds and reversals.
- Never store card details or payment credentials in RYZONE.

## Backend data model (planned)

- `users/{uid}/entitlement/current`: plan, status, product ID, expiry, source and last verification time.
- `users/{uid}/credits/{creditId}`: granted, reserved, consumed or refunded video credits.
- `purchaseEvents/{eventId}`: verified provider event, token hash/reference, product, state and timestamps.
- `generationJobs/{jobId}`: estimated cost, reserved allowance/credits, final provider cost, result status and settlement record.

Use server timestamps and idempotency keys. Never log raw purchase tokens or provider secrets.

## Required delivery stages

1. Measure real AI image/video/voice/rendering costs with test jobs.
2. Define exact Free, Premium and per-video quotas from those costs.
3. Create Google Play subscription and one-time products; configure tax, merchant and payout details in Play Console.
4. Implement Flutter purchase UI and purchase restore.
5. Implement backend purchase-token verification and entitlement/credit ledger.
6. Add RTDN and refund/revocation handling.
7. Test pending, successful, cancelled, failed, restored, expired, refunded and duplicate purchase cases using Play test accounts.
8. Only then enable paid checkout for real users.

## Compliance and customer trust

- Show the exact price, billing period, included allowance, renewal behavior and cancellation instructions before purchase.
- Clearly distinguish subscription from one-time video credits.
- Provide Terms, Privacy Policy, support contact, refund/help process and account/data deletion.
- Do not promise features that are not implemented and tested.
- For Google Play distribution, follow the current Payments policy. India has an alternative-billing programme, but it has separate enrollment, UX, reporting and service-fee requirements; it is not an automatic exemption.
- Check current Play Console requirements immediately before launch because programme and policy terms can change.

## Current implementation status

- Firebase Google sign-in: user has reported it works on their device.
- Server-side quota enforcement: not implemented.
- Billing SDK and product catalogue: not implemented.
- Purchase-token verification and entitlement database: not implemented.
- Video credit ledger: not implemented.
- Live AI video rendering and cost measurement: not implemented.
- No real payment can currently be accepted through the app.
