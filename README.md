# LostLink

LostLink is an Android-first Flutter lost-and-found management app for
Infanta National High School. Students report lost items and items they find,
search reports, and contact posters. Authorized staff review ownership claims
and make the final verification and return decisions. Matching only suggests
possible reports; it never verifies ownership.

## Features

- Student email/password registration and sign-in; staff access is assigned by
  authorized personnel.
- Lost and found reports with category, date, location, details, and optional
  compressed photos stored in Cloud Firestore as base64.
- Search, filters, My Reports, owner edit/delete, and paginated browsing.
- Per-report chat with unread counts.
- Claim requests and staff approval/rejection.
- Explainable smart-match suggestions and stored in-app notifications; no push
  notifications.
- Staff dashboard and date-filtered status/category summaries.
- Non-cash finder points awarded only when staff mark a found report Returned,
  with transaction history.

## Technology

- Flutter 3.47.6 and Dart 3.13.5 (SDK constraint: `^3.13.5`).
- Android Studio / Android Gradle Plugin; Gradle uses Java 17.
- Provider (`ChangeNotifier`) and go_router.
- Firebase Authentication (email/password) and Cloud Firestore in the existing
  Firebase project `ctadmobl-project`.
- `image_picker`, `image`, and `flutter_launcher_icons`.
- GitHub Actions CI for analysis, tests, and release APK artifacts.

Firebase Storage, Cloud Functions, and push messaging are not used.

## Folder structure

```text
lib/
  core/        Constants, router, errors, theme, and pure-Dart utilities
  models/      Immutable item, user, chat, claim, notification, and points data
  providers/   ChangeNotifier view models
  screens/     Auth, home, search, report, details, chat, claims, admin, profile
  services/    Firebase Auth and Firestore access
  widgets/     Shared responsive UI components
docs/
  FEATURE_CHECKLIST.md
android/
  app/         Android application and release build configuration
test/          Dart unit and Flutter widget tests
```

## Setup and run

1. Install Flutter 3.47.6 or a newer compatible stable release, Android Studio,
   Android SDK tooling, and a Java 17 JDK.
2. Open this repository in Android Studio and connect an Android device or
   start an emulator.
3. Keep the existing Firebase configuration in
   `lib/firebase_options.dart` and `android/app/google-services.json`. The
   Android package ID remains `com.example.ctadmobl_project` because that is
   the application registered in the existing Firebase project. Changing it
   requires a corresponding Android app registration/configuration in that
   same project.
4. Before using Firestore features against the live database, review and deploy
   the local `firestore.rules` and `firestore.indexes.json` to the existing
   project only when authorized. Deploying these files is not part of a Flutter
   build.
5. From the repository root, run:

   ```powershell
   flutter pub get
   flutter run
   ```

New public registrations receive the `student` role. Admin access is controlled
by the existing profile role plus a verified-email allowlist for
`justinefrancis425@gmail.com`. The corresponding Firestore rules must be
deployed to the existing Firebase project for staff and chat permissions to
take effect. Do not set arbitrary account roles from the client.

## Tests and analysis

```powershell
flutter analyze
flutter test
```

## Android release signing

A local upload keystore is configured at `android/app/lostlink-release.jks`;
its password properties are stored in the ignored `android/key.properties`.
Keep both files private and backed up securely. Never commit or share them.
The app Gradle configuration enables R8 code minification and resource
shrinking. Firebase Android libraries provide their consumer shrinker rules;
`android/app/proguard-rules.pro` retains signature and annotation metadata used
by those libraries.

If setting up signing on a different machine, generate a replacement upload
key (do not overwrite the key used to sign a published app):

```powershell
keytool -genkeypair -v -keystore android/app/lostlink-release.jks -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias lostlink-upload
```

Create `android/key.properties` (ignored by Git) with your own secret values:

```properties
storeFile=lostlink-release.jks
storePassword=YOUR_STORE_PASSWORD
keyAlias=lostlink-upload
keyPassword=YOUR_KEY_PASSWORD
```

Then build:

```powershell
flutter build apk --release
flutter build apk --split-per-abi
flutter build appbundle --release
```

Outputs are written under `build/app/outputs/`:

- `flutter-apk/app-release.apk`
- `flutter-apk/app-armeabi-v7a-release.apk`
- `flutter-apk/app-arm64-v8a-release.apk`
- `flutter-apk/app-x86_64-release.apk`
- `bundle/release/app-release.aab`

Build sizes are environment-dependent; after building, inspect them with:

```powershell
Get-ChildItem build/app/outputs/flutter-apk,build/app/outputs/bundle/release -File |
  Select-Object FullName,@{Name='SizeMB';Expression={[math]::Round($_.Length / 1MB, 2)}}
```

With the keystore connected, install and run a release build on a connected
Android device:

```powershell
flutter run --release
```

## GitHub Actions

`.github/workflows/ci.yml` runs `flutter pub get`, `flutter analyze`,
`flutter test`, and `flutter build apk --release` on pushes and pull requests,
then uploads the APK as the `lostlink-release-apk` artifact.

Without signing secrets, CI uses the Gradle debug-signing fallback so the
artifact build works. For a distributable signed artifact, configure the
repository Actions secrets `ANDROID_KEYSTORE_BASE64`,
`ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, and `ANDROID_KEY_PASSWORD`.
`ANDROID_KEYSTORE_BASE64` is the base64-encoded upload keystore.

## Hosting

Firebase Hosting deployment is not configured or performed by this setup.
Adding it would create/update Hosting configuration and publish a web build to
the existing Firebase project; ask for approval before making those changes.

## Screenshots

| File | Description |
|---|---|
| `docs/screenshots/home.png` | Browse screen with Lost and Found reports |
| `docs/screenshots/report-details.png` | Report details and poster actions |
| `docs/screenshots/chat.png` | In-app conversation about a report |
| `docs/screenshots/staff-dashboard.png` | Staff totals and date-filtered statistics |

Capture and place the screenshots in `docs/screenshots/` when preparing the
project presentation.

## Team members

- Add the project team members' names and roles here.
