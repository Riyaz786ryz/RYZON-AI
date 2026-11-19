# RYZONE – Story-to-Cartoon Movie and Protected Demo Workflow

## Product decision
The first and most prominent Home Page action is **Create Cartoon Video**. The customer should provide only a story; RYZONE should automatically prepare the screenplay, characters, dialogue, scene prompts, shot directions, voices, music and final movie. Do not require customers to manually write prompts, dialogue or character sheets.

## Customer flow
1. Enter a story and select a dialogue language and broad story length.
2. RYZONE prepares a reviewable storyboard, including characters, scene actions, dialogue, expressions and camera framing.
3. Before credits are spent, show a short 5–10 second preview in a deliberately small in-app player.
4. The demo must visibly carry the words **RYZONE DEMO** over the video frames, plus a repeated/moving watermark and a unique demo/job identifier.
5. Demo has no download, share, export or public media URL. Serve it only through authenticated, short-lived protected playback; expire demo assets automatically.
6. Demo should be lower resolution than the final output.
7. Ask the customer to approve the demo and show the exact credit cost before charging.
8. Reserve credits on the server before final generation. Deduct only after successful final render; release the reservation if generation fails or is cancelled.
9. Final customer video must not contain the **RYZONE DEMO** label. The customer-requested final export should have no RYZONE watermark unless a separate optional branding setting is later approved.
10. Enable download/export only after the final render is ready and ownership is verified.

## Anti-misuse protections
- Keep demo player small and embedded in the app; do not expose a raw MP4 download link.
- Apply the RYZONE DEMO watermark server-side into the actual preview frames, not merely as a Flutter overlay.
- Use a repeated diagonal watermark, moving placement, and unique non-sensitive demo identifier.
- Use low-resolution, short-duration previews and short-lived authenticated playback tokens.
- On supported Android devices, enable secure-window protection to deter screenshots/screen recording. This cannot stop external-camera recording, so watermarking remains essential.
- Never promise that watermark removal is technically impossible; multiple embedded marks only make misuse harder to hide.

## Credit and subscription rules
- A subscription grants the monthly entitlement/credits specified by the selected plan.
- Extra credits can be purchased separately.
- Show the exact credit estimate before generation.
- Reserve credits server-side with an idempotent job ID. A client must never set or increase its own balance.
- Settle the reservation only after successful final output. Release it on failure, cancellation or timeout.
- Keep the demo free of credit deductions; do not charge before customer approval.

## Current implementation in this commit
- The Home Page's primary highlighted card now opens Create Cartoon Video.
- The Create Cartoon Video screen now asks for a story, language and scene count; it no longer asks the customer to upload scene images or manually write dialogue.
- It calls the existing authenticated storyboard endpoint and displays the generated text storyboard when the backend is deployed and configured.
- The screen includes a small visual placeholder marked RYZONE DEMO and a locked full-video action to communicate the intended flow.
- The placeholder is NOT a generated video. Actual AI scene/image/video generation, secure demo streaming, server-side watermark rendering, expiry, credit reservation/settlement, and final MP4 export are not yet implemented. Do not advertise those capabilities as live until they are built and tested.
