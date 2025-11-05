# Google Sign-In Setup for Attendance App

This document explains how to configure Google Sign-In with Sheets API access for the Attendance app.

## Prerequisites

1. A Google Cloud Project
2. The `google_sign_in` Flutter package (already included in pubspec.yaml)
3. The `googleapis` package (already included in pubspec.yaml)

## 1. Generate SHA-1 Fingerprint

For Android, you need to generate the SHA-1 fingerprint of your app's signing certificate.

### For Debug Build:
```bash
# Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

### For Release Build:
```bash
keytool -list -v -keystore /path/to/your/keystore.jks -alias your_key_alias
```

## 2. Configure OAuth Consent Screen

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your project
3. Navigate to "APIs & Services" > "OAuth consent screen"
4. Select "External" or "Internal" user type
5. Fill in the required fields:
   - App name: Attendance App
   - User support email: your email
   - Developer contact information: your email
6. Add the following scope under "Scopes":
   - `.../auth/spreadsheets` (for Google Sheets API)
7. Add test users if using External user type

## 3. Create OAuth Client ID

1. In Google Cloud Console, go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "OAuth client ID"
3. Select "Android" as the application type
4. Fill in the required fields:
   - Package name: `com.example.attend_me`
   - SHA-1 certificate fingerprint: [Your SHA-1 fingerprint from step 1]
5. Click "Create"

For iOS:
1. Select "iOS" as the application type
2. Bundle ID: `com.example.attendMe`
3. App Store ID: (optional)

For Web (if needed):
1. Select "Web application" as the application type
2. Add authorized redirect URIs:
   - `http://localhost:8080`
   - Your production domain if applicable

## 4. Enable Google Sheets API

1. In Google Cloud Console, go to "APIs & Services" > "Library"
2. Search for "Google Sheets API"
3. Click on it and press "Enable"

## 5. Add google-services.json

1. Download the `google-services.json` file from your Firebase/Google Cloud project
2. Place it in `android/app/` directory
3. Add the following to `android/build.gradle.kts` in the dependencies section:
   ```kotlin
   classpath("com.google.gms:google-services:4.3.15")
   ```
4. Add the following to `android/app/build.gradle.kts` at the top:
   ```kotlin
   apply plugin: 'com.google.gms.google-services'
   ```

If you don't have a Firebase project, you can create one at [Firebase Console](https://console.firebase.google.com/) and add your Android app with the package name `com.example.attend_me` and your SHA-1 fingerprint.

## 6. Update AndroidManifest.xml (if needed)

The app should automatically handle the required permissions, but ensure your `AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

## How It Works

The app uses the `google_sign_in` package to authenticate users and request the Sheets scope:

```dart
static final GoogleSignIn _googleSignIn = GoogleSignIn(
  scopes: [sheets.SheetsApi.spreadsheetsScope],
);
```

When syncing data, the app:
1. Signs in the user silently or prompts for sign-in
2. Gets authentication headers from the signed-in account
3. Uses these headers with the Google Sheets API client
4. Updates the spreadsheet with attendance data

## Troubleshooting

1. **"Google Sign-In failed"**: Check that SHA-1 fingerprint matches exactly
2. **"API not enabled"**: Ensure Google Sheets API is enabled in Cloud Console
3. **"Invalid scope"**: Verify the scope is correctly specified in the GoogleSignIn constructor
4. **"Permission denied"**: Check that the user has edit access to the target spreadsheet