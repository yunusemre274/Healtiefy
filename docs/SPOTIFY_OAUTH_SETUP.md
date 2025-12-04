# Spotify OAuth Setup Guide for Healtiefy

## Overview
This document explains how the Spotify OAuth 2.0 + PKCE authentication flow is configured in Healtiefy.

---

## 🔑 Critical Configuration

### Redirect URI (MUST match exactly!)

```
healtiefy://callback/
```

> ⚠️ **IMPORTANT**: The trailing slash (`/`) is required! Using `healtiefy://callback` (without slash) will cause "Page not found" errors.

---

## 📋 Spotify Developer Dashboard Setup

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Select your application (or create one)
3. Click **Settings**
4. Under **Redirect URIs**, add:
   ```
   healtiefy://callback/
   ```
5. Click **Save**

### Current App Configuration
- **Client ID**: `b2dbc08c99984f2cbd7405bfba25133a`
- **Redirect URI**: `healtiefy://callback/`
- **Auth Method**: PKCE (Proof Key for Code Exchange) - No client secret needed

---

## 📁 File Configuration

### 1. AndroidManifest.xml
Location: `android/app/src/main/AndroidManifest.xml`

```xml
<intent-filter android:autoVerify="true">
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data
        android:scheme="healtiefy"
        android:host="callback"
        android:pathPrefix="/" />
</intent-filter>
```

### 2. app_constants.dart
Location: `lib/core/constants/app_constants.dart`

```dart
static const String spotifyRedirectUri = 'healtiefy://callback/';
```

### 3. Deep Link Handler
Location: `lib/main.dart`

The `_handleDeepLink()` method handles incoming URIs and forwards them to `SpotifyAuthService`.

### 4. Spotify Auth Service
Location: `lib/services/spotify_auth_service.dart`

Handles the full OAuth flow:
- Generate PKCE code verifier/challenge
- Build authorization URL
- Exchange authorization code for tokens
- Refresh tokens when expired
- Secure token storage

---

## 🧪 Testing the OAuth Flow

### Step 1: Run the app
```bash
flutter clean
flutter pub get
flutter run
```

### Step 2: Trigger Spotify Login
Navigate to the Spotify integration screen and tap "Connect to Spotify"

### Step 3: Watch the logs
Look for these messages in sequence:

```
════════════════════════════════════════════════════════════════
[DeepLink] Spotify redirect captured.
[DeepLink] Handling: scheme=healtiefy, host=callback, path=/
[DeepLink] ✓ Authorization code: AQBZ...
════════════════════════════════════════════════════════════════
[SpotifyAuth] ✓ Authorization code received
[SpotifyAuth] Token exchange starting...
[SpotifyAuth] Token response status: 200
════════════════════════════════════════════════════════════════
[SpotifyAuth] ✓ Token exchange success!
[SpotifyAuth] ✓ Access token received
[SpotifyAuth] ✓ Refresh token received
[SpotifyAuth] ✓ Tokens saved to secure storage
════════════════════════════════════════════════════════════════
[SpotifyBloc] Successfully connected to Spotify
```

### Step 4: Verify connection
The UI should update to show "Connected to Spotify" and display your playlists.

---

## ❌ Common Errors & Solutions

### "Page not found: /?code=..."
**Cause**: Redirect URI mismatch
**Solution**: 
1. Verify Spotify Dashboard has EXACTLY `healtiefy://callback/` (with trailing slash)
2. Verify `app_constants.dart` has `healtiefy://callback/` (with trailing slash)
3. Rebuild the app (`flutter clean && flutter run`)

### "INVALID_CLIENT: Invalid redirect URI"
**Cause**: The redirect URI in your token exchange request doesn't match Spotify Dashboard
**Solution**: Ensure `AppConstants.spotifyRedirectUri` exactly matches Dashboard setting

### "access_denied"
**Cause**: User clicked "Cancel" on Spotify authorization page
**Solution**: This is expected behavior. User must click "Agree" to authorize.

### App not opening after Spotify authorization
**Cause**: Deep link intent filter not registered
**Solution**: 
1. Uninstall the app completely from device
2. Run `flutter clean`
3. Run `flutter run` to reinstall

---

## 🔐 Security Notes

- **PKCE** is used instead of client secret for mobile apps (more secure)
- Tokens are stored in **Flutter Secure Storage** (encrypted)
- Access tokens auto-refresh 5 minutes before expiry
- Code verifier is securely stored during auth flow

---

## 📱 Supported Platforms

- ✅ Android (fully tested)
- ⬜ iOS (requires additional setup in Info.plist)

---

## 📝 Scopes Requested

```dart
static const List<String> spotifyScopes = [
  'playlist-read-private',
  'user-read-email',
  'user-library-read',
  'user-read-playback-state',
  'user-modify-playback-state',
  'user-read-currently-playing',
];
```

---

## 🆘 Need Help?

1. Check the logs using `flutter run` - all auth steps are logged
2. Verify Spotify Dashboard redirect URI matches exactly
3. Try uninstalling and reinstalling the app
4. Clear app data and try again
