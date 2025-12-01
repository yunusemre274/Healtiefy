import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/user_model.dart';
import '../data/models/session_model.dart';
import '../data/models/city_zone_model.dart';
import '../core/constants/app_constants.dart';

/// Base class for local cache services
abstract class LocalCacheService<T> {
  Future<void> save(String key, T data);
  Future<T?> get(String key);
  Future<void> delete(String key);
  Future<void> clear();
  Future<List<T>> getAll();
}

/// User local cache using Hive
class UserLocalCache implements LocalCacheService<User> {
  static const String _boxName = 'user_cache';
  Box? _box;

  Future<void> init() async {
    if (_box?.isOpen ?? false) return;
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<void> save(String key, User data) async {
    await init();
    await _box?.put(key, jsonEncode(data.toJson()));
  }

  @override
  Future<User?> get(String key) async {
    await init();
    final data = _box?.get(key);
    if (data == null) return null;
    return User.fromJson(jsonDecode(data as String));
  }

  @override
  Future<void> delete(String key) async {
    await init();
    await _box?.delete(key);
  }

  @override
  Future<void> clear() async {
    await init();
    await _box?.clear();
  }

  @override
  Future<List<User>> getAll() async {
    await init();
    final List<User> users = [];
    for (final key in _box?.keys ?? []) {
      final user = await get(key.toString());
      if (user != null) users.add(user);
    }
    return users;
  }

  /// Get the current user from cache
  Future<User?> getCurrentUser() async {
    return get(AppConstants.currentUserKey);
  }

  /// Save the current user to cache
  Future<void> saveCurrentUser(User user) async {
    await save(AppConstants.currentUserKey, user);
  }

  /// Clear the current user from cache
  Future<void> clearCurrentUser() async {
    await delete(AppConstants.currentUserKey);
  }
}

/// Session local cache using Hive
class SessionLocalCache implements LocalCacheService<Session> {
  static const String _boxName = 'session_cache';
  Box? _box;

  Future<void> init() async {
    if (_box?.isOpen ?? false) return;
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<void> save(String key, Session data) async {
    await init();
    await _box?.put(key, jsonEncode(data.toJson()));
  }

  @override
  Future<Session?> get(String key) async {
    await init();
    final data = _box?.get(key);
    if (data == null) return null;
    return Session.fromJson(jsonDecode(data as String));
  }

  @override
  Future<void> delete(String key) async {
    await init();
    await _box?.delete(key);
  }

  @override
  Future<void> clear() async {
    await init();
    await _box?.clear();
  }

  @override
  Future<List<Session>> getAll() async {
    await init();
    final List<Session> sessions = [];
    for (final key in _box?.keys ?? []) {
      final session = await get(key.toString());
      if (session != null) sessions.add(session);
    }
    return sessions;
  }

  /// Get sessions for a specific user
  Future<List<Session>> getSessionsForUser(String userId) async {
    final allSessions = await getAll();
    return allSessions.where((s) => s.userId == userId).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }

  /// Get sessions within a date range
  Future<List<Session>> getSessionsInRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final userSessions = await getSessionsForUser(userId);
    return userSessions.where((s) {
      return s.date.isAfter(startDate) && s.date.isBefore(endDate);
    }).toList();
  }

  /// Get today's sessions
  Future<List<Session>> getTodaySessions(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return getSessionsInRange(userId, startOfDay, endOfDay);
  }

  /// Get this week's sessions
  Future<List<Session>> getThisWeekSessions(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfDay =
        DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final endOfWeek = startOfDay.add(const Duration(days: 7));
    return getSessionsInRange(userId, startOfDay, endOfWeek);
  }

