# Environment Configuration Guide

This document explains how to set up environment variables for Healtiefy.

## ⚠️ Security Notice

**NEVER commit sensitive files to version control!**

The following files contain secrets and are excluded from Git:
- `.env` - Flutter environment variables
- `android/secrets.properties` - Android-specific secrets
- `android/local.properties` - Local SDK paths

## Quick Setup

### 1. Flutter Environment (.env)

Copy the example file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env` with your actual values:

```env
# API Configuration
API_BASE_URL=https://api.healtiefy.com

# Spotify OAuth Configuration
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_REDIRECT_URI=healtiefy://callback/
SPOTIFY_AUTH_URL=https://accounts.spotify.com/authorize
SPOTIFY_TOKEN_URL=https://accounts.spotify.com/api/token
SPOTIFY_API_BASE_URL=https://api.spotify.com/v1

# Google Maps API Key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

### 2. Android Secrets (android/secrets.properties)

Copy the example file:

```bash
cp android/secrets.properties.example android/secrets.properties
```

Edit `android/secrets.properties`:

```properties
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
SPOTIFY_CLIENT_ID=your_spotify_client_id
SPOTIFY_REDIRECT_URI=healtiefy://callback/
```

## Getting API Keys

### Spotify

1. Go to [Spotify Developer Dashboard](https://developer.spotify.com/dashboard)
2. Create a new application
3. Copy the **Client ID**
4. Add redirect URI: `healtiefy://callback/`

### Google Maps

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Create or select a project
3. Enable "Maps SDK for Android"
4. Create an API key under Credentials
5. Restrict the key to your app's package name

## How It Works

### Flutter Side
- `flutter_dotenv` loads `.env` file at app startup
- `EnvConfig` class provides typed access to environment variables
- `AppConstants` uses `EnvConfig` for all sensitive values

### Android Side
- `secrets.properties` is loaded in `build.gradle.kts`
- Values are injected as manifest placeholders
- Google Maps API key is set in AndroidManifest.xml via placeholder

## Verification

After setup, run the app and check logs for warnings:

```
⚠️ WARNING: Missing environment variables: [SPOTIFY_CLIENT_ID, GOOGLE_MAPS_API_KEY]
```

If you see this, your `.env` file is not configured correctly.

## Troubleshooting

### "Missing environment variables" warning
- Ensure `.env` file exists in project root
- Check that all required variables have values
- Run `flutter clean && flutter pub get`

### Google Maps not loading
- Verify `GOOGLE_MAPS_API_KEY` in `android/secrets.properties`
- Ensure the API key has Maps SDK enabled
- Check key restrictions match your package name

### Spotify login fails
- Verify `SPOTIFY_CLIENT_ID` is correct
- Ensure redirect URI matches Spotify Dashboard exactly
- Check that `SPOTIFY_REDIRECT_URI` includes trailing slash

## File Locations

| Purpose | File | Git Status |
|---------|------|------------|
| Flutter env vars | `.env` | ❌ Ignored |
| Flutter env template | `.env.example` | ✅ Tracked |
| Android secrets | `android/secrets.properties` | ❌ Ignored |
| Android secrets template | `android/secrets.properties.example` | ✅ Tracked |
| Environment config class | `lib/core/config/env_config.dart` | ✅ Tracked |
| Constants using env | `lib/core/constants/app_constants.dart` | ✅ Tracked |
