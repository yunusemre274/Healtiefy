import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/dashboard_models.dart';
import '../../../data/models/session_model.dart';
import '../../../services/health_service.dart';
import '../../../services/storage_service.dart';
import '../../../services/ai_service.dart';
import '../../../services/step_tracking_service.dart';

// Events
abstract class DashboardEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardLoadRequested extends DashboardEvent {}

class DashboardRefreshRequested extends DashboardEvent {}

class DashboardWaterIntakeAdded extends DashboardEvent {
  final double liters;

  DashboardWaterIntakeAdded({required this.liters});

  @override
  List<Object?> get props => [liters];
}

class DashboardStepsUpdated extends DashboardEvent {
  final int steps;

  DashboardStepsUpdated({required this.steps});

  @override
  List<Object?> get props => [steps];
}

class DashboardSensorStepsUpdated extends DashboardEvent {
  final int sensorSteps;

  DashboardSensorStepsUpdated({required this.sensorSteps});

  @override
  List<Object?> get props => [sensorSteps];
}

// States
abstract class DashboardState extends Equatable {
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final AITip? aiTip;
  final Challenge? currentChallenge;
  final List<Session> todaySessions;
  final Map<String, dynamic>? weeklyAnalysis;
  final Map<String, dynamic>? competitiveStats;
  final bool stepSensorAvailable;

  DashboardLoaded({
    required this.stats,
    this.aiTip,
    this.currentChallenge,
    this.todaySessions = const [],
    this.weeklyAnalysis,
    this.competitiveStats,
    this.stepSensorAvailable = true,
  });

  DashboardLoaded copyWith({
    DashboardStats? stats,
    AITip? aiTip,
    Challenge? currentChallenge,
    List<Session>? todaySessions,
    Map<String, dynamic>? weeklyAnalysis,
    Map<String, dynamic>? competitiveStats,
    bool? stepSensorAvailable,
  }) {
    return DashboardLoaded(
      stats: stats ?? this.stats,
      aiTip: aiTip ?? this.aiTip,
      currentChallenge: currentChallenge ?? this.currentChallenge,
      todaySessions: todaySessions ?? this.todaySessions,
      weeklyAnalysis: weeklyAnalysis ?? this.weeklyAnalysis,
      competitiveStats: competitiveStats ?? this.competitiveStats,
      stepSensorAvailable: stepSensorAvailable ?? this.stepSensorAvailable,
    );
  }

  @override
  List<Object?> get props => [
        stats,
        aiTip,
        currentChallenge,
        todaySessions,
        weeklyAnalysis,
        competitiveStats,
        stepSensorAvailable,
      ];
}

class DashboardError extends DashboardState {
  final String message;

  DashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final HealthService healthService;
  final StorageService storageService;
  final AIService aiService;
  final StepTrackingService? stepTrackingService;

  StreamSubscription<int>? _stepSubscription;

  DashboardBloc({
    required this.healthService,
    required this.storageService,
    required this.aiService,
    this.stepTrackingService,
  }) : super(DashboardInitial()) {
    on<DashboardLoadRequested>(_onLoadRequested);
    on<DashboardRefreshRequested>(_onRefreshRequested);
    on<DashboardWaterIntakeAdded>(_onWaterIntakeAdded);
    on<DashboardStepsUpdated>(_onStepsUpdated);
    on<DashboardSensorStepsUpdated>(_onSensorStepsUpdated);

    // Subscribe to step tracking service if available
    _subscribeToStepService();
  }

  void _subscribeToStepService() {
    if (stepTrackingService != null) {
      _stepSubscription = stepTrackingService!.stepStream.listen((steps) {
        add(DashboardSensorStepsUpdated(sensorSteps: steps));
      });
    }
  }

