import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking daily water intake.
/// Extends ChangeNotifier for Provider integration.
/// Automatically resets at midnight (or when app detects a new day).
class WaterTrackingService extends ChangeNotifier {
  // Water intake state (in milliliters for precision)
  int _waterTodayMl = 0;
  int _waterGoalMl = 2000; // Default 2000ml = 2 liters
  String _lastResetDate = '';
  bool _isInitialized = false;

  // Keys for persistence
  static const String _keyWaterToday = 'water_today_ml';
  static const String _keyWaterGoal = 'water_goal_ml';
  static const String _keyLastResetDate = 'water_last_reset_date';

  // Getters for Provider consumers
  int get waterToday => _waterTodayMl;
  int get waterGoal => _waterGoalMl;
  double get waterTodayLiters => _waterTodayMl / 1000.0;
  double get waterGoalLiters => _waterGoalMl / 1000.0;
  double get progress =>
      _waterGoalMl > 0 ? (_waterTodayMl / _waterGoalMl).clamp(0.0, 1.0) : 0.0;
  bool get isGoalReached => _waterTodayMl >= _waterGoalMl;
  bool get isInitialized => _isInitialized;
  int get glassesConsumed => (_waterTodayMl / 250).floor(); // 250ml per glass
  int get glassesGoal => (_waterGoalMl / 250).ceil();

  /// Constructor - does not auto-initialize (call init() after construction)
  WaterTrackingService();

  /// Initialize the water tracking service
  Future<void> init() async {
    if (_isInitialized) return;

    debugPrint('[WaterTracking] Initializing water tracking service...');

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load water goal
      _waterGoalMl = prefs.getInt(_keyWaterGoal) ?? 2000;

      // Check if we need to reset for a new day
      _lastResetDate = prefs.getString(_keyLastResetDate) ?? '';
      final today = _getTodayDateString();

      if (_lastResetDate != today) {
        // New day - reset water intake
        debugPrint('[WaterTracking] New day detected, resetting water intake');
        _waterTodayMl = 0;
        await _saveData();
      } else {
        // Same day - load existing water intake
        _waterTodayMl = prefs.getInt(_keyWaterToday) ?? 0;
      }

      _isInitialized = true;
      debugPrint(
          '[WaterTracking] Initialized - today: ${_waterTodayMl}ml, goal: ${_waterGoalMl}ml');
      notifyListeners();
    } catch (e) {
      debugPrint('[WaterTracking] Error initializing: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Add water intake in milliliters
  Future<void> addWater(int ml) async {
    if (ml <= 0) return;

    // Check for day change before adding
    await _checkDayChange();

    _waterTodayMl += ml;
    debugPrint('[WaterTracking] Added ${ml}ml, total: ${_waterTodayMl}ml');

    await _saveData();
    notifyListeners();
  }

  /// Add water intake in liters (convenience method)
  Future<void> addWaterLiters(double liters) async {
    await addWater((liters * 1000).round());
  }

  /// Add one glass of water (250ml)
  Future<void> addGlass() async {
    await addWater(250);
  }

  /// Remove water intake in milliliters (for corrections)
  Future<void> removeWater(int ml) async {
    if (ml <= 0) return;

    _waterTodayMl = (_waterTodayMl - ml).clamp(0, _waterTodayMl);
    debugPrint('[WaterTracking] Removed ${ml}ml, total: ${_waterTodayMl}ml');

    await _saveData();
    notifyListeners();
  }

  /// Set daily water goal in milliliters
  Future<void> setGoal(int ml) async {
    if (ml <= 0) return;

    _waterGoalMl = ml;
    debugPrint('[WaterTracking] Goal set to ${ml}ml');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyWaterGoal, ml);
    } catch (e) {
      debugPrint('[WaterTracking] Error saving goal: $e');
    }

    notifyListeners();
  }

  /// Set daily water goal in liters (convenience method)
  Future<void> setGoalLiters(double liters) async {
    await setGoal((liters * 1000).round());
  }

  /// Reset today's water intake to zero
  Future<void> resetToday() async {
    debugPrint('[WaterTracking] Resetting today\'s water intake');

    _waterTodayMl = 0;
    await _saveData();
    notifyListeners();
  }

  /// Check if day has changed and reset if needed
  Future<void> _checkDayChange() async {
    final today = _getTodayDateString();
    if (_lastResetDate != today) {
      debugPrint('[WaterTracking] Day changed, resetting water intake');
      _waterTodayMl = 0;
      _lastResetDate = today;
    }
  }

  /// Save current data to SharedPreferences
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyWaterToday, _waterTodayMl);
      await prefs.setString(_keyLastResetDate, _getTodayDateString());
    } catch (e) {
      debugPrint('[WaterTracking] Error saving data: $e');
    }
  }

  /// Force refresh from storage (useful after app resume)
  Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = _getTodayDateString();
      final storedDate = prefs.getString(_keyLastResetDate) ?? '';

      if (storedDate != today) {
        // New day
        _waterTodayMl = 0;
        _lastResetDate = today;
        await _saveData();
      } else {
        _waterTodayMl = prefs.getInt(_keyWaterToday) ?? 0;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('[WaterTracking] Error refreshing: $e');
    }
  }
}
