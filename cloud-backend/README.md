# RYZON AI Cloud Backend — Gemini starter

This is the first executable backend milestone. It connects server-side text tasks to the Gemini Developer API without putting the Gemini API key in the Android app or GitHub.

## Included endpoints

- `GET /health` — service health check.
- `POST /v1/ai/story` — create a story.
- `POST /v1/ai/dialogue` — create character dialogue.
- `POST /v1/ai/scenes` — turn a story into a text storyboard.

All AI endpoints require `Authorization: Bearer <RYZON_BACKEND_TOKEN>`. Requests are size-limited and rate-limited per process/IP. Provider error bodies and secrets are not returned to clients.

## Local setup

Requires Node.js 20 or newer.

1. Copy `.env.example` to `.env`.
2. Create a Gemini API key in Google AI Studio.
3. Set `GEMINI_API_KEY` in the local/server environment. Do not commit the real `.env`.
4. Generate a random token of at least 32 characters for `RYZON_BACKEND_TOKEN`.
5. Run:

```bash
npm run check
npm start
```

Test health with `GET http://localhost:8080/health`. Test an AI endpoint with a JSON POST and the bearer token.

Example story request:

```json
{
  "idea": "A clever village child helps a lost baby elephant find its family",
  "language": "Tamil",
  "genre": "Adventure",
  "audience": "Kids"
}
```

## Model and free-tier notes

The default model is `gemini-3.8-flash`; change `GEMINI_MODEL` in the hosting environment if Google changes availability or if a different eligible model is needed. Model availability and free-tier quotas depend on the Google AI Studio project and can change. Review the official [models list](https://ai.google.dev/gemini-api/docs/models) and [pricing/free-tier details](https://ai.google.dev/gemini-api/docs/pricing).

Google's free tier may use submitted content to improve its products. Do not send private user photos, sensitive personal data, or confidential content through a free-tier project without reviewing Google's current terms and obtaining appropriate user consent.

## Important launch limitations

- This is a development starter, not a deployed production backend.
- The bearer token is a temporary development gate, not per-user authentication. Replace it with verified user JWTs before any public release. Never embed this shared token in a public APK.
- In-memory rate limits reset on restart and are not a substitute for atomic account quotas.
- No database, persistent jobs, user accounts, subscriptions, payments, image generation, audio generation, or video generation is included yet.
- Do not enable public app access until HTTPS hosting, user authentication, per-account quota enforcement, monitoring, and privacy controls are implemented.
- The Android app is not connected to this backend yet. Deployment and a secure app-auth flow are the next integration steps.
