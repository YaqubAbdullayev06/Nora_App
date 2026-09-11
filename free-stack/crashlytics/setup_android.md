# Firebase Crashlytics — Android Setup Guide

## Why Crashlytics?
- **$0 cost** — completely free, no event caps
- **No credit card** required
- **Zero maintenance** — Google manages everything
- Works standalone (you don't need to pay for other Firebase services)

## Setup Steps

### 1. Create Firebase Project (Free)
1. Go to https://console.firebase.google.com
2. Click "Create a project"
3. Enter project name (e.g., "nora-app")
4. Disable Google Analytics (not needed, saves setup time)
5. Click "Create project"

### 2. Add Android App
1. In Firebase console, click "Add app" → Android
2. Enter package name: `com.nora.app`
3. Download `google-services.json`
4. Place it in: `NoraApp/android/app/google-services.json`

### 3. Add Dependencies

In `NoraApp/android/build.gradle` (project-level):
```gradle
buildscript {
    dependencies {
        // ... existing dependencies
        classpath 'com.google.gms:google-services:4.4.0'
        classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
    }
}
```

In `NoraApp/android/app/build.gradle` (app-level):
```gradle
apply plugin: 'com.android.application'
apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'

dependencies {
    // ... existing dependencies
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-crashlytics'
}
```

### 4. Initialize in Flutter

In `NoraApp/lib/main.dart`:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Pass all uncaught errors to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  runApp(MyApp());
}
```

### 5. Test It
```dart
// Force a crash to test (remove in production)
FirebaseCrashlytics.instance.crash();
```

### 6. Verify
1. Run your app
2. Trigger a crash
3. Go to Firebase Console → Crashlytics
4. See the crash report appear within minutes

## Key Points
- **No billing setup needed** — Crashlytics is always free
- **No event limits** — log as many crashes as you want
- **Works without other Firebase services** — you can use ONLY Crashlytics
- **No credit card** — Google won't ask for payment info for Crashlytics alone

## Custom Logging (Optional)
```dart
// Log non-fatal errors
FirebaseCrashlytics.instance.recordError(
  error,
  stackTrace,
  reason: 'Failed to load user data',
);

// Add custom keys
FirebaseCrashlytics.instance.setCustomKey('user_id', '12345');
FirebaseCrashlytics.instance.setCustomKey('screen', 'home');

// Log messages
FirebaseCrashlytics.instance.log('User tapped focus button');
```
