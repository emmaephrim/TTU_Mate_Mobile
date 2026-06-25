# TTU Mate — Android (Flutter)

This is a thin Flutter wrapper around the **TTU Mate Flask backend**.
It is a real Android app (compiles to a real APK) that loads your hosted
Flask site inside a full-screen WebView, keeps the user logged in across
sessions, and handles document downloads (DOCX/PDF) natively.

## Why a wrapper?

You said you have a presentation tomorrow. Re-implementing every screen
(auth, generators, Paystack, PDF rendering, file storage) natively in
Flutter would take a week. A WebView wrapper gives you a 100% functional
mobile app **today**, using the exact same backend the web app uses.

## One-time setup

1. **Install Flutter** (3.16+): https://docs.flutter.dev/get-started/install
2. Open a terminal in this folder and run:
   ```bash
   flutter pub get
   ```
3. Point the app at your Flask server. Edit **`lib/config.dart`**:
   ```dart
   static const String serverUrl = "http://10.0.2.2:5000";
   ```
   - `10.0.2.2:5000` → Flask running on your computer, viewed from the Android **emulator**.
   - `http://192.168.x.x:5000` → Flask on your computer, viewed from a **physical phone** on the same Wi-Fi.
     Find your LAN IP with `ipconfig` (Windows) or `ifconfig` (Mac/Linux).
   - `https://your-deployed-domain.com` → Production.

   > For the phone to reach Flask on your laptop, run Flask with
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
Send it to your phone, tap to install (you may need to allow
"Install from unknown sources").

## What this app does for you

- Loads the TTU Mate web app full-screen, no browser chrome
- Persists login cookies (users stay signed in)
- Hardware back button = in-app navigation
- Intercepts file downloads, saves DOCX/PDF to **Downloads** folder with
  the user's auth cookie, then opens the file with the system viewer
- Shows an "offline" banner when no internet
- Splash screen + app icon
