# Twitter

A private Flutter app for a personal social timeline, inspired by the familiar layout and interaction patterns of X/Twitter and TwiNote.

## Current app foundation
- X-style home timeline with For you / Following tabs
- Explore search across visible posts
- Notifications, messages and profile screens
- Post composer with gallery and camera photo selection
- Photo previews in the composer and attached images in the timeline
- Like, repost and reply counters
- Locally saved timeline posts
- Light, dark and system appearance modes
- Accent color presets and custom HEX color
- Theme and accent preferences saved on device

## Planned next
- Bot Studio: create accounts, define voice/personality and posting schedules
- Curated media library for ILLIT and NewJeans/NJZ
- Automated update sources with clear source labels
- Video posts, richer replies, following lists and profile customization
- Settings, notification controls and backup/export

## Run locally
```bash
flutter pub get
flutter run
```

## Android APK
Every push to main starts the **Android build** GitHub Actions workflow. When the run succeeds, open the workflow run and download the twitter-android artifact. It contains the release APK.

Demo timeline entries are sample placeholders, not live news or real-time bot updates. Automated publishing is a planned feature.
