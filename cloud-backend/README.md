# RYZONE Cloud Backend — Firebase-authenticated Gemini starter

This is an executable development backend for text-based cartoon planning. It verifies Firebase ID tokens with Firebase Admin before accepting AI requests.

## Endpoints
- `GET /health` — service health.
- `POST /v1/ai/story` — create a story.
- `POST /v1/ai/dialogue` — create character dialogue.
- `POST /v1/ai/scenes` — create a text storyboard.

AI endpoints require `Authorization: Bearer <Firebase ID token>`. The Android app must obtain the token from the signed-in Firebase user using `FirebaseAuth.instance.currentUser!.getIdToken()`. Never embed a shared backend token or provider API key in the APK.

## Server configuration
Requires Node.js 20+, Firebase Admin Application Default Credentials for project `ryzon-ai`, and a Gemini API key.
Set `GEMINI_API_KEY`, `FIREBASE_PROJECT_ID=ryzon-ai`, and `GEMINI_MODEL` in the hosting platform. On Google Cloud hosting, attach a dedicated service account with only the required Firebase token-verification permissions. Do not commit service-account JSON or real secrets.

Run `npm install`, `npm run check`, then `npm start`.

## Important status
- Firebase ID token verification: implemented in backend source.
- Gemini story/dialogue/storyboard text endpoints: implemented in backend source.
- Backend deployment, hosting credentials, Gemini key, and HTTPS URL: not configured here.
- Android client integration: not yet implemented.
- Per-user quotas, database, private media storage, image generation, speech, lip-sync, and rendered AI video: not implemented.
- The backend must not be exposed publicly until deployed with HTTPS, verified Firebase credentials, quotas, monitoring, and privacy controls.
