import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for tracking steps using device sensors (pedometer).
/// This uses the Android TYPE_STEP_COUNTER / TYPE_STEP_DETECTOR sensors.
class StepTrackingService extends ChangeNotifier {
  // Stream subscriptions
  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // Step count state
  int _totalStepsToday = 0;
  int _stepsAtDayStart = 0;
  int _sessionStartSteps = 0;
  int _sessionSteps = 0;
  bool _isTracking = false;
  bool _isSessionActive = false;
  bool _sensorAvailable = true;
  String? _lastError;
  PedestrianStatus? _pedestrianStatus;

  // Keys for persistence
  static const String _keyStepsAtDayStart = 'steps_at_day_start';
  static const String _keyLastResetDate = 'steps_last_reset_date';

  // Stream controllers for external listeners
  final _stepStreamController = StreamController<int>.broadcast();
  final _sessionStepStreamController = StreamController<int>.broadcast();

  // Getters
  int get stepsToday => _totalStepsToday; // Primary getter for Provider
  int get totalStepsToday => _totalStepsToday;
  int get sessionSteps => _sessionSteps;
  bool get isTracking => _isTracking;
  bool get isSessionActive => _isSessionActive;
  bool get sensorAvailable => _sensorAvailable;
  String? get lastError => _lastError;
  PedestrianStatus? get pedestrianStatus => _pedestrianStatus;

  Stream<int> get stepStream => _stepStreamController.stream;
  Stream<int> get stepsStream =>
      _stepStreamController.stream; // Alias for compatibility
  Stream<int> get sessionStepStream => _sessionStepStreamController.stream;

  /// Initialize the step tracking service
  Future<void> init() async {
    print('[StepTracking] Initializing step tracking service...');

    // Check and request ACTIVITY_RECOGNITION permission (Android 10+)
    final permissionGranted = await _requestActivityPermission();
    if (!permissionGranted) {
      _lastError = 'Activity recognition permission denied';
      _sensorAvailable = false;
      print('[StepTracking] Permission denied');
      notifyListeners();
      return;
    }

    // Load persisted day start steps
    await _loadDayStartSteps();

    // Start listening to step count
    await startTracking();
  }

  /// Request ACTIVITY_RECOGNITION permission
  Future<bool> _requestActivityPermission() async {
    try {
      final status = await Permission.activityRecognition.status;
      print('[StepTracking] Current permission status: $status');

      if (status.isGranted) {
        return true;
      }

      if (status.isDenied) {
        final result = await Permission.activityRecognition.request();
        print('[StepTracking] Permission request result: $result');
        return result.isGranted;
      }

      if (status.isPermanentlyDenied) {
        _lastError =
            'Activity recognition permission permanently denied. Please enable in settings.';
        return false;
      }

      return false;
    } catch (e) {
      print('[StepTracking] Permission error: $e');
      _lastError = 'Failed to request permission: $e';
      return false;
    }
  }

  /// Load day start steps from SharedPreferences
  Future<void> _loadDayStartSteps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastResetDate = prefs.getString(_keyLastResetDate);
      final today = _getTodayDateString();

