import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/storage_service.dart';

// Events
abstract class AccountEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AccountLoadRequested extends AccountEvent {}

class AccountUpdateRequested extends AccountEvent {
  final String? name;
  final double? height;
  final double? weight;
  final String? gender;
  final int? age;
  final int? stepGoal;
  final double? waterGoal;
  final int? calorieGoal;

  AccountUpdateRequested({
    this.name,
    this.height,
    this.weight,
    this.gender,
    this.age,
    this.stepGoal,
    this.waterGoal,
    this.calorieGoal,
  });

  @override
  List<Object?> get props => [
        name,
        height,
        weight,
        gender,
        age,
        stepGoal,
        waterGoal,
        calorieGoal,
      ];
}

class AccountLogoutRequested extends AccountEvent {}

// States
abstract class AccountState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountLoaded extends AccountState {
  final User user;
  final AccountStats stats;
  final List<Achievement> achievements;

  AccountLoaded({
    required this.user,
    required this.stats,
    this.achievements = const [],
  });

  AccountLoaded copyWith({
    User? user,
    AccountStats? stats,
    List<Achievement>? achievements,
  }) {
    return AccountLoaded(
      user: user ?? this.user,
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
    );
  }

  @override
  List<Object?> get props => [user, stats, achievements];
}

class AccountError extends AccountState {
  final String message;

  AccountError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AccountLoggedOut extends AccountState {}

// Stats model
class AccountStats extends Equatable {
  final int totalSessions;
  final int totalSteps;
  final double totalDistance;
  final double totalCalories;
  final int totalBuildings;
  final int totalCities;
  final int currentStreak;
  final int longestStreak;

  const AccountStats({
    this.totalSessions = 0,
    this.totalSteps = 0,
    this.totalDistance = 0,
    this.totalCalories = 0,
    this.totalBuildings = 0,
    this.totalCities = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  @override
  List<Object?> get props => [
        totalSessions,
        totalSteps,
        totalDistance,
        totalCalories,
        totalBuildings,
        totalCities,
        currentStreak,
        longestStreak,
      ];
}

// BLoC
class AccountBloc extends Bloc<AccountEvent, AccountState> {
  final AuthService authService;
  final StorageService storageService;

  AccountBloc({
    required this.authService,
    required this.storageService,
  }) : super(AccountInitial()) {
    on<AccountLoadRequested>(_onLoadRequested);
    on<AccountUpdateRequested>(_onUpdateRequested);
    on<AccountLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLoadRequested(
    AccountLoadRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());

    try {
      final user = authService.currentUser;
      if (user == null) {
        emit(AccountError(message: 'User not found'));
        return;
      }

      final stats = _calculateStats(user.id);
      final achievements = _generateAchievements(stats);

      emit(AccountLoaded(
        user: user,
        stats: stats,
        achievements: achievements,
      ));
    } catch (e) {
      emit(AccountError(message: 'Failed to load account: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRequested(
    AccountUpdateRequested event,
    Emitter<AccountState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AccountLoaded) return;

    emit(AccountLoading());

    try {
      final updatedUser = await authService.updateProfile(
        name: event.name,
        height: event.height,
        weight: event.weight,
        gender: event.gender,
        age: event.age,
        stepGoal: event.stepGoal,
        waterGoal: event.waterGoal,
        calorieGoal: event.calorieGoal,
      );

      emit(currentState.copyWith(user: updatedUser));
    } catch (e) {
      emit(AccountError(message: 'Failed to update profile'));
      emit(currentState);
    }
  }

  Future<void> _onLogoutRequested(
    AccountLogoutRequested event,
    Emitter<AccountState> emit,
  ) async {
    emit(AccountLoading());

    try {
      await authService.signOut();
      emit(AccountLoggedOut());
    } catch (e) {
      emit(AccountError(message: 'Failed to sign out'));
    }
  }

  AccountStats _calculateStats(String userId) {
    final sessions = storageService.getSessions();
    final cityZones =
        storageService.getCityZones().where((z) => z.userId == userId).toList();

    int totalSteps = 0;
    double totalDistance = 0;
    double totalCalories = 0;
    int totalBuildings = 0;

    for (final session in sessions) {
      totalSteps += session.steps;
      totalDistance += session.distanceKm;
      totalCalories += session.calories;
    }

    for (final zone in cityZones) {
      totalBuildings += zone.buildings.length;
    }

    // Calculate streaks
    final streak = _calculateStreak(sessions);

    return AccountStats(
      totalSessions: sessions.length,
      totalSteps: totalSteps,
      totalDistance: totalDistance,
      totalCalories: totalCalories,
      totalBuildings: totalBuildings,
      totalCities: cityZones.length,
      currentStreak: streak['current'] ?? 0,
      longestStreak: streak['longest'] ?? 0,
    );
  }

  Map<String, int> _calculateStreak(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Sort sessions by date
    final sortedSessions = List.from(sessions)
      ..sort((a, b) => b.date.compareTo(a.date));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    DateTime? previousDate;

    for (final session in sortedSessions) {
      if (previousDate == null) {
        previousDate = session.date;
        tempStreak = 1;
        continue;
      }

      final daysDifference = previousDate.difference(session.date).inDays;

      if (daysDifference == 1) {
        tempStreak++;
      } else if (daysDifference > 1) {
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
        tempStreak = 1;
      }

      previousDate = session.date;
    }

    if (tempStreak > longestStreak) {
      longestStreak = tempStreak;
    }

    // Check if current streak is still active
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastSessionDate = sortedSessions.first.date;
    final lastDate = DateTime(
      lastSessionDate.year,
      lastSessionDate.month,
      lastSessionDate.day,
    );

    if (today.difference(lastDate).inDays <= 1) {
      currentStreak = tempStreak;
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  List<Achievement> _generateAchievements(AccountStats stats) {
    return [
      Achievement(
        id: '1',
        name: '10K Steps',
        description: 'Walk 10,000 steps in a day',
        isUnlocked: stats.totalSteps >= 10000,
      ),
      Achievement(
        id: '2',
        name: 'Marathon',
        description: 'Walk a total of 42 km',
        isUnlocked: stats.totalDistance >= 42,
      ),
      Achievement(
        id: '3',
        name: 'City Builder',
        description: 'Build 10 buildings',
        isUnlocked: stats.totalBuildings >= 10,
      ),
      Achievement(
        id: '4',
        name: 'Streak Master',
        description: 'Achieve a 7 day streak',
        isUnlocked: stats.longestStreak >= 7,
      ),
      Achievement(
        id: '5',
        name: 'Calorie Crusher',
        description: 'Burn 1,000 calories',
        isUnlocked: stats.totalCalories >= 1000,
      ),
      Achievement(
        id: '6',
        name: 'Session Pro',
        description: 'Complete 20 sessions',
        isUnlocked: stats.totalSessions >= 20,
      ),
    ];
  }
}

// Achievement model
class Achievement extends Equatable {
  final String id;
  final String name;
  final String description;
  final bool isUnlocked;

  const Achievement({
    required this.id,
    required this.name,
    this.description = '',
    this.isUnlocked = false,
  });

  @override
  List<Object?> get props => [id, name, description, isUnlocked];
}
