import 'dart:async';
import 'dart:math';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Model for a tracked location point
class TrackPoint {
  final LatLng position;
  final DateTime timestamp;
  final double? altitude;
  final double? speed;
  final double? accuracy;

  const TrackPoint({
    required this.position,
    required this.timestamp,
    this.altitude,
    this.speed,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': timestamp.toIso8601String(),
        'altitude': altitude,
        'speed': speed,
        'accuracy': accuracy,
      };

  factory TrackPoint.fromJson(Map<String, dynamic> json) => TrackPoint(
        position: LatLng(
          json['latitude'] as double,
          json['longitude'] as double,
        ),
        timestamp: DateTime.parse(json['timestamp'] as String),
        altitude: json['altitude'] as double?,
        speed: json['speed'] as double?,
        accuracy: json['accuracy'] as double?,
      );
}

/// Model for a complete tracked session
class TrackedSession {
  final String id;
  final List<TrackPoint> points;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceMeters;
  final Duration totalDuration;
  final double averageSpeedKmh;
  final double? maxSpeedKmh;
  final double? totalCalories;

  const TrackedSession({
    required this.id,
    required this.points,
    required this.startTime,
    this.endTime,
    this.totalDistanceMeters = 0,
    this.totalDuration = Duration.zero,
    this.averageSpeedKmh = 0,
    this.maxSpeedKmh,
    this.totalCalories,
  });

  TrackedSession copyWith({
    String? id,
    List<TrackPoint>? points,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistanceMeters,
    Duration? totalDuration,
    double? averageSpeedKmh,
    double? maxSpeedKmh,
    double? totalCalories,
  }) {
    return TrackedSession(
      id: id ?? this.id,
      points: points ?? this.points,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalDuration: totalDuration ?? this.totalDuration,
      averageSpeedKmh: averageSpeedKmh ?? this.averageSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      totalCalories: totalCalories ?? this.totalCalories,
    );
  }

  /// Distance in kilometers
  double get distanceKm => totalDistanceMeters / 1000;

  /// Duration formatted as HH:MM:SS
  String get formattedDuration {
    final hours = totalDuration.inHours;
    final minutes = totalDuration.inMinutes.remainder(60);
    final seconds = totalDuration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Get polyline coordinates for map
  List<LatLng> get polylineCoordinates =>
      points.map((p) => p.position).toList();

  Map<String, dynamic> toJson() => {
        'id': id,
        'points': points.map((p) => p.toJson()).toList(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime?.toIso8601String(),
        'totalDistanceMeters': totalDistanceMeters,
        'totalDurationSeconds': totalDuration.inSeconds,
        'averageSpeedKmh': averageSpeedKmh,
        'maxSpeedKmh': maxSpeedKmh,
        'totalCalories': totalCalories,
      };

  factory TrackedSession.fromJson(Map<String, dynamic> json) => TrackedSession(
        id: json['id'] as String,
        points: (json['points'] as List)
            .map((p) => TrackPoint.fromJson(p as Map<String, dynamic>))
            .toList(),
        startTime: DateTime.parse(json['startTime'] as String),
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        totalDistanceMeters: (json['totalDistanceMeters'] as num).toDouble(),
        totalDuration: Duration(seconds: json['totalDurationSeconds'] as int),
        averageSpeedKmh: (json['averageSpeedKmh'] as num).toDouble(),
        maxSpeedKmh: json['maxSpeedKmh'] != null
            ? (json['maxSpeedKmh'] as num).toDouble()
            : null,
        totalCalories: json['totalCalories'] != null
            ? (json['totalCalories'] as num).toDouble()
            : null,
      );
}

/// Tracking state for the UI
class TrackingState {
  final bool isTracking;
  final bool isPaused;
  final TrackedSession? currentSession;
  final LatLng? currentPosition;
  final double currentSpeedKmh;
  final String? error;

  const TrackingState({
    this.isTracking = false,
    this.isPaused = false,
    this.currentSession,
    this.currentPosition,
    this.currentSpeedKmh = 0,
    this.error,
  });

  TrackingState copyWith({
    bool? isTracking,
    bool? isPaused,
    TrackedSession? currentSession,
    LatLng? currentPosition,
    double? currentSpeedKmh,
    String? error,
  }) {
    return TrackingState(
      isTracking: isTracking ?? this.isTracking,
      isPaused: isPaused ?? this.isPaused,
      currentSession: currentSession ?? this.currentSession,
      currentPosition: currentPosition ?? this.currentPosition,
      currentSpeedKmh: currentSpeedKmh ?? this.currentSpeedKmh,
      error: error,
    );
  }
}

/// Service for real-time GPS tracking
class TrackingService {
  StreamSubscription<Position>? _positionSubscription;
  Timer? _durationTimer;

  final _stateController = StreamController<TrackingState>.broadcast();
  Stream<TrackingState> get stateStream => _stateController.stream;

  TrackingState _state = const TrackingState();
  TrackingState get state => _state;

  // Tracking data
  List<TrackPoint> _trackPoints = [];
  DateTime? _startTime;
  DateTime? _pauseTime;
  Duration _pausedDuration = Duration.zero;
  double _maxSpeed = 0;
  double _totalDistance = 0;
  TrackPoint? _lastPoint;

  // Configuration
  final int _distanceFilter;
  final LocationAccuracy _accuracy;
  final double _userWeightKg;

  TrackingService({
    int distanceFilter = 10, // meters
    LocationAccuracy accuracy = LocationAccuracy.high,
    double userWeightKg = 70,
  })  : _distanceFilter = distanceFilter,
        _accuracy = accuracy,
        _userWeightKg = userWeightKg;

  /// Check if location services are available
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _updateState(_state.copyWith(error: 'Location services are disabled'));
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _updateState(_state.copyWith(error: 'Location permission denied'));
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _updateState(_state.copyWith(
        error: 'Location permissions are permanently denied',
      ));
      return false;
    }

    return true;
  }

