import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class SessionDetailScreen extends StatelessWidget {
  final String sessionId;

  const SessionDetailScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    // TODO: Load actual session data from bloc
    final session = _MockSession();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Map
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_rounded, size: 18),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Mini map placeholder
                  Container(
                    color: AppColors.surface,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.map_rounded,
                            size: 64,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.3),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Route Map',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.3),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date and time
                  Text(
                    session.dateFormatted,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ).animate().fadeIn(),
                  const SizedBox(height: 4),
                  Text(
                    '${session.timeRange} • ${session.duration}',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 24),
                  // Main stats
                  _MainStatsSection(session: session)
                      .animate()
                      .fadeIn(delay: 200.ms),
                  const SizedBox(height: 24),
                  // Detailed stats
                  Text(
                    'Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).animate().fadeIn(delay: 300.ms),
                  const SizedBox(height: 16),
                  _DetailedStatsSection(session: session)
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 24),
                  // Achievements
                  Text(
                    'Achievements',
                    style: Theme.of(context).textTheme.titleLarge,
                  ).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 16),
                  _AchievementsSection(session: session)
                      .animate()
                      .fadeIn(delay: 600.ms),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainStatsSection extends StatelessWidget {
  final _MockSession session;

  const _MainStatsSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatColumn(
            icon: Icons.directions_walk_rounded,
            value: session.steps.toString(),
            label: 'Steps',
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          _StatColumn(
            icon: Icons.straighten_rounded,
            value: '${session.distance.toStringAsFixed(2)} km',
            label: 'Distance',
          ),
          Container(
            width: 1,
            height: 50,
            color: Colors.white.withValues(alpha: 0.2),
          ),
          _StatColumn(
            icon: Icons.local_fire_department_rounded,
            value: '${session.calories.toInt()}',
            label: 'Calories',
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatColumn({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withValues(alpha: 0.8), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DetailedStatsSection extends StatelessWidget {
  final _MockSession session;

  const _DetailedStatsSection({required this.session});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _DetailRow(
            icon: Icons.speed_rounded,
            label: 'Average Pace',
            value: '${session.avgPace.toStringAsFixed(1)} min/km',
            color: AppColors.primary,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.trending_up_rounded,
            label: 'Max Speed',
            value: '${session.maxSpeed.toStringAsFixed(1)} km/h',
            color: AppColors.secondary,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.landscape_rounded,
            label: 'Elevation Gain',
            value: '${session.elevation} m',
            color: AppColors.accent,
          ),
          const Divider(height: 24),
          _DetailRow(
            icon: Icons.location_city_rounded,
            label: 'Buildings Unlocked',
            value: '${session.buildingsUnlocked}',
            color: AppColors.purple,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _AchievementsSection extends StatelessWidget {
  final _MockSession session;

  const _AchievementsSection({required this.session});

  @override
  Widget build(BuildContext context) {
    final achievements = session.achievements;

    if (achievements.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.emoji_events_outlined,
                size: 48,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'No achievements this session',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: achievements.map((achievement) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achievement.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement.icon,
                  color: achievement.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// Mock data class
class _MockSession {
  final int steps = 8543;
  final double distance = 5.67;
  final double calories = 312.5;
  final double avgPace = 6.2;
  final double maxSpeed = 12.4;
  final int elevation = 45;
  final int buildingsUnlocked = 3;

  String get dateFormatted => 'Today';
  String get timeRange => '08:30 - 09:45';
  String get duration => '1h 15m';

  List<_Achievement> get achievements => [
        _Achievement(
          icon: Icons.emoji_events_rounded,
          title: '5K Champion',
          description: 'Walked 5+ kilometers',
          color: AppColors.accent,
        ),
        _Achievement(
          icon: Icons.local_fire_department_rounded,
          title: 'Calorie Crusher',
          description: 'Burned 300+ calories',
          color: AppColors.error,
        ),
      ];
}

class _Achievement {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _Achievement({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
