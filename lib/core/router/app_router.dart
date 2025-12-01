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
import '../../features/map/screens/city_builder_screen.dart';
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
                path: 'city',
                name: 'cityBuilder',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => const CityBuilderScreen(),
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
    redirect: (context, state) {
      // We'll handle auth redirects in the actual screens
      return null;
    },
  );
}
