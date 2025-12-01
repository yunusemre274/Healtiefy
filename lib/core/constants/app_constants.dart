class AppConstants {
  // App Info
  static const String appName = 'Healtiefy';
  static const String appVersion = '1.0.0';

  // API Endpoints
  static const String baseUrl = 'https://api.healtiefy.com';

  // Spotify
  static const String spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID';
  static const String spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET';
  static const String spotifyRedirectUri = 'healtiefy://spotify-callback';
  static const String spotifyScopes =
      'user-read-playback-state user-modify-playback-state user-read-currently-playing playlist-read-private playlist-read-collaborative';

  // Google Maps
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Firebase
  static const String firebaseProjectId = 'YOUR_FIREBASE_PROJECT_ID';

  // Default Values
  static const int defaultStepGoal = 10000;
  static const double defaultWaterGoal = 2.5; // liters
  static const int defaultCalorieGoal = 2000;

  // Health Calculations
  static const double caloriesPerStep =
      0.04; // average calories burned per step
  static const double fatPerCalorie =
      0.00013; // grams of fat burned per calorie
  static const double stepsPerKm = 1312.0; // average steps per kilometer

  // Storage Keys
  static const String userKey = 'user_data';
  static const String sessionsKey = 'sessions_data';
  static const String cityZonesKey = 'city_zones_data';
  static const String buildingsKey = 'buildings_data';
  static const String spotifyTokenKey = 'spotify_token';
  static const String isFirstLaunchKey = 'is_first_launch';
  static const String hasLocationPermissionKey = 'has_location_permission';

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Debounce Durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration locationDebounce = Duration(milliseconds: 1000);

  // Limits
  static const int maxSessionsPerDay = 10;
  static const int maxBuildingsPerZone = 5;
  static const double minDistanceForBuilding = 0.5; // km

  // City Building
  static const double buildingCostBase = 100; // steps required
  static const Map<String, double> buildingCostMultiplier = {
    'house': 1.0,
    'shop': 1.5,
    'park': 2.0,
    'factory': 2.5,
    'school': 3.0,
  };
}
