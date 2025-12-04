import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/profile_setup_screen.dart';
import '../../features/auth/screens/location_permission_screen.dart';
import '../../features/main/screens/main_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/progress/screens/session_detail_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/farm/screens/farm_screen.dart';
import '../../features/spotify/screens/spotify_screen.dart';
import '../../features/account/screens/account_screen.dart';
import '../../features/account/screens/edit_profile_screen.dart';
import '../../features/splash/screens/splash_screen.dart';
import '../../features/onboarding/screens/onboarding_screen.dart';

class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>();
  static final _shellNavigatorKey = GlobalKey<NavigatorState>();

  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    // Handle deep links - redirect Spotify OAuth callback to appropriate screen
    redirect: (context, state) {
      final path = state.uri.path;
      final fullUri = state.uri.toString();

      // Debug log
      debugPrint('[GoRouter] Redirect check - path: $path, fullUri: $fullUri');

      // Spotify OAuth callback - redirect to spotify screen
      // The deep link handler in main.dart handles the token exchange
      // We just need to make sure the user ends up on the spotify screen
      if (path == '/callback' ||
          path == '/callback/' ||
          fullUri.contains('healtiefy://callback') ||
          fullUri.contains('callback?code=') ||
          fullUri.contains('callback/?code=')) {
        debugPrint(
            '[GoRouter] Spotify callback detected, redirecting to /spotify');
        return '/spotify';
      }

      return null;
    },
    // Error handler for unknown routes
    errorBuilder: (context, state) {
      debugPrint('[GoRouter] Error - unknown route: ${state.uri}');
      // For any callback-related URLs, show loading and navigate after
      final uri = state.uri.toString();
      if (uri.contains('callback')) {
        return const _CallbackLoadingScreen();
      }
      return _ErrorScreen(uri: state.uri.toString());
    },
    routes: [
      // Splash Screen
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/location-permission',
        name: 'locationPermission',
        builder: (context, state) => const LocationPermissionScreen(),
      ),

      // Main App with Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/progress',
            name: 'progress',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const ProgressScreen(),
            ),
            routes: [
              GoRoute(
                path: 'session/:sessionId',
                name: 'sessionDetail',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => SessionDetailScreen(
                  sessionId: state.pathParameters['sessionId']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const MapScreen(),
            ),
            routes: [
              GoRoute(
                path: 'farm',
                name: 'farm',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const FarmScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/spotify',
            name: 'spotify',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SpotifyScreen(),
            ),
          ),
          GoRoute(
            path: '/account',
            name: 'account',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const AccountScreen(),
            ),
            routes: [
              GoRoute(
                path: 'edit',
                name: 'editProfile',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const EditProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Loading screen shown during OAuth callback processing
class _CallbackLoadingScreen extends StatefulWidget {
  const _CallbackLoadingScreen();

  @override
  State<_CallbackLoadingScreen> createState() => _CallbackLoadingScreenState();
}

class _CallbackLoadingScreenState extends State<_CallbackLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to spotify screen after a brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        AppRouter.router.go('/spotify');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Connecting to Spotify...'),
          ],
        ),
      ),
    );
  }
}

/// Error screen with navigation back to dashboard
class _ErrorScreen extends StatelessWidget {
  final String uri;

  const _ErrorScreen({required this.uri});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => AppRouter.router.go('/dashboard'),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Page not found: $uri'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => AppRouter.router.go('/dashboard'),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}
