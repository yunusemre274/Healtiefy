import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/user_model.dart';
import '../data/models/session_model.dart';
import '../data/models/city_zone_model.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  late SharedPreferences _prefs;
  late Box<String> _sessionsBox;
  late Box<String> _cityZonesBox;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _sessionsBox = await Hive.openBox<String>('sessions');
    _cityZonesBox = await Hive.openBox<String>('city_zones');
  }

  // User methods
  Future<void> saveUser(User user) async {
    await _prefs.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  User? getUser() {
    final userJson = _prefs.getString(AppConstants.userKey);
    if (userJson == null) return null;
    return User.fromJson(jsonDecode(userJson));
  }

  Future<void> clearUser() async {
    await _prefs.remove(AppConstants.userKey);
  }

  // Sessions methods
  Future<void> saveSession(Session session) async {
    await _sessionsBox.put(session.id, jsonEncode(session.toJson()));
  }

  Future<void> saveSessions(List<Session> sessions) async {
    for (final session in sessions) {
      await _sessionsBox.put(session.id, jsonEncode(session.toJson()));
    }
  }

  List<Session> getSessions() {
    final sessions = <Session>[];
    for (final key in _sessionsBox.keys) {
      final sessionJson = _sessionsBox.get(key);
      if (sessionJson != null) {
        sessions.add(Session.fromJson(jsonDecode(sessionJson)));
      }
    }
    sessions.sort((a, b) => b.date.compareTo(a.date));
    return sessions;
  }

  List<Session> getSessionsForDate(DateTime date) {
    return getSessions().where((s) {
      return s.date.year == date.year &&
          s.date.month == date.month &&
          s.date.day == date.day;
    }).toList();
  }

  List<Session> getSessionsForDateRange(DateTime start, DateTime end) {
    return getSessions().where((s) {
      return s.date.isAfter(start.subtract(const Duration(days: 1))) &&
          s.date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  Session? getSession(String id) {
    final sessionJson = _sessionsBox.get(id);
    if (sessionJson == null) return null;
    return Session.fromJson(jsonDecode(sessionJson));
  }

  Future<void> deleteSession(String id) async {
    await _sessionsBox.delete(id);
  }

  // City Zones methods
  Future<void> saveCityZone(CityZone zone) async {
    await _cityZonesBox.put(zone.id, jsonEncode(zone.toJson()));
  }

  List<CityZone> getCityZones() {
    final zones = <CityZone>[];
    for (final key in _cityZonesBox.keys) {
      final zoneJson = _cityZonesBox.get(key);
      if (zoneJson != null) {
        zones.add(CityZone.fromJson(jsonDecode(zoneJson)));
      }
    }
    return zones;
  }

  CityZone? getCityZone(String id) {
    final zoneJson = _cityZonesBox.get(id);
    if (zoneJson == null) return null;
    return CityZone.fromJson(jsonDecode(zoneJson));
  }

  CityZone? getCityZoneForSession(String sessionId) {
    return getCityZones().firstWhere(
      (z) => z.sessionId == sessionId,
      orElse: () => throw Exception('Zone not found'),
    );
  }

  Future<void> deleteCityZone(String id) async {
    await _cityZonesBox.delete(id);
  }

  // Preferences methods
  Future<void> setIsFirstLaunch(bool value) async {
    await _prefs.setBool(AppConstants.isFirstLaunchKey, value);
  }

  bool isFirstLaunch() {
    return _prefs.getBool(AppConstants.isFirstLaunchKey) ?? true;
  }

  Future<void> setHasLocationPermission(bool value) async {
    await _prefs.setBool(AppConstants.hasLocationPermissionKey, value);
  }

  bool hasLocationPermission() {
    return _prefs.getBool(AppConstants.hasLocationPermissionKey) ?? false;
  }

  // Spotify token
  Future<void> saveSpotifyToken(String token) async {
    await _prefs.setString(AppConstants.spotifyTokenKey, token);
  }

  String? getSpotifyToken() {
    return _prefs.getString(AppConstants.spotifyTokenKey);
  }

  Future<void> clearSpotifyToken() async {
    await _prefs.remove(AppConstants.spotifyTokenKey);
  }

  // Water intake tracking
  Future<void> saveWaterIntake(double liters, DateTime date) async {
    final key = 'water_${date.year}_${date.month}_${date.day}';
    await _prefs.setDouble(key, liters);
  }

  double getWaterIntake(DateTime date) {
    final key = 'water_${date.year}_${date.month}_${date.day}';
    return _prefs.getDouble(key) ?? 0;
  }

  Future<void> addWaterIntake(double liters, DateTime date) async {
    final current = getWaterIntake(date);
    await saveWaterIntake(current + liters, date);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
    await _sessionsBox.clear();
    await _cityZonesBox.clear();
  }
}
