import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/theme/app_colors.dart';
import '../../../widgets/buttons/soft_button.dart';

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  bool _isRequesting = false;

  Future<void> _requestPermission() async {
    setState(() => _isRequesting = true);

    try {
      final status = await Permission.location.request();

      if (status.isGranted) {
        // Also request background location for tracking
        await Permission.locationAlways.request();
        if (mounted) {
          context.go('/dashboard');
        }
      } else if (status.isPermanentlyDenied) {
        if (mounted) {
          _showSettingsDialog();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Location permission is required for tracking'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRequesting = false);
      }
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Permission Required'),
        content: const Text(
          'Location permission has been permanently denied. '
          'Please enable it in your device settings to use tracking features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: Text('Open Settings',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  void _skipPermission() {
    context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              // Illustration
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 100,
                  color: AppColors.primary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 48),
              // Title
              Text(
                'Enable Location',
                style: Theme.of(context).textTheme.displaySmall,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),
              // Description
              Text(
                'We need your location to track your walks, '
                'calculate distance, and build your city along your routes.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 32),
              // Features list
              _FeatureItem(
                icon: Icons.route_rounded,
                text: 'Track walking routes accurately',
              ).animate().fadeIn(delay: 400.ms).slideX(begin: -0.2),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.location_city_rounded,
                text: 'Build your city along your paths',
              ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2),
              const SizedBox(height: 16),
              _FeatureItem(
                icon: Icons.analytics_rounded,
                text: 'Get precise distance and pace data',
              ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2),
              const Spacer(),
              // Buttons
              SoftButton(
                text: 'Enable Location',
                onPressed: _requestPermission,
                isLoading: _isRequesting,
                width: double.infinity,
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _skipPermission,
                child: Text(
                  'Maybe Later',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ).animate().fadeIn(delay: 800.ms),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.secondary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.secondary, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}
