import '../config/env_config.dart';

class AppConstants {
  // App Info
  static const String appName = 'Healtiefy';
  static const String appVersion = '1.0.0';

  // API Endpoints - loaded from environment
  static String get baseUrl => EnvConfig.apiBaseUrl;

  // Spotify OAuth Configuration - loaded from environment
  // IMPORTANT: These values are loaded from .env file
  // Spotify Dashboard URL: https://developer.spotify.com/dashboard
  static String get spotifyClientId => EnvConfig.spotifyClientId;
  static String get spotifyRedirectUri => EnvConfig.spotifyRedirectUri;
  static String get spotifyAuthUrl => EnvConfig.spotifyAuthUrl;
  static String get spotifyTokenUrl => EnvConfig.spotifyTokenUrl;
  static String get spotifyApiBaseUrl => EnvConfig.spotifyApiBaseUrl;
  static const List<String> spotifyScopes = [
    'playlist-read-private',
    'user-read-email',
    'user-library-read',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
  ];

  // Google Maps API Key - loaded from environment
  static String get googleMapsApiKey => EnvConfig.googleMapsApiKey;

  // Firebase Collections
  static const String usersCollection = 'users';
  static const String sessionsCollection = 'sessions';
  static const String citiesCollection = 'cities';
  static const String buildingsCollection = 'buildings';

  // Default Values
  static const int defaultStepGoal = 10000;
  static const double defaultWaterGoal = 2.5; // liters
  static const int defaultCalorieGoal = 2000;
  static const double defaultHeight = 170.0; // cm
  static const double defaultWeight = 70.0; // kg

  // Health Calculations
  static const double caloriesPerStep = 0.04;
  static const double fatPerCalorie = 0.00013;
  static const double stepsPerKm = 1312.0;

  // Secure Storage Keys
  static const String spotifyAccessTokenKey = 'spotify_access_token';
  static const String spotifyRefreshTokenKey = 'spotify_refresh_token';
  static const String spotifyExpiresAtKey = 'spotify_expires_at';
  static const String spotifyCodeVerifierKey = 'spotify_code_verifier';

  // Local Storage Keys
  static const String userKey = 'user_data';
  static const String currentUserKey = 'current_user';
  static const String sessionsKey = 'sessions_data';
  static const String cityZonesKey = 'city_zones_data';
  static const String buildingsKey = 'buildings_data';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String hasLocationPermissionKey = 'has_location_permission';
  static const String lastSyncKey = 'last_sync_timestamp';
  static const String currentStreakKey = 'current_streak';
  static const String lastActivityDateKey = 'last_activity_date';
  static const String darkModeKey = 'dark_mode';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String languageKey = 'language';
  static const String distanceUnitKey = 'distance_unit';

  // Hive Box Names
  static const String userBox = 'user_box';
  static const String sessionsBox = 'sessions_box';
  static const String citiesBox = 'cities_box';
  static const String settingsBox = 'settings_box';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Tracking Configuration
  static const int trackingIntervalSeconds = 3;
  static const double trackingMinDistanceMeters = 20.0;
  static const Duration locationDebounce = Duration(milliseconds: 1000);

  // Limits
  static const int maxSessionsPerDay = 10;
  static const int maxBuildingsPerZone = 5;
  static const double minDistanceForBuilding = 0.5; // km

  // City Building
  static const double buildingCostBase = 100;
  static const Map<String, double> buildingCostMultiplier = {
    'house': 1.0,
    'shop': 1.5,
    'park': 2.0,
    'factory': 2.5,
    'school': 3.0,
    'hospital': 4.0,
    'stadium': 5.0,
  };
}
