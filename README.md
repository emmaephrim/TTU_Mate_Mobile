# TTU Mate — Android (Flutter)

This is a thin Flutter wrapper around the **TTU Mate Flask backend**.
It is a real Android app (compiles to a real APK) that loads your hosted
Flask site inside a full-screen WebView, keeps the user logged in across
sessions, and handles document downloads (DOCX/PDF) natively.

## One-time setup

1. **Install Flutter**
2. Open a terminal in this folder and run:
3. Point the app at your Flask server. Edit **`lib/config.dart`**:

   For the phone to reach Flask on your laptop, run Flask with

   > `flask --app run.py run --host=0.0.0.0 --port=5000`.

## Run on an emulator / device

```bash
flutter run
```

## Build a release APK (to install on any phone)

```bash
flutter build apk --release
```

The APK appears at `build/app/outputs/flutter-apk/app-release.apk`.

## What this app does

- Loads the TTU Mate web app full-screen, no browser chrome
- Persists login cookies (users stay signed in)
- Hardware back button = in-app navigation
- Intercepts file downloads, saves DOCX/PDF to **Downloads** folder with
  the user's auth cookie, then opens the file with the system viewer
- Shows an "offline" banner when no internet
- Splash screen + app icon
