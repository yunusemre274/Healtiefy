import 'dart:math';

import '../data/models/session_model.dart';
import '../data/models/dashboard_models.dart';
import '../data/models/user_model.dart';

class AIService {
  final Random _random = Random();

  // Generate personalized fitness tips based on user data
  AITip generatePersonalizedTip({
    required User user,
    required List<Session> recentSessions,
    required DashboardStats todayStats,
  }) {
    final tips = <AITip>[];
    final now = DateTime.now();

    // Check step progress
    final stepProgress = todayStats.stepProgress;
    if (stepProgress < 0.25) {
      tips.add(AITip(
        id: 'tip_${now.millisecondsSinceEpoch}',
        title: 'Time to Move!',
        message:
            "You're at ${(stepProgress * 100).toInt()}% of your daily step goal. "
            "A 15-minute walk could boost your progress significantly! 🚶",
        category: 'motivation',
        createdAt: now,
      ));
    } else if (stepProgress >= 1.0) {
      tips.add(AITip(
        id: 'tip_${now.millisecondsSinceEpoch}',
        title: 'Goal Achieved! 🎉',
        message: "Amazing! You've completed your daily step goal! "
            "Keep the momentum going and unlock new city zones!",
        category: 'motivation',
        createdAt: now,
      ));
    }

    // Check water intake
    if (todayStats.waterProgress < 0.5) {
      tips.add(AITip(
        id: 'tip_water_${now.millisecondsSinceEpoch}',
        title: 'Stay Hydrated! 💧',
        message:
            "You've only consumed ${todayStats.waterConsumed.toStringAsFixed(1)}L of water today. "
            "Proper hydration improves performance and recovery.",
        category: 'health',
        createdAt: now,
      ));
    }

    // Check heart rate
    if (todayStats.averageHeartRate > 100) {
      tips.add(AITip(
        id: 'tip_hr_${now.millisecondsSinceEpoch}',
        title: 'Heart Rate Insight',
        message:
            "Your average heart rate is ${todayStats.averageHeartRate.toInt()} bpm. "
            "Consider incorporating some recovery walks to balance intensity.",
        category: 'health',
        createdAt: now,
      ));
    }

    // Session consistency
    if (recentSessions.isEmpty) {
      tips.add(AITip(
        id: 'tip_session_${now.millisecondsSinceEpoch}',
        title: 'Start Your Journey!',
        message: "You haven't logged any walking sessions yet. "
            "Start your first walk and begin building your city! 🏙️",
        category: 'motivation',
        createdAt: now,
      ));
    }

    // Return a random tip or default
    if (tips.isEmpty) {
      return AITip(
        id: 'tip_default_${now.millisecondsSinceEpoch}',
        title: 'Keep Going! 💪',
        message:
            "You're doing great! Consistency is key to achieving your fitness goals. "
            "Every step counts towards a healthier you.",
        category: 'motivation',
        createdAt: now,
      );
    }

    return tips[_random.nextInt(tips.length)];
  }

  // Generate weekly analysis
  Map<String, dynamic> generateWeeklyAnalysis(List<Session> weekSessions) {
    if (weekSessions.isEmpty) {
      return {
        'totalSteps': 0,
        'totalDistance': 0.0,
        'totalCalories': 0.0,
        'avgSessionDuration': 0,
        'mostActiveDay': 'N/A',
        'trend': 'neutral',
        'message': 'Start walking to see your weekly analysis!',
      };
    }

    final totalSteps = weekSessions.fold(0, (sum, s) => sum + s.steps);
    final totalDistance =
        weekSessions.fold(0.0, (sum, s) => sum + s.distanceKm);
    final totalCalories = weekSessions.fold(0.0, (sum, s) => sum + s.calories);
    final avgDuration =
        weekSessions.fold(0, (sum, s) => sum + s.durationMinutes) ~/
            weekSessions.length;

    // Find most active day
    final daySteps = <int, int>{};
    for (final session in weekSessions) {
      final day = session.date.weekday;
      daySteps[day] = (daySteps[day] ?? 0) + session.steps;
    }

    int mostActiveDay = 1;
    int maxSteps = 0;
    daySteps.forEach((day, steps) {
      if (steps > maxSteps) {
        maxSteps = steps;
        mostActiveDay = day;
      }
    });

    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Determine trend
    String trend = 'neutral';
    if (weekSessions.length >= 2) {
      final firstHalf = weekSessions.sublist(0, weekSessions.length ~/ 2);
      final secondHalf = weekSessions.sublist(weekSessions.length ~/ 2);

      final firstHalfAvg =
          firstHalf.fold(0, (sum, s) => sum + s.steps) / firstHalf.length;
      final secondHalfAvg =
          secondHalf.fold(0, (sum, s) => sum + s.steps) / secondHalf.length;

      if (secondHalfAvg > firstHalfAvg * 1.1) {
        trend = 'improving';
      } else if (secondHalfAvg < firstHalfAvg * 0.9) {
        trend = 'declining';
      }
    }

    String message;
    switch (trend) {
      case 'improving':
        message =
            "Great progress! You're getting more active. Keep up the momentum! 📈";
        break;
      case 'declining':
        message = "Your activity has decreased. Let's get back on track! 💪";
        break;
      default:
        message =
            "You're maintaining steady activity. Challenge yourself to do more! 🎯";
    }

    return {
      'totalSteps': totalSteps,
      'totalDistance': totalDistance,
      'totalCalories': totalCalories,
      'avgSessionDuration': avgDuration,
      'mostActiveDay': dayNames[mostActiveDay - 1],
      'trend': trend,
      'message': message,
      'sessionsCount': weekSessions.length,
    };
  }

