import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';

import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/dashboard/bloc/dashboard_bloc.dart';
import 'features/progress/bloc/progress_bloc.dart';
import 'features/map/bloc/map_bloc.dart';
import 'features/spotify/bloc/spotify_bloc.dart';
import 'features/account/bloc/account_bloc.dart';
import 'services/auth_service.dart';
import 'services/location_service.dart';
import 'services/health_service.dart';
import 'services/spotify_service.dart';
import 'services/spotify_auth_service.dart';
import 'services/city_builder_service.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';
import 'services/local_cache_service.dart';
import 'services/tracking_service.dart';
import 'services/farm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize cache manager (Hive-based caching)
  final cacheManager = CacheManager();
  await cacheManager.init();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final spotifyAuthService = SpotifyAuthService();
  final authService = AuthService(storageService: storageService);
  final locationService = LocationService();
  final healthService = HealthService();
  final spotifyService = SpotifyService(authService: spotifyAuthService);
  final cityBuilderService = CityBuilderService(storageService: storageService);
  final aiService = AIService();
  final trackingService = TrackingService();
  final farmService = FarmService();
  await farmService.init();

  runApp(
    HealtifyApp(
      authService: authService,
      locationService: locationService,
      healthService: healthService,
      spotifyService: spotifyService,
      spotifyAuthService: spotifyAuthService,
      cityBuilderService: cityBuilderService,
      aiService: aiService,
      storageService: storageService,
      cacheManager: cacheManager,
      trackingService: trackingService,
      farmService: farmService,
    ),
  );
}

class HealtifyApp extends StatefulWidget {
  final AuthService authService;
  final LocationService locationService;
  final HealthService healthService;
  final SpotifyService spotifyService;
  final SpotifyAuthService spotifyAuthService;
  final CityBuilderService cityBuilderService;
  final AIService aiService;
  final StorageService storageService;
  final CacheManager cacheManager;
  final TrackingService trackingService;
  final FarmService farmService;

  const HealtifyApp({
    super.key,
    required this.authService,
    required this.locationService,
    required this.healthService,
    required this.spotifyService,
    required this.spotifyAuthService,
    required this.cityBuilderService,
    required this.aiService,
    required this.storageService,
    required this.cacheManager,
    required this.trackingService,
    required this.farmService,
  });

  @override
  State<HealtifyApp> createState() => _HealtifyAppState();
}

class _HealtifyAppState extends State<HealtifyApp> {
  late AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Handle links that opened the app
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle links while app is running
    _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Handle Spotify OAuth callback
    if (uri.scheme == 'healtiefy' && uri.host == 'callback') {
      widget.spotifyAuthService.handleRedirectCallback(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: widget.authService),
        RepositoryProvider.value(value: widget.locationService),
        RepositoryProvider.value(value: widget.healthService),
        RepositoryProvider.value(value: widget.spotifyService),
        RepositoryProvider.value(value: widget.spotifyAuthService),
        RepositoryProvider.value(value: widget.cityBuilderService),
        RepositoryProvider.value(value: widget.aiService),
        RepositoryProvider.value(value: widget.storageService),
        RepositoryProvider.value(value: widget.cacheManager),
        RepositoryProvider.value(value: widget.trackingService),
        RepositoryProvider.value(value: widget.farmService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(authService: widget.authService)
              ..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              healthService: widget.healthService,
              storageService: widget.storageService,
              aiService: widget.aiService,
            ),
          ),
          BlocProvider(
            create: (context) => ProgressBloc(
              storageService: widget.storageService,
              healthService: widget.healthService,
            ),
          ),
          BlocProvider(
            create: (context) => MapBloc(
              locationService: widget.locationService,
              cityBuilderService: widget.cityBuilderService,
              storageService: widget.storageService,
            ),
          ),
          BlocProvider(
            create: (context) =>
                SpotifyBloc(spotifyService: widget.spotifyService),
          ),
          BlocProvider(
            create: (context) => AccountBloc(
              authService: widget.authService,
              storageService: widget.storageService,
            ),
          ),
        ],
        child: MaterialApp.router(
          title: 'Healtiefy',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
