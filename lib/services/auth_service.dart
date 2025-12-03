import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/models/user_model.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService storageService;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  final _authStateController = StreamController<User?>.broadcast();
  Stream<User?> get authStateChanges => _authStateController.stream;

  User? _currentUser;
  User? get currentUser => _currentUser;

  /// Checks if Firebase is properly configured
  /// Returns error message if misconfigured, null if OK
  static Future<String?> validateFirebaseConfiguration() async {
    try {
      // Try to access Firebase Auth - this will fail if API key is invalid
      final auth = firebase_auth.FirebaseAuth.instance;
      // A simple operation to test if Firebase is configured correctly
      await auth.fetchSignInMethodsForEmail('test@validation.check');
      return null; // Configuration is valid
    } on firebase_auth.FirebaseAuthException catch (e) {
      // user-not-found or invalid-email is expected - means Firebase is working
      if (e.code == 'user-not-found' || e.code == 'invalid-email') {
        return null; // Firebase is properly configured
      }
      return 'Firebase Auth error: ${e.code}';
    } catch (e) {
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('api key') ||
          errorMessage.contains('api_key')) {
        return 'Invalid Firebase API key. Please download google-services.json from Firebase Console';
      }
      if (errorMessage.contains('not initialized')) {
        return 'Firebase not initialized. Call Firebase.initializeApp() first';
      }
      return 'Firebase configuration error: ${e.toString()}';
    }
  }

  /// Quick check if Firebase is initialized
  static bool get isFirebaseInitialized {
    try {
      firebase_auth.FirebaseAuth.instance;
      return true;
    } catch (_) {
      return false;
    }
  }

  AuthService({
    required this.storageService,
    firebase_auth.FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _googleSignIn =
            googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']),
        _firestore = firestore ?? FirebaseFirestore.instance {
    // Check for existing user on initialization
    _currentUser = storageService.getUser();
    _authStateController.add(_currentUser);

    // Listen to Firebase auth state changes
    _firebaseAuth
        .authStateChanges()
        .listen((firebase_auth.User? firebaseUser) async {
      if (firebaseUser != null) {
        await _syncUserFromFirebase(firebaseUser);
      }
    });
  }

  /// Sync user data from Firebase to local storage
  Future<void> _syncUserFromFirebase(firebase_auth.User firebaseUser) async {
    try {
      // Check if user exists in Firestore
      final docSnapshot =
          await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (docSnapshot.exists) {
        // Load existing user data
        final userData = docSnapshot.data()!;
        _currentUser = User(
          id: firebaseUser.uid,
          name: userData['name'] ?? firebaseUser.displayName ?? 'User',
          email: userData['email'] ?? firebaseUser.email ?? '',
          photoUrl: userData['photoUrl'] ?? firebaseUser.photoURL,
          height: (userData['height'] as num?)?.toDouble(),
          weight: (userData['weight'] as num?)?.toDouble(),
          gender: userData['gender'],
          age: userData['age'],
          stepGoal: userData['stepGoal'] ?? 10000,
          waterGoal: (userData['waterGoal'] as num?)?.toDouble() ?? 2.0,
          calorieGoal: userData['calorieGoal'] ?? 500,
          createdAt: userData['createdAt'] != null
              ? (userData['createdAt'] as Timestamp).toDate()
              : DateTime.now(),
          updatedAt: userData['updatedAt'] != null
              ? (userData['updatedAt'] as Timestamp).toDate()
              : null,
        );
      } else {
        // Create new user
        _currentUser = User(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          photoUrl: firebaseUser.photoURL,
          createdAt: DateTime.now(),
        );
      }

      await storageService.saveUser(_currentUser!);
      _authStateController.add(_currentUser);
    } catch (e) {
      // If Firestore fails, still create local user
      _currentUser = User(
        id: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'User',
        email: firebaseUser.email ?? '',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      await storageService.saveUser(_currentUser!);
      _authStateController.add(_currentUser);
    }
  }

  /// Create or update user document in Firestore
  Future<void> _saveUserToFirestore(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'photoUrl': user.photoUrl,
        'height': user.height,
        'weight': user.weight,
        'gender': user.gender,
        'age': user.age,
        'stepGoal': user.stepGoal,
        'waterGoal': user.waterGoal,
        'calorieGoal': user.calorieGoal,
        'createdAt': Timestamp.fromDate(user.createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      // Log error but don't throw - local storage is primary
      print('Failed to save user to Firestore: $e');
    }
  }

  // Sign in with email and password
  Future<User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        await _syncUserFromFirebase(credential.user!);
        return _currentUser!;
      }
      throw AuthException('Sign in failed - no user returned');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      // Catch any other exceptions (network, configuration, etc.)
      if (e is AuthException) rethrow;
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('api key') ||
          errorMessage.contains('api_key')) {
        throw AuthException(
            'Firebase configuration error. Please check google-services.json');
      }
      throw AuthException(
          'Sign in failed: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // Sign up with email and password
  Future<User> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user
        final user = User(
          id: credential.user!.uid,
          name: name,
          email: email,
          createdAt: DateTime.now(),
        );

        // Save to Firestore
        await _saveUserToFirestore(user);

        // Save locally
        await storageService.saveUser(user);
        _currentUser = user;
        _authStateController.add(_currentUser);

        return user;
      }
      throw AuthException('Sign up failed - no user returned');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      // Catch any other exceptions (network, configuration, etc.)
      if (e is AuthException) rethrow;
      final errorMessage = e.toString().toLowerCase();
      if (errorMessage.contains('api key') ||
          errorMessage.contains('api_key')) {
        throw AuthException(
            'Firebase configuration error. Please check google-services.json');
      }
      throw AuthException(
          'Sign up failed: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // Sign in with Google
  Future<User> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        throw AuthException('Google sign-in was cancelled');
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Validate tokens
      if (googleAuth.accessToken == null && googleAuth.idToken == null) {
        throw AuthException('Failed to get Google authentication tokens');
      }

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(credential);

      if (userCredential.user != null) {
        final firebaseUser = userCredential.user!;

        // Check if user exists in Firestore
        final docSnapshot =
            await _firestore.collection('users').doc(firebaseUser.uid).get();

        User user;
        if (!docSnapshot.exists) {
          // Create new user document in Firestore
          user = User(
            id: firebaseUser.uid,
            name: firebaseUser.displayName ?? googleUser.displayName ?? 'User',
            email: firebaseUser.email ?? googleUser.email,
            photoUrl: firebaseUser.photoURL ?? googleUser.photoUrl,
            createdAt: DateTime.now(),
          );

          // Save to Firestore
          await _saveUserToFirestore(user);
        } else {
          // Load existing user data
          final userData = docSnapshot.data()!;
          user = User(
            id: firebaseUser.uid,
            name: userData['name'] ?? firebaseUser.displayName ?? 'User',
            email: userData['email'] ?? firebaseUser.email ?? '',
            photoUrl: userData['photoUrl'] ?? firebaseUser.photoURL,
            height: (userData['height'] as num?)?.toDouble(),
            weight: (userData['weight'] as num?)?.toDouble(),
            gender: userData['gender'],
            age: userData['age'],
            stepGoal: userData['stepGoal'] ?? 10000,
            waterGoal: (userData['waterGoal'] as num?)?.toDouble() ?? 2.0,
            calorieGoal: userData['calorieGoal'] ?? 500,
            createdAt: userData['createdAt'] != null
                ? (userData['createdAt'] as Timestamp).toDate()
                : DateTime.now(),
            updatedAt: userData['updatedAt'] != null
                ? (userData['updatedAt'] as Timestamp).toDate()
                : null,
          );
        }

        // Save locally
        await storageService.saveUser(user);
        _currentUser = user;
        _authStateController.add(_currentUser);

        return user;
      }

      throw AuthException(
          'Google sign-in failed - no user returned from Firebase');
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e.code));
    } catch (e) {
      if (e is AuthException) rethrow;

      final errorMessage = e.toString().toLowerCase();

      // Provide specific error messages for common issues
      if (errorMessage.contains('api key') ||
          errorMessage.contains('api_key')) {
        throw AuthException(
            'Firebase configuration error. Please verify google-services.json');
      }
      if (errorMessage.contains('network')) {
        throw AuthException(
            'Network error. Please check your internet connection');
      }
      if (errorMessage.contains('cancelled') ||
          errorMessage.contains('canceled')) {
        throw AuthException('Google sign-in was cancelled');
      }
      if (errorMessage.contains('sha-1') ||
          errorMessage.contains('sha1') ||
          errorMessage.contains('fingerprint')) {
        throw AuthException(
            'App signature not registered. Please add SHA-1 fingerprint to Firebase Console');
      }
      if (errorMessage.contains('developer_error') ||
          errorMessage.contains('developer error')) {
        throw AuthException(
            'Google Sign-In configuration error. Please verify OAuth client ID and SHA-1 fingerprint in Firebase Console');
      }
      if (errorMessage.contains('sign_in_failed')) {
        throw AuthException(
            'Google Sign-In failed. Please check Google Cloud Console configuration');
      }

      // Generic fallback with actual error for debugging
      throw AuthException(
          'Google sign-in failed: ${e.toString().replaceAll('Exception:', '').trim()}');
    }
  }

  // Sign in with Apple
  Future<User> signInWithApple() async {
    // TODO: Implement Apple Sign In when needed
    throw AuthException('Apple Sign In not yet implemented');
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

    // Save locally first
    await storageService.saveUser(updatedUser);
    _currentUser = updatedUser;
    _authStateController.add(_currentUser);

    // Then save to Firestore (don't block on this)
    _saveUserToFirestore(updatedUser);

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
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    try {
      await _firebaseAuth.signOut();
    } catch (_) {}

    await storageService.clearUser();
    _currentUser = null;
    _authStateController.add(null);
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw AuthException(_getFirebaseAuthErrorMessage(e.code));
    }
  }

  // Check auth state
  Future<User?> checkAuthState() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      await _syncUserFromFirebase(firebaseUser);
    } else {
      _currentUser = storageService.getUser();
      _authStateController.add(_currentUser);
    }
    return _currentUser;
  }

  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      // Sign-in errors
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Invalid password';
      case 'invalid-credential':
        return 'Invalid email or password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later';

      // Sign-up errors
      case 'email-already-in-use':
        return 'Email is already registered';
      case 'weak-password':
        return 'Password is too weak (minimum 6 characters)';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Please contact support.';

      // Google/OAuth errors
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-verification-id':
        return 'Invalid verification session';
      case 'popup-closed-by-user':
        return 'Sign-in popup was closed';
      case 'cancelled-popup-request':
        return 'Sign-in was cancelled';

      // Network/configuration errors
      case 'network-request-failed':
        return 'Network error. Please check your internet connection';
      case 'internal-error':
        return 'Authentication service error. Please check Firebase configuration.';
      case 'invalid-api-key':
        return 'Invalid Firebase API key. Please check google-services.json configuration.';
      case 'app-not-authorized':
        return 'App not authorized. Please check Firebase configuration.';

      // Other errors
      case 'requires-recent-login':
        return 'Please sign in again to complete this action';
      case 'expired-action-code':
        return 'This link has expired';
      case 'invalid-action-code':
        return 'Invalid or expired link';

      default:
        // Return the error code for debugging - never show "Unknown"
        return 'Authentication failed ($code). Please try again.';
    }
  }

  // ============================================================
  // DEVELOPER TEST USER FUNCTIONALITY
  // ============================================================

  /// Private test user credentials
  static const String _testUserId = 'test_001';
  static const String _testUserEmail = 'testuser@private.dev';
  static const String _testUserName = 'DeveloperTest';

  /// Signs in as the developer test user (bypasses Firebase Auth)
  /// Only for testing when Firebase is not configured
  Future<User> signInAsTestUser() async {
    final testUser = User(
      id: _testUserId,
      name: _testUserName,
      email: _testUserEmail,
      height: 175,
      weight: 70,
      gender: 'male',
      age: 25,
      stepGoal: 10000,
      waterGoal: 2.0,
      calorieGoal: 500,
      createdAt: DateTime.now(),
    );

    // Save to local storage
    await storageService.saveUser(testUser);
    _currentUser = testUser;
    _authStateController.add(_currentUser);

    // Try to save to Firestore (may fail if not configured)
    try {
      await _saveUserToFirestore(testUser);
    } catch (_) {
      // Ignore Firestore errors for test user
    }

    return testUser;
  }

  /// Check if current user is the test user
  bool get isTestUser => _currentUser?.id == _testUserId;

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
