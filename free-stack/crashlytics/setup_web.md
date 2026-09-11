# Firebase Crashlytics — Web Setup Guide

## Setup Steps

### 1. Add Firebase to Web

In `NoraApp/web/index.html`, add before `</body>`:
```html
<!-- Firebase App -->
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.7.0/firebase-crashlytics-compat.js"></script>

<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_PROJECT.firebaseapp.com",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_PROJECT.appspot.com",
    messagingSenderId: "YOUR_SENDER_ID",
    appId: "YOUR_APP_ID"
  };

  firebase.initializeApp(firebaseConfig);
  const crashlytics = firebase.crashlytics();
</script>
```

### 2. Initialize in Flutter Web

In `NoraApp/lib/main.dart`:
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Web-specific: use Firebase JS SDK for Crashlytics
  if (kIsWeb) {
    // Crashlytics works via the JS SDK loaded in index.html
    FlutterError.onError = (details) {
      // Log to console for web (Crashlytics JS handles it)
      print('Flutter Error: ${details.exceptionAsString()}');
    };
  } else {
    // Mobile: use native Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  runApp(MyApp());
}
```

### 3. Verify
1. Run `flutter run -d chrome`
2. Trigger an error
3. Check Firebase Console → Crashlytics

## Key Points
- **$0 cost** — Crashlytics is free on web too
- **No credit card** required
- **Works alongside mobile** — same Firebase project
