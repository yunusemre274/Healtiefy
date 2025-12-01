import 'dart:async';
import 'dart:math';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../data/models/session_model.dart';

class LocationService {
  StreamSubscription<Position>? _positionSubscription;
  final _locationController = StreamController<Position>.broadcast();
  final _trackingController = StreamController<List<LatLng>>.broadcast();

  Stream<Position> get positionStream => _locationController.stream;
  Stream<List<LatLng>> get trackingStream => _trackingController.stream;

  List<LatLng> _currentRoute = [];
  List<LatLng> get currentRoute => List.unmodifiable(_currentRoute);

  bool _isTracking = false;
  bool get isTracking => _isTracking;

  Position? _lastPosition;
  Position? get lastPosition => _lastPosition;

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permission status
  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permission
  Future<bool> requestPermission() async {
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    // Request background location permission
    if (permission == LocationPermission.whileInUse) {
      final backgroundStatus = await Permission.locationAlways.request();
      return backgroundStatus.isGranted;
    }

    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      final serviceEnabled = await isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      final permission = await checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _lastPosition = position;
      return position;
    } catch (e) {
      return null;
    }
  }

  // Start tracking
  Future<bool> startTracking() async {
    if (_isTracking) return true;

    final permission = await requestPermission();
    if (!permission) return false;

    _currentRoute = [];
    _isTracking = true;

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // Update every 5 meters
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(
      (Position position) {
        _lastPosition = position;
        _locationController.add(position);

        final newPoint = LatLng(
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _currentRoute.add(newPoint);
        _trackingController.add(_currentRoute);
      },
      onError: (error) {
        print('Location tracking error: $error');
      },
    );

    return true;
  }

  // Pause tracking
  void pauseTracking() {
    _positionSubscription?.pause();
  }

  // Resume tracking
  void resumeTracking() {
    _positionSubscription?.resume();
  }

  // Stop tracking
  Future<List<LatLng>> stopTracking() async {
    _isTracking = false;
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    final route = List<LatLng>.from(_currentRoute);
    return route;
  }

  // Clear current route
  void clearRoute() {
    _currentRoute = [];
    _trackingController.add(_currentRoute);
  }

  // Calculate distance between two points (in km)
  double calculateDistance(LatLng start, LatLng end) {
    return Geolocator.distanceBetween(
          start.latitude,
          start.longitude,
          end.latitude,
          end.longitude,
        ) /
        1000; // Convert to km
  }

  // Calculate total route distance
  double calculateRouteDistance(List<LatLng> route) {
    if (route.length < 2) return 0;

    double totalDistance = 0;
    for (int i = 0; i < route.length - 1; i++) {
      totalDistance += calculateDistance(route[i], route[i + 1]);
    }
    return totalDistance;
  }

  // Get route center point
  LatLng? getRouteCenter(List<LatLng> route) {
    if (route.isEmpty) return null;

    double sumLat = 0;
    double sumLng = 0;

    for (final point in route) {
      sumLat += point.latitude;
      sumLng += point.longitude;
    }

    return LatLng(
      latitude: sumLat / route.length,
      longitude: sumLng / route.length,
    );
  }

  // Get route bounds (for map camera)
  Map<String, LatLng>? getRouteBounds(List<LatLng> route) {
    if (route.isEmpty) return null;

    double minLat = route.first.latitude;
    double maxLat = route.first.latitude;
    double minLng = route.first.longitude;
    double maxLng = route.first.longitude;

    for (final point in route) {
      minLat = min(minLat, point.latitude);
      maxLat = max(maxLat, point.latitude);
      minLng = min(minLng, point.longitude);
      maxLng = max(maxLng, point.longitude);
    }

    return {
      'southwest': LatLng(latitude: minLat, longitude: minLng),
      'northeast': LatLng(latitude: maxLat, longitude: maxLng),
    };
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
    _trackingController.close();
  }
}
