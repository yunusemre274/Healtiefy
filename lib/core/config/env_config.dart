import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Environment configuration loaded from .env file
/// All sensitive values are read from environment variables
class EnvConfig {
  // Singleton pattern
  static final EnvConfig _instance = EnvConfig._internal();
  factory EnvConfig() => _instance;
  EnvConfig._internal();

  /// Initialize environment configuration
  /// Must be called before accessing any env values
  static Future<void> init() async {
    await dotenv.load(fileName: ".env");
  }

  // API Configuration
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://api.healtiefy.com';

  // Spotify OAuth Configuration
  static String get spotifyClientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';

  static String get spotifyRedirectUri =>
      dotenv.env['SPOTIFY_REDIRECT_URI'] ?? 'healtiefy://callback/';

  static String get spotifyAuthUrl =>
      dotenv.env['SPOTIFY_AUTH_URL'] ??
      'https://accounts.spotify.com/authorize';

  static String get spotifyTokenUrl =>
      dotenv.env['SPOTIFY_TOKEN_URL'] ??
      'https://accounts.spotify.com/api/token';

  static String get spotifyApiBaseUrl =>
      dotenv.env['SPOTIFY_API_BASE_URL'] ?? 'https://api.spotify.com/v1';

  // Google Maps API Key
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  /// Check if all required environment variables are set
  static bool get isConfigured {
    return spotifyClientId.isNotEmpty && googleMapsApiKey.isNotEmpty;
  }

  /// Get a list of missing required environment variables
  static List<String> get missingVariables {
    final missing = <String>[];
    if (spotifyClientId.isEmpty) missing.add('SPOTIFY_CLIENT_ID');
    if (googleMapsApiKey.isEmpty) missing.add('GOOGLE_MAPS_API_KEY');
    return missing;
  }
}