  Future<void> _onLoadRequested(
    DashboardLoadRequested event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      final stats = await _calculateStats();
      final user = storageService.getUser();
      final todaySessions = storageService.getSessionsForDate(DateTime.now());

      // Get week sessions for analysis
      final now = DateTime.now();
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekSessions = storageService.getSessionsForDateRange(
        weekStart,
        now,
      );

      AITip? aiTip;
      Map<String, dynamic>? weeklyAnalysis;
      Map<String, dynamic>? competitiveStats;
      List<Challenge>? challenges;

      if (user != null) {
        aiTip = aiService.generatePersonalizedTip(
          user: user,
          recentSessions: todaySessions,
          todayStats: stats,
        );

        weeklyAnalysis = aiService.generateWeeklyAnalysis(weekSessions);

        competitiveStats = aiService.compareWithCommunity(
          userSteps: stats.totalSteps,
          userDistance: stats.totalDistanceKm,
          userCalories: stats.totalCalories,
        );

        challenges = aiService.generateChallenges(
          user: user,
          recentSessions: todaySessions,
          currentTotalSteps: stats.totalSteps,
        );
      }

      emit(DashboardLoaded(
        stats: stats,
        aiTip: aiTip,
        currentChallenge:
            challenges?.isNotEmpty == true ? challenges!.first : null,
        todaySessions: todaySessions,
        weeklyAnalysis: weeklyAnalysis,
        competitiveStats: competitiveStats,
        stepSensorAvailable: stepTrackingService?.sensorAvailable ?? false,
      ));
    } catch (e) {
      emit(
          DashboardError(message: 'Failed to load dashboard: ${e.toString()}'));
    }
  }

  Future<void> _onRefreshRequested(
    DashboardRefreshRequested event,
    Emitter<DashboardState> emit,
  ) async {
    add(DashboardLoadRequested());
  }

  Future<void> _onWaterIntakeAdded(
    DashboardWaterIntakeAdded event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    try {
      await storageService.addWaterIntake(event.liters, DateTime.now());

      final newWaterConsumed = currentState.stats.waterConsumed + event.liters;
      final updatedStats = currentState.stats.copyWith(
        waterConsumed: newWaterConsumed,
      );

      emit(currentState.copyWith(stats: updatedStats));
    } catch (e) {
      // Silently fail for water intake
    }
  }

  Future<void> _onStepsUpdated(
    DashboardStepsUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final user = storageService.getUser();

    final calories =
        healthService.calculateCaloriesFromSteps(event.steps, user: user);
    final fatBurned = healthService.calculateFatBurned(calories);
    final distance =
        healthService.calculateDistanceFromSteps(event.steps, user: user);

    final updatedStats = currentState.stats.copyWith(
      totalSteps: event.steps,
      totalCalories: calories,
      totalFatBurned: fatBurned,
      totalDistanceKm: distance,
    );

    emit(currentState.copyWith(stats: updatedStats));
  }

  Future<void> _onSensorStepsUpdated(
    DashboardSensorStepsUpdated event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    final user = storageService.getUser();

    // Get session steps from storage
    final todaySessions = storageService.getSessionsForDate(DateTime.now());
    int sessionSteps = 0;
    for (final session in todaySessions) {
      sessionSteps += session.steps;
    }

    // Total steps = sensor steps + session steps from today
    // (sensor steps are live, sessions are persisted)
    final totalSteps = event.sensorSteps;

    final calories =
        healthService.calculateCaloriesFromSteps(totalSteps, user: user);
    final fatBurned = healthService.calculateFatBurned(calories);
    final distance =
        healthService.calculateDistanceFromSteps(totalSteps, user: user);

    final updatedStats = currentState.stats.copyWith(
      totalSteps: totalSteps,
      totalCalories: currentState.stats.totalCalories > calories
          ? currentState.stats.totalCalories
          : calories,
      totalFatBurned: currentState.stats.totalFatBurned > fatBurned
          ? currentState.stats.totalFatBurned
          : fatBurned,
      totalDistanceKm: currentState.stats.totalDistanceKm > distance
          ? currentState.stats.totalDistanceKm
          : distance,
    );

    emit(currentState.copyWith(stats: updatedStats));
  }

  Future<DashboardStats> _calculateStats() async {
    final now = DateTime.now();
    final todaySessions = storageService.getSessionsForDate(now);
    final user = storageService.getUser();

    int totalSteps = 0;
    double totalCalories = 0;
    double totalFatBurned = 0;
    double totalDistance = 0;
    double totalHeartRate = 0;
    int heartRateCount = 0;
    int totalMinutes = 0;

    for (final session in todaySessions) {
      totalSteps += session.steps;
      totalCalories += session.calories;
      totalFatBurned += session.fatBurned;
      totalDistance += session.distanceKm;
      totalMinutes += session.durationMinutes;

      if (session.heartRateAvg != null) {
        totalHeartRate += session.heartRateAvg!;
        heartRateCount++;
      }
    }

    // If step tracking service is available, use sensor steps
    if (stepTrackingService != null && stepTrackingService!.sensorAvailable) {
      final sensorSteps = stepTrackingService!.totalStepsToday;
      if (sensorSteps > totalSteps) {
        totalSteps = sensorSteps;
        // Recalculate derived values
        totalCalories =
            healthService.calculateCaloriesFromSteps(totalSteps, user: user);
        totalFatBurned = healthService.calculateFatBurned(totalCalories);
        totalDistance =
            healthService.calculateDistanceFromSteps(totalSteps, user: user);
      }
    }

    final avgHeartRate =
        heartRateCount > 0 ? totalHeartRate / heartRateCount : 0.0;
    final waterConsumed = storageService.getWaterIntake(now);

    return DashboardStats(
      totalSteps: totalSteps,
      totalCalories: totalCalories,
      totalFatBurned: totalFatBurned,
      totalDistanceKm: totalDistance,
      averageHeartRate: avgHeartRate,
      waterConsumed: waterConsumed,
      waterGoal: user?.waterGoal ?? 2.5,
      stepGoal: user?.stepGoal ?? 10000,
      activeMinutes: totalMinutes,
      sessionsCount: todaySessions.length,
    );
  }

  @override
  Future<void> close() {
    _stepSubscription?.cancel();
    return super.close();
  }
}