  // Generate custom challenges
  List<Challenge> generateChallenges({
    required User user,
    required List<Session> recentSessions,
    required int currentTotalSteps,
  }) {
    final now = DateTime.now();
    final challenges = <Challenge>[];

    // Daily step challenge
    challenges.add(Challenge(
      id: 'daily_${now.day}',
      title: 'Daily Walker',
      description: 'Complete your daily step goal',
      targetValue: user.stepGoal,
      currentValue: currentTotalSteps,
      unit: 'steps',
      reward: '🏆 +1 Building Slot',
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    ));

    // Distance challenge
    final avgDistance = recentSessions.isEmpty
        ? 2.0
        : recentSessions.fold(0.0, (sum, s) => sum + s.distanceKm) /
            recentSessions.length;

    challenges.add(Challenge(
      id: 'distance_${now.day}',
      title: 'Distance Explorer',
      description: 'Walk ${(avgDistance * 1.2).toStringAsFixed(1)} km today',
      targetValue: ((avgDistance * 1.2) * 1000).toInt(),
      currentValue:
          (recentSessions.isEmpty ? 0 : recentSessions.last.distanceKm * 1000)
              .toInt(),
      unit: 'meters',
      reward: '🌟 Unlock Park Building',
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    ));

    // Weekly challenge
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    challenges.add(Challenge(
      id: 'weekly_${now.weekOfYear}',
      title: 'Weekly Warrior',
      description: 'Walk 50,000 steps this week',
      targetValue: 50000,
      currentValue: recentSessions
          .where((s) => s.date.isAfter(weekStart))
          .fold(0, (sum, s) => sum + s.steps),
      unit: 'steps',
      reward: '🏅 Gold Badge',
      startDate: weekStart,
      endDate: weekStart.add(const Duration(days: 7)),
    ));

    // Special city building challenge
    challenges.add(Challenge(
      id: 'city_${now.day}',
      title: 'City Expansion',
      description: 'Walk 4 km to unlock a new building area',
      targetValue: 4000,
      currentValue:
          (recentSessions.isEmpty ? 0 : recentSessions.last.distanceKm * 1000)
              .toInt(),
      unit: 'meters',
      reward: '🏙️ New City Zone',
      startDate: DateTime(now.year, now.month, now.day),
      endDate: DateTime(now.year, now.month, now.day, 23, 59, 59),
    ));

    return challenges;
  }

  // Compare with community average
  Map<String, dynamic> compareWithCommunity({
    required int userSteps,
    required double userDistance,
    required double userCalories,
  }) {
    // Simulated community averages
    final communityAvgSteps = 7500;
    final communityAvgDistance = 5.5;
    final communityAvgCalories = 300.0;

    final stepsPercentile = _calculatePercentile(userSteps, communityAvgSteps);
    final distancePercentile =
        _calculatePercentile(userDistance, communityAvgDistance);
    final caloriesPercentile =
        _calculatePercentile(userCalories, communityAvgCalories);

    return {
      'communityAvgSteps': communityAvgSteps,
      'communityAvgDistance': communityAvgDistance,
      'communityAvgCalories': communityAvgCalories,
      'stepsPercentile': stepsPercentile,
      'distancePercentile': distancePercentile,
      'caloriesPercentile': caloriesPercentile,
      'overallRank':
          ((stepsPercentile + distancePercentile + caloriesPercentile) / 3)
              .round(),
      'message': _generateCompetitiveMessage(
        (stepsPercentile + distancePercentile + caloriesPercentile) ~/ 3,
      ),
    };
  }

  int _calculatePercentile(num userValue, num avgValue) {
    if (avgValue == 0) return 50;
    final ratio = userValue / avgValue;
    // Simple percentile estimation
    if (ratio >= 2.0) return 95;
    if (ratio >= 1.5) return 85;
    if (ratio >= 1.2) return 75;
    if (ratio >= 1.0) return 60;
    if (ratio >= 0.8) return 45;
    if (ratio >= 0.5) return 30;
    return 15;
  }

  String _generateCompetitiveMessage(int percentile) {
    if (percentile >= 90) {
      return "🏆 Outstanding! You're in the top 10% of all users!";
    } else if (percentile >= 75) {
      return "🌟 Excellent! You're outperforming 75% of users!";
    } else if (percentile >= 50) {
      return "💪 Good job! You're above average. Keep pushing!";
    } else if (percentile >= 25) {
      return "📈 You're making progress! A bit more effort and you'll shine!";
    } else {
      return "🚀 Every step counts! Start building your momentum today!";
    }
  }
}

// Extension to get week of year
extension DateTimeExtension on DateTime {
  int get weekOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    final daysDifference = difference(firstDayOfYear).inDays;
    return ((daysDifference + firstDayOfYear.weekday) / 7).ceil();
  }
}
