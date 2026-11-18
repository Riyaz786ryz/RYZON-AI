# RYZONE Cloud Backend — Firebase-authenticated Gemini adapter

This Node.js service provides real AI text generation for the Flutter creative studio. It verifies Firebase ID tokens before calling Gemini.

## Endpoints
- GET /health — service health.
- POST /v1/ai/story — create a story.
- POST /v1/ai/dialogue — create character dialogue.
- POST /v1/ai/scenes — create a text storyboard.
- POST /v1/media/photo-to-cartoon — transform an uploaded JPG/PNG/WebP photo into a generated PNG character image (requires `OPENAI_API_KEY`).

The Flutter client in android-app/lib/ai_creative_studio.dart calls these exact routes and sends the signed-in user's Firebase ID token. Provider keys stay on the server and must never be embedded in the APK.

## Hosting configuration
Requires Node.js 20+, Firebase Admin Application Default Credentials for project ryzon-ai, and:
- GEMINI_API_KEY — secret Gemini API key (needed for story/dialogue/storyboard generation).
- OPENAI_API_KEY — secret OpenAI API key (needed for photo-to-cartoon image generation).
- OPENAI_IMAGE_MODEL — optional image model override; defaults to `gpt-image-2`.
- FIREBASE_PROJECT_ID=ryzon-ai.
- GEMINI_MODEL — model identifier supported by the configured Gemini API.

Set secrets in the hosting platform's environment/secret manager. Never commit service-account JSON or real secrets.

Run npm install, npm run check, then npm start from this directory.

## Implemented
- Firebase ID-token verification, including revoked-token checks.
- Story, dialogue and storyboard generation endpoints (Gemini).
- Authenticated photo-to-cartoon image-edit endpoint using the OpenAI Images API, with image MIME/base64 validation, 12 MB source limit, and server-side provider credentials.
- Input validation, request body size limit, per-IP request throttling, no-store response headers, and safe provider error handling.
- Flutter client authentication and calls to the three AI text routes.

## Not yet implemented
- Backend deployment, hosting credentials, Gemini key, and HTTPS URL.
- Speech generation, lip-sync, animation and rendered MP4.
- Private cloud storage, durable generation jobs, per-user quotas, billing, and project persistence.
- The photo-to-cartoon route returns generated PNG bytes to the authenticated client; production private storage and project persistence still need to be implemented.

The text studio becomes live only after the backend is deployed with valid Gemini credentials and the app is configured with RYZON_API_BASE_URL. Photo-to-cartoon becomes live only after the backend is deployed with a valid OpenAI API key and the Android client workflow is connected. This endpoint generates a character image, not a video. Do not claim a generated video exists until speech, animation, job orchestration, storage, and MP4 rendering are connected and tested.
