import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/session_model.dart';
import '../../../services/storage_service.dart';
import '../../../services/health_service.dart';

// Events
abstract class ProgressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressLoadRequested extends ProgressEvent {
  final ProgressFilter filter;

  ProgressLoadRequested({this.filter = ProgressFilter.today});

  @override
  List<Object?> get props => [filter];
}

class ProgressFilterChanged extends ProgressEvent {
  final ProgressFilter filter;

  ProgressFilterChanged({required this.filter});

  @override
  List<Object?> get props => [filter];
}

class ProgressSessionDeleted extends ProgressEvent {
  final String sessionId;

  ProgressSessionDeleted({required this.sessionId});

  @override
  List<Object?> get props => [sessionId];
}

enum ProgressFilter { today, week, month }

// States
abstract class ProgressState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProgressInitial extends ProgressState {}

class ProgressLoading extends ProgressState {}

class ProgressLoaded extends ProgressState {
  final List<Session> sessions;
  final ProgressFilter filter;
  final ProgressSummary summary;

  ProgressLoaded({
    required this.sessions,
    required this.filter,
    required this.summary,
  });

  ProgressLoaded copyWith({
    List<Session>? sessions,
    ProgressFilter? filter,
    ProgressSummary? summary,
  }) {
    return ProgressLoaded(
      sessions: sessions ?? this.sessions,
      filter: filter ?? this.filter,
      summary: summary ?? this.summary,
    );
  }

  @override
  List<Object?> get props => [sessions, filter, summary];
}

class ProgressError extends ProgressState {
  final String message;

  ProgressError({required this.message});

  @override
  List<Object?> get props => [message];
}

// Summary model
class ProgressSummary extends Equatable {
  final int totalSteps;
  final double totalCalories;
  final double totalDistance;
  final double totalFatBurned;
  final int totalMinutes;
  final double averageHeartRate;
  final int sessionCount;

  // Averages
  final int avgStepsPerSession;
  final double avgCaloriesPerSession;
  final double avgDistancePerSession;
  final int avgDurationPerSession;

  const ProgressSummary({
    this.totalSteps = 0,
    this.totalCalories = 0,
    this.totalDistance = 0,
    this.totalFatBurned = 0,
    this.totalMinutes = 0,
    this.averageHeartRate = 0,
    this.sessionCount = 0,
    this.avgStepsPerSession = 0,
    this.avgCaloriesPerSession = 0,
    this.avgDistancePerSession = 0,
    this.avgDurationPerSession = 0,
  });

  @override
  List<Object?> get props => [
        totalSteps,
        totalCalories,
        totalDistance,
        totalFatBurned,
        totalMinutes,
        averageHeartRate,
        sessionCount,
        avgStepsPerSession,
        avgCaloriesPerSession,
        avgDistancePerSession,
        avgDurationPerSession,
      ];
}

// BLoC
class ProgressBloc extends Bloc<ProgressEvent, ProgressState> {
  final StorageService storageService;
  final HealthService healthService;

  ProgressBloc({
    required this.storageService,
    required this.healthService,
  }) : super(ProgressInitial()) {
    on<ProgressLoadRequested>(_onLoadRequested);
    on<ProgressFilterChanged>(_onFilterChanged);
    on<ProgressSessionDeleted>(_onSessionDeleted);
  }

  Future<void> _onLoadRequested(
    ProgressLoadRequested event,
    Emitter<ProgressState> emit,
  ) async {
    emit(ProgressLoading());

    try {
      final sessions = _getFilteredSessions(event.filter);
      final summary = _calculateSummary(sessions);

      emit(ProgressLoaded(
        sessions: sessions,
        filter: event.filter,
        summary: summary,
      ));
    } catch (e) {
      emit(ProgressError(message: 'Failed to load progress: ${e.toString()}'));
    }
  }

  Future<void> _onFilterChanged(
    ProgressFilterChanged event,
    Emitter<ProgressState> emit,
  ) async {
    add(ProgressLoadRequested(filter: event.filter));
  }

  Future<void> _onSessionDeleted(
    ProgressSessionDeleted event,
    Emitter<ProgressState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ProgressLoaded) return;

    try {
      await storageService.deleteSession(event.sessionId);

      final updatedSessions =
          currentState.sessions.where((s) => s.id != event.sessionId).toList();
      final updatedSummary = _calculateSummary(updatedSessions);

      emit(currentState.copyWith(
        sessions: updatedSessions,
        summary: updatedSummary,
      ));
    } catch (e) {
      emit(ProgressError(message: 'Failed to delete session'));
    }
  }

  List<Session> _getFilteredSessions(ProgressFilter filter) {
    final now = DateTime.now();

    switch (filter) {
      case ProgressFilter.today:
        return storageService.getSessionsForDate(now);

      case ProgressFilter.week:
        final weekStart = now.subtract(Duration(days: now.weekday - 1));
        final weekEnd = weekStart.add(const Duration(days: 7));
        return storageService.getSessionsForDateRange(weekStart, weekEnd);

      case ProgressFilter.month:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 0);
        return storageService.getSessionsForDateRange(monthStart, monthEnd);
    }
  }

  ProgressSummary _calculateSummary(List<Session> sessions) {
    if (sessions.isEmpty) {
      return const ProgressSummary();
    }

    int totalSteps = 0;
    double totalCalories = 0;
    double totalDistance = 0;
    double totalFatBurned = 0;
    int totalMinutes = 0;
    double totalHeartRate = 0;
    int heartRateCount = 0;

    for (final session in sessions) {
      totalSteps += session.steps;
      totalCalories += session.calories;
      totalDistance += session.distanceKm;
      totalFatBurned += session.fatBurned;
      totalMinutes += session.durationMinutes;

      if (session.heartRateAvg != null) {
        totalHeartRate += session.heartRateAvg!;
        heartRateCount++;
      }
    }

    final sessionCount = sessions.length;
    final avgHeartRate =
        heartRateCount > 0 ? totalHeartRate / heartRateCount : 0.0;

    return ProgressSummary(
      totalSteps: totalSteps,
      totalCalories: totalCalories,
      totalDistance: totalDistance,
      totalFatBurned: totalFatBurned,
      totalMinutes: totalMinutes,
      averageHeartRate: avgHeartRate,
      sessionCount: sessionCount,
      avgStepsPerSession: (totalSteps / sessionCount).round(),
      avgCaloriesPerSession: totalCalories / sessionCount,
      avgDistancePerSession: totalDistance / sessionCount,
      avgDurationPerSession: (totalMinutes / sessionCount).round(),
    );
  }
}
