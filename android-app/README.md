# RYZON AI — Android App

Flutter starter for the RYZON AI cartoon movie studio.

## Current working module

- Photo picker: choose a photo from the device gallery.
- On-device face detection using Google ML Kit.
- Detect and count multiple faces in one photo.
- Select or deselect each detected person before confirming the character list.
- The photo is processed locally by this module; it is not uploaded to an AI server.

## Requirements

- Flutter SDK with Dart 3.3 or newer.
- Android minimum SDK 21 or newer (required by the ML Kit face detection plugin).
- Android device or emulator.

## Run

From this directory:

```bash
flutter pub get
flutter run
```

If the Android platform folder has not yet been generated, create the Flutter platform scaffold first:

```bash
flutter create --platforms=android .
```

Then ensure `minSdk` is at least 21 in the Android app Gradle configuration.

## Important

Face detection and face selection are implemented as a first development step. Cartoon image generation, character profile storage, story generation, voice, music, video rendering, and live camera effects still need their AI services and backend integrations. No API keys are included in this repository.
