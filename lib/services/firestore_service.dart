import 'dart:async';

import '../data/models/user_model.dart';
import '../data/models/session_model.dart';
import '../data/models/city_zone_model.dart';

// NOTE: To use Firestore, you need to:
// 1. Create a Firebase project at https://console.firebase.google.com
// 2. Enable Firestore in your Firebase project
// 3. Add your app to the Firebase project
// 4. Download google-services.json (Android) / GoogleService-Info.plist (iOS)
// 5. Run: flutterfire configure
// 6. Uncomment the firestore imports below

// import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore User Service
/// Handles user data persistence in Firestore
class FirestoreUserService {
  // Mock data store for demo
  final Map<String, Map<String, dynamic>> _mockUsers = {};

  FirestoreUserService();

  /// Create or update a user profile in Firestore
  Future<void> saveUserProfile(User user) async {
    _mockUsers[user.id] = user.toJson();
  }

  /// Get a user profile by ID
  Future<User?> getUserProfile(String oderId) async {
    final data = _mockUsers[userId];
    return data != null ? User.fromJson(data) : null;
  }

  /// Update specific user fields
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    if (_mockUsers.containsKey(userId)) {
      _mockUsers[userId]!.addAll(fields);
    }
  }

  /// Delete a user profile
  Future<void> deleteUserProfile(String userId) async {
    _mockUsers.remove(userId);
  }

  /// Stream user profile changes
  Stream<User?> userProfileStream(String userId) {
    return Stream.value(
        _mockUsers[userId] != null ? User.fromJson(_mockUsers[userId]!) : null);
  }
}

/// Firestore Sessions Service
/// Handles walking/running session data persistence in Firestore
class FirestoreSessionService {
  // Mock data store for demo
  final Map<String, Map<String, dynamic>> _mockSessions = {};

  FirestoreSessionService();

  /// Save a session to Firestore
  Future<void> saveSession(String oderId, Session session) async {
    _mockSessions[session.id] = {
      ...session.toJson(),
      'oderId': oderId,
    };
  }

  /// Get a session by ID
  Future<Session?> getSession(String sessionId) async {
    final data = _mockSessions[sessionId];
    return data != null ? Session.fromJson(data) : null;
  }

  /// Get all sessions for a user
  Future<List<Session>> getUserSessions(String userId, {int? limit}) async {
    final userSessions = _mockSessions.entries
        .where((e) => e.value['userId'] == userId)
        .map((e) => Session.fromJson(e.value))
        .toList();

    if (limit != null && userSessions.length > limit) {
      return userSessions.take(limit).toList();
    }
    return userSessions;
  }

  /// Get sessions within a date range
  Future<List<Session>> getSessionsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _mockSessions.entries
        .where((e) {
          final date = DateTime.parse(e.value['date'] as String);
          return e.value['userId'] == userId &&
              date.isAfter(startDate) &&
              date.isBefore(endDate);
        })
        .map((e) => Session.fromJson(e.value))
        .toList();
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    _mockSessions.remove(sessionId);
  }

  /// Get aggregate stats for a user
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final sessions = await getUserSessions(userId);

    if (sessions.isEmpty) {
      return {
        'totalSessions': 0,
        'totalDistance': 0.0,
        'totalDuration': 0,
        'totalCalories': 0.0,
        'totalSteps': 0,
      };
    }

    int totalDuration = 0;
    double totalDistance = 0;
    double totalCalories = 0;
    int totalSteps = 0;

    for (final session in sessions) {
      totalDuration += session.durationMinutes;
      totalDistance += session.distanceKm;
      totalCalories += session.calories;
      totalSteps += session.steps;
    }

    return {
      'totalSessions': sessions.length,
      'totalDistance': totalDistance,
      'totalDuration': totalDuration,
      'totalCalories': totalCalories,
      'totalSteps': totalSteps,
      'averageDistance': totalDistance / sessions.length,
      'averageDuration': totalDuration.toDouble() / sessions.length,
    };
  }
}

/// Firestore City Builder Service
/// Handles city building progress in Firestore
class FirestoreCityService {
  // Mock data store for demo
  final Map<String, List<Map<String, dynamic>>> _mockCities = {};

  FirestoreCityService();

  /// Save city data for a user
  Future<void> saveCityData(String oderId, List<Building> buildings) async {
    _mockCities[userId] = buildings.map((b) => b.toJson()).toList();
  }

  /// Get city data for a user
  Future<List<Building>> getCityData(String userId) async {
    final data = _mockCities[userId];
    if (data == null) return [];
    return data.map((b) => Building.fromJson(b)).toList();
  }

  /// Add a single building
  Future<void> addBuilding(String userId, Building building) async {
    _mockCities.putIfAbsent(userId, () => []);
    _mockCities[userId]!.add(building.toJson());
  }

  /// Update building level
  Future<void> updateBuildingLevel(
    String userId,
    String buildingId,
    int newLevel,
  ) async {
    final buildings = _mockCities[userId];
    if (buildings != null) {
      final index = buildings.indexWhere((b) => b['id'] == buildingId);
      if (index != -1) {
        buildings[index]['level'] = newLevel;
      }
    }
  }

  /// Stream city data changes
  Stream<List<Building>> cityDataStream(String userId) {
    final data = _mockCities[userId] ?? [];
    return Stream.value(data.map((b) => Building.fromJson(b)).toList());
  }

  /// Delete all city data for a user
  Future<void> deleteCityData(String userId) async {
    _mockCities.remove(userId);
  }
}

// Variable for mock services to use
String userId = '';