      if (lastResetDate != today) {
        // New day - will reset when we get the first step count
        print('[StepTracking] New day detected, will reset step count');
        _stepsAtDayStart = 0;
      } else {
        _stepsAtDayStart = prefs.getInt(_keyStepsAtDayStart) ?? 0;
        print('[StepTracking] Loaded day start steps: $_stepsAtDayStart');
      }
    } catch (e) {
      print('[StepTracking] Error loading day start steps: $e');
    }
  }

  /// Save day start steps to SharedPreferences
  Future<void> _saveDayStartSteps(int steps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyStepsAtDayStart, steps);
      await prefs.setString(_keyLastResetDate, _getTodayDateString());
      print('[StepTracking] Saved day start steps: $steps');
    } catch (e) {
      print('[StepTracking] Error saving day start steps: $e');
    }
  }

  String _getTodayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Start tracking steps from the sensor
  Future<void> startTracking() async {
    if (_isTracking) {
      print('[StepTracking] Already tracking');
      return;
    }

    print('[StepTracking] Starting step tracking...');

    try {
      // Listen to step count stream
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Listen to pedestrian status (walking/stopped)
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isTracking = true;
      _sensorAvailable = true;
      _lastError = null;
      notifyListeners();
      print('[StepTracking] Step tracking started successfully');
    } catch (e) {
      print('[StepTracking] Error starting tracking: $e');
      _lastError = 'Failed to start step tracking: $e';
      _sensorAvailable = false;
      notifyListeners();
    }
  }

  /// Stop tracking steps
  void stopTracking() {
    print('[StepTracking] Stopping step tracking...');
    _stepCountSubscription?.cancel();
    _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    _isTracking = false;
    notifyListeners();
  }

  /// Handle step count updates from sensor
  void _onStepCount(StepCount event) {
    final sensorSteps = event.steps;
    print('[StepTracking] Sensor step count: $sensorSteps');

    // Check if we need to reset for a new day
    final prefs = SharedPreferences.getInstance();
    prefs.then((p) async {
      final lastResetDate = p.getString(_keyLastResetDate);
      final today = _getTodayDateString();

      if (lastResetDate != today || _stepsAtDayStart == 0) {
        // New day - set baseline
        _stepsAtDayStart = sensorSteps;
        await _saveDayStartSteps(sensorSteps);
      }

      // Calculate today's steps
      _totalStepsToday = sensorSteps - _stepsAtDayStart;
      if (_totalStepsToday < 0) {
        // Device was rebooted, sensor reset
        _stepsAtDayStart = sensorSteps;
        _totalStepsToday = 0;
        await _saveDayStartSteps(sensorSteps);
      }

      print('[StepTracking] Today\'s steps: $_totalStepsToday');
      _stepStreamController.add(_totalStepsToday);

      // Update session steps if session is active
      if (_isSessionActive) {
        _sessionSteps = sensorSteps - _sessionStartSteps;
        if (_sessionSteps < 0) _sessionSteps = 0;
        print('[StepTracking] Session steps: $_sessionSteps');
        _sessionStepStreamController.add(_sessionSteps);
      }

      notifyListeners();
    });
  }

  /// Handle step count errors
  void _onStepCountError(dynamic error) {
    print('[StepTracking] Step count error: $error');
    _lastError = 'Step sensor error: $error';
    _sensorAvailable = false;
    notifyListeners();
  }

  /// Handle pedestrian status changes
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    print('[StepTracking] Pedestrian status: ${event.status}');
    _pedestrianStatus = event;
    notifyListeners();
  }

  /// Handle pedestrian status errors
  void _onPedestrianStatusError(dynamic error) {
    print('[StepTracking] Pedestrian status error: $error');
    // This is not critical, don't mark sensor as unavailable
  }

  /// Start a walking session
  Future<void> startSession() async {
    if (_isSessionActive) {
      print('[StepTracking] Session already active');
      return;
    }

    print('[StepTracking] Starting walk session...');

    // Ensure tracking is active
    if (!_isTracking) {
      await startTracking();
    }

    // Get current step count as session baseline
    // We'll get the actual value from the next sensor event
    _sessionStartSteps = _stepsAtDayStart + _totalStepsToday;
    _sessionSteps = 0;
    _isSessionActive = true;
    notifyListeners();

    print('[StepTracking] Session started at step count: $_sessionStartSteps');
  }

  /// End a walking session and return session statistics
  SessionStepData endSession() {
    if (!_isSessionActive) {
      print('[StepTracking] No active session to end');
      return SessionStepData(steps: 0, startSteps: 0, endSteps: 0);
    }

    print('[StepTracking] Ending walk session...');

    final endSteps = _stepsAtDayStart + _totalStepsToday;
    final sessionData = SessionStepData(
      steps: _sessionSteps,
      startSteps: _sessionStartSteps,
      endSteps: endSteps,
    );

    _isSessionActive = false;
    _sessionSteps = 0;
    _sessionStartSteps = 0;
    notifyListeners();

    print('[StepTracking] Session ended. Steps: ${sessionData.steps}');
    return sessionData;
  }

  /// Reset today's step count (for testing or manual reset)
  Future<void> resetTodaySteps() async {
    print('[StepTracking] Resetting today\'s steps...');

    // Get current sensor count and set as new baseline
    // This will take effect on the next sensor update
    _stepsAtDayStart = _stepsAtDayStart + _totalStepsToday;
    _totalStepsToday = 0;
    await _saveDayStartSteps(_stepsAtDayStart);

    _stepStreamController.add(0);
    notifyListeners();
  }

  /// Check if step sensor is available on this device
  Future<bool> checkSensorAvailability() async {
    // The pedometer package doesn't have a direct availability check,
    // but we can try to get a stream and see if it errors
    try {
      final completer = Completer<bool>();
      StreamSubscription<StepCount>? testSub;

      testSub = Pedometer.stepCountStream.listen(
        (event) {
          testSub?.cancel();
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onError: (error) {
          testSub?.cancel();
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      );

      // Give it 3 seconds to respond
      return await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          testSub?.cancel();
          return false;
        },
      );
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    stopTracking();
    _stepStreamController.close();
    _sessionStepStreamController.close();
    super.dispose();
  }
}

/// Data class for session step statistics
class SessionStepData {
  final int steps;
  final int startSteps;
  final int endSteps;

  SessionStepData({
    required this.steps,
    required this.startSteps,
    required this.endSteps,
  });

  @override
  String toString() =>
      'SessionStepData(steps: $steps, start: $startSteps, end: $endSteps)';
}
