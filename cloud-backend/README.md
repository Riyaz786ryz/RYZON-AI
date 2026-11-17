# RYZONE Cloud Backend — Firebase-authenticated Gemini adapter

This Node.js service provides real AI text generation for the Flutter creative studio. It verifies Firebase ID tokens before calling Gemini.

## Endpoints
- GET /health — service health.
- POST /v1/ai/story — create a story.
- POST /v1/ai/dialogue — create character dialogue.
- POST /v1/ai/scenes — create a text storyboard.

The Flutter client in android-app/lib/ai_creative_studio.dart calls these exact routes and sends the signed-in user's Firebase ID token. Provider keys stay on the server and must never be embedded in the APK.

## Hosting configuration
Requires Node.js 20+, Firebase Admin Application Default Credentials for project ryzon-ai, and:
- GEMINI_API_KEY — secret Gemini API key.
- FIREBASE_PROJECT_ID=ryzon-ai.
- GEMINI_MODEL — model identifier supported by the configured Gemini API.

Set secrets in the hosting platform's environment/secret manager. Never commit service-account JSON or real secrets.

Run npm install, npm run check, then npm start from this directory.

## Implemented
- Firebase ID-token verification, including revoked-token checks.
- Story, dialogue and storyboard generation endpoints.
- Input validation, request body size limit, per-IP request throttling, no-store response headers, and safe provider error handling.
- Flutter client authentication and calls to the three AI text routes.

## Not yet implemented
- Backend deployment, hosting credentials, Gemini key, and HTTPS URL.
- AI image generation, speech generation, lip-sync, animation and rendered MP4.
- Private photo uploads, durable generation jobs, per-user quotas, billing, and project persistence.

The app's text studio becomes live only after the backend is deployed with valid credentials and the app is configured with RYZON_API_BASE_URL. Do not claim a generated video exists until the media generation and rendering pipeline is connected.
