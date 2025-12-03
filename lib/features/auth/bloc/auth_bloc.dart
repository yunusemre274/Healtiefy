import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/user_model.dart';
import '../../../services/auth_service.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;

  AuthLoginRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;

  AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

class AuthGoogleSignInRequested extends AuthEvent {}

class AuthAppleSignInRequested extends AuthEvent {}

class AuthProfileUpdateRequested extends AuthEvent {
  final String? name;
  final double? height;
  final double? weight;
  final String? gender;
  final int? age;
  final int? stepGoal;
  final double? waterGoal;
  final int? calorieGoal;

  AuthProfileUpdateRequested({
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

class AuthLogoutRequested extends AuthEvent {}

class AuthResetPasswordRequested extends AuthEvent {
  final String email;

  AuthResetPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

/// Developer test user sign-in event (bypasses Firebase)
class AuthTestUserSignInRequested extends AuthEvent {}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final bool isProfileComplete;

  AuthAuthenticated({required this.user, required this.isProfileComplete});

  @override
  List<Object?> get props => [user, isProfileComplete];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;

  AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AuthPasswordResetSent extends AuthState {}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService authService;

  AuthBloc({required this.authService}) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheckRequested);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthGoogleSignInRequested>(_onGoogleSignInRequested);
    on<AuthAppleSignInRequested>(_onAppleSignInRequested);
    on<AuthProfileUpdateRequested>(_onProfileUpdateRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthTestUserSignInRequested>(_onTestUserSignInRequested);
  }

  Future<void> _onCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.checkAuthState();

      if (user != null) {
        emit(AuthAuthenticated(
          user: user,
          isProfileComplete: authService.isProfileComplete(),
        ));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.signInWithEmail(
        event.email,
        event.password,
      );

      emit(AuthAuthenticated(
        user: user,
        isProfileComplete: authService.isProfileComplete(),
      ));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.signUpWithEmail(
        email: event.email,
        password: event.password,
        name: event.name,
      );

      emit(AuthAuthenticated(
        user: user,
        isProfileComplete: false,
      ));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'An unexpected error occurred'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onGoogleSignInRequested(
    AuthGoogleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.signInWithGoogle();

      emit(AuthAuthenticated(
        user: user,
        isProfileComplete: authService.isProfileComplete(),
      ));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Google sign-in failed: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAppleSignInRequested(
    AuthAppleSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.signInWithApple();

      emit(AuthAuthenticated(
        user: user,
        isProfileComplete: authService.isProfileComplete(),
      ));
    } on AuthException catch (e) {
      emit(AuthError(message: e.message));
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Apple sign-in failed: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onProfileUpdateRequested(
    AuthProfileUpdateRequested event,
    Emitter<AuthState> emit,
  ) async {
    final currentState = state;
    if (currentState is! AuthAuthenticated) return;

    emit(AuthLoading());

    try {
      final user = await authService.updateProfile(
        name: event.name,
        height: event.height,
        weight: event.weight,
        gender: event.gender,
        age: event.age,
        stepGoal: event.stepGoal,
        waterGoal: event.waterGoal,
        calorieGoal: event.calorieGoal,
      );

      emit(AuthAuthenticated(
        user: user,
        isProfileComplete: authService.isProfileComplete(),
      ));
    } catch (e) {
      emit(AuthError(message: 'Failed to update profile'));
      emit(currentState);
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e) {
      emit(AuthError(message: 'Failed to sign out'));
    }
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      await authService.resetPassword(event.email);
      emit(AuthPasswordResetSent());
    } catch (e) {
      emit(AuthError(message: 'Failed to send reset email'));
    }
  }

  /// Sign in as developer test user (bypasses Firebase)
  Future<void> _onTestUserSignInRequested(
    AuthTestUserSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());

    try {
      final user = await authService.signInAsTestUser();
      emit(AuthAuthenticated(
        user: user,
        isProfileComplete: true, // Test user has complete profile
      ));
    } catch (e) {
      emit(AuthError(message: 'Test user sign-in failed: ${e.toString()}'));
      emit(AuthUnauthenticated());
    }
  }
}