  /// Get current location once
  Future<LatLng?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _accuracy,
      );

      final latLng = LatLng(position.latitude, position.longitude);
      _updateState(_state.copyWith(currentPosition: latLng));
      return latLng;
    } catch (e) {
      _updateState(_state.copyWith(error: 'Failed to get location: $e'));
      return null;
    }
  }

  /// Start tracking a new session
  Future<bool> startTracking() async {
    if (_state.isTracking) return true;

    final hasPermission = await checkLocationPermission();
    if (!hasPermission) return false;

    // Reset state
    _trackPoints = [];
    _startTime = DateTime.now();
    _pauseTime = null;
    _pausedDuration = Duration.zero;
    _maxSpeed = 0;
    _totalDistance = 0;
    _lastPoint = null;

    // Create new session
    final session = TrackedSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: [],
      startTime: _startTime!,
    );

    _updateState(TrackingState(
      isTracking: true,
      isPaused: false,
      currentSession: session,
    ));

    // Start listening to position updates
    _startPositionStream();
    _startDurationTimer();

    return true;
  }

  /// Pause tracking
  void pauseTracking() {
    if (!_state.isTracking || _state.isPaused) return;

    _pauseTime = DateTime.now();
    _positionSubscription?.pause();
    _durationTimer?.cancel();

    _updateState(_state.copyWith(isPaused: true));
  }

  /// Resume tracking
  void resumeTracking() {
    if (!_state.isTracking || !_state.isPaused) return;

    if (_pauseTime != null) {
      _pausedDuration += DateTime.now().difference(_pauseTime!);
      _pauseTime = null;
    }

    _positionSubscription?.resume();
    _startDurationTimer();

    _updateState(_state.copyWith(isPaused: false));
  }

  /// Stop tracking and return the completed session
  Future<TrackedSession?> stopTracking() async {
    if (!_state.isTracking) return null;

    _positionSubscription?.cancel();
    _durationTimer?.cancel();

    final endTime = DateTime.now();
    final duration = _calculateDuration(endTime);
    final avgSpeed = duration.inSeconds > 0
        ? (_totalDistance / 1000) / (duration.inSeconds / 3600)
        : 0.0;
    final calories = _calculateCalories(duration, avgSpeed);

    final completedSession = TrackedSession(
      id: _state.currentSession?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      points: List.from(_trackPoints),
      startTime: _startTime ?? endTime,
      endTime: endTime,
      totalDistanceMeters: _totalDistance,
      totalDuration: duration,
      averageSpeedKmh: avgSpeed,
      maxSpeedKmh: _maxSpeed,
      totalCalories: calories,
    );

    _updateState(const TrackingState());

    return completedSession;
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();

    final locationSettings = LocationSettings(
      accuracy: _accuracy,
      distanceFilter: _distanceFilter,
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      _onPositionUpdate,
      onError: (e) {
        _updateState(_state.copyWith(error: 'Location error: $e'));
      },
    );
  }

  void _onPositionUpdate(Position position) {
    final latLng = LatLng(position.latitude, position.longitude);
    final speedKmh =
        (position.speed * 3.6).clamp(0.0, 100.0); // m/s to km/h, max 100

    final trackPoint = TrackPoint(
      position: latLng,
      timestamp: DateTime.now(),
      altitude: position.altitude,
      speed: speedKmh.toDouble(),
      accuracy: position.accuracy,
    );

    // Calculate distance from last point
    if (_lastPoint != null) {
      final distance = _calculateDistance(
        _lastPoint!.position,
        latLng,
      );
      _totalDistance += distance;
    }

    // Update max speed
    if (speedKmh > _maxSpeed) {
      _maxSpeed = speedKmh.toDouble();
    }

    _trackPoints.add(trackPoint);
    _lastPoint = trackPoint;

    // Update session
    final duration = _calculateDuration(DateTime.now());
    final avgSpeed = duration.inSeconds > 0
        ? (_totalDistance / 1000) / (duration.inSeconds / 3600)
        : 0.0;

    final updatedSession = TrackedSession(
      id: _state.currentSession?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      points: List.from(_trackPoints),
      startTime: _startTime!,
      totalDistanceMeters: _totalDistance,
      totalDuration: duration,
      averageSpeedKmh: avgSpeed,
      maxSpeedKmh: _maxSpeed,
    );

    _updateState(_state.copyWith(
      currentSession: updatedSession,
      currentPosition: latLng,
      currentSpeedKmh: speedKmh.toDouble(),
      error: null,
    ));
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_state.isTracking &&
          !_state.isPaused &&
          _state.currentSession != null) {
        final duration = _calculateDuration(DateTime.now());
        final avgSpeed = duration.inSeconds > 0
            ? (_totalDistance / 1000) / (duration.inSeconds / 3600)
            : 0.0;

        final updatedSession = _state.currentSession!.copyWith(
          totalDuration: duration,
          averageSpeedKmh: avgSpeed,
        );

        _updateState(_state.copyWith(currentSession: updatedSession));
      }
    });
  }

  Duration _calculateDuration(DateTime currentTime) {
    if (_startTime == null) return Duration.zero;
    final totalElapsed = currentTime.difference(_startTime!);
    return totalElapsed - _pausedDuration;
  }

  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000.0; // meters

    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final deltaLat = (end.latitude - start.latitude) * pi / 180;
    final deltaLon = (end.longitude - start.longitude) * pi / 180;

    final a = sin(deltaLat / 2) * sin(deltaLat / 2) +
        cos(lat1) * cos(lat2) * sin(deltaLon / 2) * sin(deltaLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  /// Calculate calories burned based on duration, speed, and weight
  double _calculateCalories(Duration duration, double avgSpeedKmh) {
    // MET values for different walking/running speeds
    double met;
    if (avgSpeedKmh < 4) {
      met = 2.0; // Slow walking
    } else if (avgSpeedKmh < 5.5) {
      met = 3.5; // Walking
    } else if (avgSpeedKmh < 7) {
      met = 4.3; // Brisk walking
    } else if (avgSpeedKmh < 9) {
      met = 8.0; // Jogging
    } else if (avgSpeedKmh < 12) {
      met = 10.0; // Running
    } else {
      met = 12.5; // Fast running
    }

    // Calories = MET × weight (kg) × time (hours)
    final hours = duration.inSeconds / 3600;
    return met * _userWeightKg * hours;
  }

  void _updateState(TrackingState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  void dispose() {
    _positionSubscription?.cancel();
    _durationTimer?.cancel();
    _stateController.close();
  }
}
