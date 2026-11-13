# RYZON AI — Authentication and Delivery Plan

## Product decision
RYZON AI will offer **Continue with Google** sign-in for every user. Each person signs in with their own Google account. The app must not ask users to share Gmail passwords; Google OAuth handles sign-in.

## Authentication architecture
- Use Firebase Authentication with the Google provider for Android.
- Give each signed-in user a stable Firebase UID.
- Keep user projects, usage records, and subscription entitlements scoped to that UID.
- Require authentication before cloud generation, cloud project sync, or purchases.
- Allow a clear sign-out action and account deletion/data-deletion workflow.
- Do not store Google passwords, OAuth client secrets, service-account keys, or AI provider keys in the mobile app or Git repository.
- Enforce quotas and premium entitlements on a trusted backend, never only in local SharedPreferences.
- Request only basic profile/email scopes unless a later feature needs more.

## Setup required before Google sign-in can work
1. Create or select a Firebase project for RYZON AI.
2. Register the Android application using its exact applicationId/package name.
3. Enable Google as a sign-in provider in Firebase Authentication.
4. Add the app's SHA-1 and SHA-256 signing fingerprints (debug and release as appropriate).
5. Download the matching `google-services.json` into `android-app/android/app/` (do not commit private credentials if the configuration contains restricted secrets; use repository secrets or a secure setup process where appropriate).
6. Configure the Google Services Gradle plugin and FlutterFire packages.
7. Test sign-in, sign-out, cancellation, network errors, and a second distinct Google account on a real Android device.

## Delivery sequence
1. Inspect and stabilize the existing Flutter app and Android build.
2. Add Google sign-in and per-user account state.
3. Add a trusted backend, database, private media storage, and server-enforced free quotas.
4. Implement a first end-to-end generation workflow: photo input → cartoon image or locally animated 10-second reel → MP4 export.
5. Add external AI provider adapters for story, image, video, voice, and lip-sync generation. Keep provider keys on the backend.
6. Add projects, cloud sync, subscriptions, and payment verification.
7. Test every flow and publish a new APK only after a successful CI build and artifact check.

## Important current-state note
The current Flutter app has local UI/planning features, photo selection and on-device face detection. It does not yet have working Firebase login, a deployed backend, connected AI generation providers, server-side quotas, or live payments. Adding this plan does not itself activate those services.

## Cost and availability
Google sign-in itself can be implemented without charging users for each login, subject to Firebase/Google service terms and quotas. AI image/video generation, hosting, storage, and bandwidth may incur costs. The Free plan must use measured provider limits and server-side controls; do not promise unlimited free AI video.