  /// Calculate aggregate stats
  Future<Map<String, dynamic>> getStats(String userId) async {
    final sessions = await getSessionsForUser(userId);

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

/// City/Building local cache using Hive
class CityLocalCache implements LocalCacheService<Building> {
  static const String _boxName = 'city_cache';
  Box? _box;

  Future<void> init() async {
    if (_box?.isOpen ?? false) return;
    _box = await Hive.openBox(_boxName);
  }

  @override
  Future<void> save(String key, Building data) async {
    await init();
    await _box?.put(key, jsonEncode(data.toJson()));
  }

  @override
  Future<Building?> get(String key) async {
    await init();
    final data = _box?.get(key);
    if (data == null) return null;
    return Building.fromJson(jsonDecode(data as String));
  }

  @override
  Future<void> delete(String key) async {
    await init();
    await _box?.delete(key);
  }

  @override
  Future<void> clear() async {
    await init();
    await _box?.clear();
  }

  @override
  Future<List<Building>> getAll() async {
    await init();
    final List<Building> buildings = [];
    for (final key in _box?.keys ?? []) {
      final building = await get(key.toString());
      if (building != null) buildings.add(building);
    }
    return buildings;
  }

  /// Get all buildings for a user's city
  Future<List<Building>> getCityBuildings(String userId) async {
    await init();
    final List<Building> buildings = [];
    final prefix = '${userId}_';

    for (final key in _box?.keys ?? []) {
      if (key.toString().startsWith(prefix)) {
        final building = await get(key.toString());
        if (building != null) buildings.add(building);
      }
    }
    return buildings;
  }

  /// Save all buildings for a user's city
  Future<void> saveCityBuildings(
      String userId, List<Building> buildings) async {
    // Clear existing buildings for this user
    final existing = await getCityBuildings(userId);
    for (final building in existing) {
      await delete('${userId}_${building.id}');
    }

    // Save new buildings
    for (final building in buildings) {
      await save('${userId}_${building.id}', building);
    }
  }

  /// Update a building's level
  Future<void> updateBuildingLevel(
      String userId, String buildingId, int newLevel) async {
    final building = await get('${userId}_$buildingId');
    if (building != null) {
      final updated = building.copyWith(level: newLevel);
      await save('${userId}_$buildingId', updated);
    }
  }
}

/// Settings cache using SharedPreferences
class SettingsCache {
  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setBool(String key, bool value) async {
    await init();
    await _prefs?.setBool(key, value);
  }

  Future<bool?> getBool(String key) async {
    await init();
    return _prefs?.getBool(key);
  }

  Future<void> setString(String key, String value) async {
    await init();
    await _prefs?.setString(key, value);
  }

  Future<String?> getString(String key) async {
    await init();
    return _prefs?.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    await init();
    await _prefs?.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    await init();
    return _prefs?.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    await init();
    await _prefs?.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    await init();
    return _prefs?.getDouble(key);
  }

  Future<void> remove(String key) async {
    await init();
    await _prefs?.remove(key);
  }

  Future<void> clear() async {
    await init();
    await _prefs?.clear();
  }

  // Convenience methods for app settings
  Future<bool> isDarkMode() async {
    return await getBool('dark_mode') ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    await setBool('dark_mode', value);
  }

  Future<bool> isNotificationsEnabled() async {
    return await getBool('notifications_enabled') ?? true;
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await setBool('notifications_enabled', value);
  }

  Future<String> getLanguage() async {
    return await getString('language') ?? 'en';
  }

  Future<void> setLanguage(String languageCode) async {
    await setString('language', languageCode);
  }

  Future<String> getDistanceUnit() async {
    return await getString('distance_unit') ?? 'km';
  }

  Future<void> setDistanceUnit(String unit) async {
    await setString('distance_unit', unit);
  }

  Future<bool> isFirstLaunch() async {
    return await getBool('first_launch') ?? true;
  }

  Future<void> setFirstLaunchComplete() async {
    await setBool('first_launch', false);
  }

  Future<int> getCurrentStreak() async {
    return await getInt(AppConstants.currentStreakKey) ?? 0;
  }

  Future<void> setCurrentStreak(int streak) async {
    await setInt(AppConstants.currentStreakKey, streak);
  }

  Future<String?> getLastActivityDate() async {
    return getString(AppConstants.lastActivityDateKey);
  }

  Future<void> setLastActivityDate(DateTime date) async {
    await setString(AppConstants.lastActivityDateKey, date.toIso8601String());
  }
}

/// Central cache manager that coordinates all cache services
class CacheManager {
  final UserLocalCache userCache = UserLocalCache();
  final SessionLocalCache sessionCache = SessionLocalCache();
  final CityLocalCache cityCache = CityLocalCache();
  final SettingsCache settingsCache = SettingsCache();

  static final CacheManager _instance = CacheManager._internal();
  factory CacheManager() => _instance;
  CacheManager._internal();

  /// Initialize all cache services
  Future<void> init() async {
    await Future.wait([
      userCache.init(),
      sessionCache.init(),
      cityCache.init(),
      settingsCache.init(),
    ]);
  }

  /// Clear all caches (useful for logout)
  Future<void> clearAll() async {
    await Future.wait([
      userCache.clear(),
      sessionCache.clear(),
      cityCache.clear(),
      // Don't clear settings - user preferences should persist
    ]);
  }

  /// Clear user-specific data while preserving app settings
  Future<void> clearUserData() async {
    await userCache.clearCurrentUser();
    await sessionCache.clear();
    await cityCache.clear();
  }
}
