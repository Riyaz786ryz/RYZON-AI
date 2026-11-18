# RYZONE Admin Budget Alerts

## Goal
Send budget and usage warnings to the owner's Android phone before the monthly AI/cloud budget is exhausted.

## Initial monthly budget and thresholds
The initial planning budget is INR 2,000. These are alert thresholds, not guaranteed provider billing caps:

| Threshold | Amount | Action |
| --- | ---: | --- |
| 50% | INR 1,000 | Informational push notification |
| 75% | INR 1,500 | Warning push notification |
| 90% | INR 1,800 | High-priority warning |
| 95% | INR 1,900 | Pause promotional/free AI requests; preserve owner/admin access |
| 100% | INR 2,000 | Block new billable AI jobs until the owner explicitly raises the limit |

## Required architecture
1. **Android app:** Firebase Cloud Messaging (FCM) receives push notifications. Ask for Android notification permission and register the owner's device token after sign-in.
2. **Secure token registration:** Send the FCM token to the authenticated backend. Store it in a private Firestore collection keyed by owner UID. Never place service-account credentials or provider API keys in the APK or GitHub.
3. **Owner authorization:** Only a configured owner Firebase UID may register an admin device or receive admin budget alerts. Do not trust a client-supplied admin flag or email address alone.
4. **Usage ledger:** Record every provider operation with owner/user UID, provider, model, operation type, timestamp, estimated cost, and final provider cost when available. Use durable storage and idempotent job IDs.
5. **Budget evaluator:** Aggregate the current billing month in INR, convert foreign-currency provider costs using a recorded exchange rate, and send each threshold notification once per billing period.
6. **Cloud billing feed:** Configure Google Cloud Billing budget notifications through Pub/Sub and a secured backend subscriber. Billing export data is the preferred source for reconciled actual spend; budget notifications can be delayed.
7. **Enforcement:** Apply server-side quotas before starting a provider request. Pause new billable jobs at the configured safety threshold. A Google Cloud budget alert alone does not stop spending and is not a hard cap.
8. **Admin screen:** Show month-to-date estimated and reconciled spend, threshold status, provider breakdown, and whether new AI jobs are paused.

## Notification copy
- INR 1,000: RYZONE budget update: estimated monthly spend reached INR 1,000 (50% of INR 2,000).
- INR 1,500: RYZONE warning: estimated monthly spend reached INR 1,500 (75%).
- INR 1,800: RYZONE high warning: estimated monthly spend reached INR 1,800 (90%).
- INR 1,900: RYZONE safety pause: free/promotional AI requests are paused. Estimated spend reached INR 1,900.
- INR 2,000: RYZONE budget limit reached. New billable AI jobs are blocked until the owner reviews and raises the limit.

## Security and launch requirements
- Never commit Gemini/OpenAI API keys, Firebase service-account keys, or FCM server credentials.
- Do not send budget alerts to ordinary users.
- Do not treat an alert threshold as a guaranteed spend ceiling. Provider billing can be delayed, and in-flight jobs may finish after a pause.
- Test foreground, background, and terminated-app notifications on a real Android device.
- Test duplicate suppression, month rollover, token refresh, revoked sessions, and provider failures.
- Do not enable paid Cloud Run, Pub/Sub, or other billable infrastructure without the owner's explicit approval.

## Implementation status
This document is the approved design only. Push delivery, durable usage metering, Cloud Billing Pub/Sub integration, and server-side budget enforcement are not yet implemented or live-tested. The current backend's in-memory IP rate limiter is not a monthly cost limit.
