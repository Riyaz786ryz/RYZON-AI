# RYZONE Cloud Backend — Firebase-authenticated AI adapter

This Node.js 20 service provides server-side AI endpoints for the Flutter app. It verifies Firebase ID tokens before calling AI providers. Provider API keys must remain in the hosting platform's secret manager and must never be embedded in the APK or committed to GitHub.

## Endpoints

- `GET /health` — service health check.
- `POST /v1/ai/story` — create a cartoon story.
- `POST /v1/ai/dialogue` — create character dialogue.
- `POST /v1/ai/scenes` — create a text storyboard.
- `POST /v1/media/photo-to-cartoon` — transform an uploaded JPG/PNG/WebP photo into a generated PNG character image (requires `OPENAI_API_KEY`).
- `POST /v1/media/text-to-speech` — generate speech audio from text using Gemini TTS (requires `GEMINI_API_KEY`).
- `POST /v1/media/render-video` — render 1–6 supplied scene images into a short vertical MP4, optionally with WAV/MP3/AAC audio (requires FFmpeg in the container; no AI provider call).

The Flutter client sends the signed-in user's Firebase ID token to these routes. The photo route returns a generated image, not an animated video. The TTS route returns audio bytes. The MP4 route creates a basic slideshow-style video from already-generated scene images; it does not animate characters, generate scene images, or create lip-sync.

## Required environment and credentials

- Node.js 20+.
- `FIREBASE_PROJECT_ID=ryzon-ai`.
- `GEMINI_API_KEY` — server-side Gemini API key for story/dialogue/storyboard and TTS.
- `OPENAI_API_KEY` — server-side OpenAI API key for photo-to-cartoon.
- `GEMINI_MODEL` — optional text model override; default is `gemini-3.8-flash`.
- `GEMINI_TTS_MODEL` — optional TTS model override; default is `gemini-3.8-flash-tts`.
- `OPENAI_IMAGE_MODEL` — optional image model override; default is `gpt-image-2`.
- `PORT` — hosting port; default is `8080`.

Firebase Admin uses Application Default Credentials. On Google Cloud Run, attach a dedicated runtime service account for the Firebase project and grant only the permissions needed by the service. Do not upload or commit a service-account JSON key.

## Local checks

From this directory:

```sh
npm install
npm run check
npm start
```

The backend check workflow also runs `node --check src/server.js` on GitHub Actions. A passing syntax check does not prove provider credentials, API access, or live generation work.

## Google Cloud Run deployment outline

The repository includes a Dockerfile for Cloud Run. Deployment is a separate, billable cloud action and has **not** been performed.

1. Create or select a Google Cloud project and enable Cloud Run, Cloud Build, Artifact Registry, Secret Manager, and the required Firebase/Gemini services.
2. Create a dedicated runtime service account. Configure Firebase Admin Application Default Credentials for project `ryzon-ai`; do not use a downloaded JSON key in the repository.
3. Store `GEMINI_API_KEY` and `OPENAI_API_KEY` in Secret Manager. Do not put their values in shell history, source files, or APK build arguments.
4. From the `cloud-backend` directory, deploy the service with the runtime service account, region, and Secret Manager references. Example command (replace the project, region, service account, and secret names with the values you actually created):

```sh
gcloud run deploy ryzone-ai-backend \
  --source . \
  --region asia-south1 \
  --service-account RUNTIME_SERVICE_ACCOUNT_EMAIL \
  --set-env-vars FIREBASE_PROJECT_ID=ryzon-ai,GEMINI_MODEL=gemini-3.8-flash,GEMINI_TTS_MODEL=gemini-3.8-flash-tts \
  --set-secrets GEMINI_API_KEY=GEMINI_SECRET_NAME:latest,OPENAI_API_KEY=OPENAI_SECRET_NAME:latest \
  --allow-unauthenticated
```

5. This example allows HTTPS requests to reach the service because a mobile app cannot safely hold a Cloud Run IAM identity token. The application endpoints still reject requests without a valid Firebase ID token. Keep provider keys in Secret Manager, review abuse/rate limits before launch, and do not remove Firebase token verification.
6. Verify the deployed `/health` endpoint and then test every authenticated AI route with a real Firebase user token. Only after that should the HTTPS service URL be added to the Android build as `RYZON_API_BASE_URL`.

Do not run the deployment command until the cloud project, billing, API keys, and service-account permissions have been reviewed and you explicitly approve any possible charges.

## Implemented in source (not yet live-tested)

- Firebase ID-token verification, including revoked-token checks.
- Story, dialogue and storyboard text-generation endpoints.
- Photo-to-cartoon image-edit endpoint with MIME/base64 validation and a 12 MB source limit.
- Text-to-speech endpoint with a restricted prebuilt voice list and bounded input text.
- Short MP4 slideshow renderer using FFmpeg, isolated temporary workspaces, bounded scene/audio inputs, and output-size limits.
- Request-size limits, per-IP throttling, no-store response headers, and safe provider error handling.
- Flutter client calls for story/dialogue/storyboard, photo-to-cartoon, and TTS; Voice Studio includes audio playback controls.

## Still required before the app can be called functional

- Backend deployment, hosting configuration, provider keys, and HTTPS URL.
- Successful authenticated live tests for story, dialogue, storyboard, photo-to-cartoon, and TTS/playback.
- Speech-to-text input, lip-sync, character animation, and AI-generated scene images. The current MP4 endpoint is a basic slideshow renderer only.
- Private cloud storage, durable generation jobs, per-user quotas, billing/coins, and project persistence.
- Group-photo face-to-character mapping and consistent character identity across scenes.
- Existing-video conversion/dubbing and live cartoon camera.

The app must not claim to create a cartoon video until speech, animation, job orchestration, storage, and MP4 rendering are connected and tested.

## Gemini text-to-speech

The default TTS model is `gemini-3.8-flash-tts`, using the Gemini Interactions API on `v1beta`. The endpoint extracts the returned audio payload and sends it to the Flutter client as base64 WAV audio. Model/API availability and actual playback still need an authenticated integration test with the configured Google AI project.
