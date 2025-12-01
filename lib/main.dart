import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

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
import 'services/city_builder_service.dart';
import 'services/ai_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final authService = AuthService(storageService: storageService);
  final locationService = LocationService();
  final healthService = HealthService();
  final spotifyService = SpotifyService();
  final cityBuilderService = CityBuilderService(storageService: storageService);
  final aiService = AIService();

  runApp(
    HealtifyApp(
      authService: authService,
      locationService: locationService,
      healthService: healthService,
      spotifyService: spotifyService,
      cityBuilderService: cityBuilderService,
      aiService: aiService,
      storageService: storageService,
    ),
  );
}

class HealtifyApp extends StatelessWidget {
  final AuthService authService;
  final LocationService locationService;
  final HealthService healthService;
  final SpotifyService spotifyService;
  final CityBuilderService cityBuilderService;
  final AIService aiService;
  final StorageService storageService;

  const HealtifyApp({
    super.key,
    required this.authService,
    required this.locationService,
    required this.healthService,
    required this.spotifyService,
    required this.cityBuilderService,
    required this.aiService,
    required this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: authService),
        RepositoryProvider.value(value: locationService),
        RepositoryProvider.value(value: healthService),
        RepositoryProvider.value(value: spotifyService),
        RepositoryProvider.value(value: cityBuilderService),
        RepositoryProvider.value(value: aiService),
        RepositoryProvider.value(value: storageService),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) =>
                AuthBloc(authService: authService)..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => DashboardBloc(
              healthService: healthService,
              storageService: storageService,
              aiService: aiService,
            ),
          ),
          BlocProvider(
            create: (context) => ProgressBloc(
              storageService: storageService,
              healthService: healthService,
            ),
          ),
          BlocProvider(
            create: (context) => MapBloc(
              locationService: locationService,
              cityBuilderService: cityBuilderService,
              storageService: storageService,
            ),
          ),
          BlocProvider(
            create: (context) => SpotifyBloc(spotifyService: spotifyService),
          ),
          BlocProvider(
            create: (context) => AccountBloc(
              authService: authService,
              storageService: storageService,
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
