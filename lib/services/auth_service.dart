import 'dart:async';
import 'package:uuid/uuid.dart';

import '../data/models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService storageService;

  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  User? _currentUser;
  User? get currentUser => _currentUser;

  AuthService({required this.storageService}) {
    // Check for existing user on initialization
    _currentUser = storageService.getUser();
    _authStateController.add(_currentUser);
  }

  // Sign in with email and password
  Future<User> signInWithEmail(String email, String password) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // In a real app, this would validate credentials with a backend
    // For demo, we'll check if user exists locally
    final existingUser = storageService.getUser();
    if (existingUser != null && existingUser.email == email) {
      _currentUser = existingUser;
      _authStateController.add(_currentUser);
      return _currentUser!;
    }

    throw AuthException('Invalid email or password');
  }

  // Sign up with email and password
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));

    // Create new user
    final user = User(
      id: const Uuid().v4(),
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    await storageService.saveUser(user);
    _currentUser = user;
    _authStateController.add(_currentUser);

    return user;
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    // Simulate Google sign in
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, this would use google_sign_in package
    final user = User(
      id: const Uuid().v4(),
      name: 'Google User',
      email: 'user@gmail.com',
      createdAt: DateTime.now(),
    );

    await storageService.saveUser(user);
    _currentUser = user;
    _authStateController.add(_currentUser);

    return user;
  }

  // Sign in with Apple
  Future<User> signInWithApple() async {
    // Simulate Apple sign in
    await Future.delayed(const Duration(seconds: 2));

    // In a real app, this would use sign_in_with_apple package
    final user = User(
      id: const Uuid().v4(),
      name: 'Apple User',
      email: 'user@icloud.com',
      createdAt: DateTime.now(),
    );

    await storageService.saveUser(user);
    _currentUser = user;
    _authStateController.add(_currentUser);

    return user;
  }

  // Update user profile
  Future<User> updateProfile({
    String? name,
    double? height,
    double? weight,
    String? gender,
    int? age,
    int? stepGoal,
    double? waterGoal,
    int? calorieGoal,
    String? photoUrl,
  }) async {
    if (_currentUser == null) {
      throw AuthException('No user logged in');
    }

    final updatedUser = _currentUser!.copyWith(
      name: name,
      height: height,
      weight: weight,
      gender: gender,
      age: age,
      stepGoal: stepGoal,
      waterGoal: waterGoal,
      calorieGoal: calorieGoal,
      photoUrl: photoUrl,
      updatedAt: DateTime.now(),
    );

    await storageService.saveUser(updatedUser);
    _currentUser = updatedUser;
    _authStateController.add(_currentUser);

    return updatedUser;
  }

  // Check if profile is complete
  bool isProfileComplete() {
    if (_currentUser == null) return false;
    return _currentUser!.height != null &&
        _currentUser!.weight != null &&
        _currentUser!.gender != null;
  }

  // Sign out
  Future<void> signOut() async {
    await storageService.clearUser();
    _currentUser = null;
    _authStateController.add(null);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would send a password reset email
  }

  // Check auth state
  Future<User?> checkAuthState() async {
    _currentUser = storageService.getUser();
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  void dispose() {
    _authStateController.close();
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
