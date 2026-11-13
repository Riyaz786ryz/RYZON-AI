# RYZON AI Cloud AI Architecture

Status: architecture approved; implementation and deployment are not complete.

## Product direction
RYZON AI will use a cloud-connected architecture for generative AI features. The Android app remains the user interface and performs local tasks such as gallery selection and face detection. Generative image, video, voice, and story workloads run through authenticated server-side services.

## First delivery milestone: Photo to Cartoon
1. User selects a photo and a cartoon style in the Android app.
2. The app asks the authenticated RYZON AI backend to create a generation.
3. The backend validates the user's identity, file type/size, consent, and available quota.
4. The backend sends the image and style prompt to the configured image provider using a server-side secret.
5. The result is stored in private cloud storage and linked to the user's project.
6. The app polls or subscribes to job status, then shows preview, retry, save, and download actions.
7. Usage is charged only after successful generation; failed/cancelled jobs follow the quota reservation policy in the backend contract.

## Planned service boundaries
- Android client: upload UI, job progress, preview, local cache, export/share.
- API backend: authentication, authorization, validation, rate limits, quota reservations, job orchestration, provider abstraction.
- AI provider adapters: image editing first; later video generation, speech, lip-sync, story, and music providers.
- Database: accounts, entitlements, projects, characters, generation jobs, reservations, and audit events.
- Private object storage: source uploads and generated media, with short-lived signed access URLs.
- Render worker: assemble generated clips, voice, music, captions, and transitions into MP4.

## Security and privacy requirements
- Never place provider API keys in Flutter assets, APK resources, source control, or client-side configuration.
- Require verified user authentication for private project and generation endpoints.
- Enforce quotas and paid entitlements on the server, not in the app.
- Validate MIME type, actual file signature, size, and image dimensions; reject unsupported files.
- Use private storage and expiring signed URLs; do not make personal photos public.
- Explain that a selected photo is sent to the configured AI provider for processing and obtain user confirmation before upload.
- Provide deletion controls and define retention periods before public launch.
- Do not deploy an unauthenticated generation endpoint: it could expose user photos and allow uncontrolled paid usage.

## Provider integration
The first provider adapter may use the OpenAI Images edit API. Provider/model choice, pricing, terms, data handling, and regional availability must be checked before enabling paid generation. Keep the adapter replaceable so future video and voice providers can be added without rewriting the Android UI.

## Environment and deployment gates
Before live generation can be enabled:
1. Choose and create the cloud backend project.
2. Configure authentication and private storage.
3. Add provider credentials as server-side secrets in the hosting platform.
4. Configure per-user limits, maximum upload size, and spending alerts.
5. Deploy behind HTTPS and verify authentication, authorization, privacy, and quota tests.
6. Add the deployed API base URL to the Android app configuration (never the provider secret).
7. Build a new APK and test the full upload-to-preview flow on a real Android device.

## Status
- Cloud-first product direction: approved.
- Photo-to-Cartoon first milestone: planned.
- Live backend, authentication, database, storage, provider credentials, deployment, and AI generation: not yet configured.
- No paid provider usage is enabled by this document.
