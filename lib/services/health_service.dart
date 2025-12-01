import 'dart:async';
import 'dart:math';

import '../data/models/session_model.dart';
import '../data/models/user_model.dart';
import '../core/constants/app_constants.dart';

class HealthService {
  final _stepsController = StreamController<int>.broadcast();
  final _heartRateController = StreamController<double>.broadcast();

  Stream<int> get stepsStream => _stepsController.stream;
  Stream<double> get heartRateStream => _heartRateController.stream;

  int _currentSteps = 0;
  int get currentSteps => _currentSteps;

  double _currentHeartRate = 0;
  double get currentHeartRate => _currentHeartRate;

  Timer? _stepSimulationTimer;
  Timer? _heartRateSimulationTimer;

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  // Start monitoring health metrics
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    _isMonitoring = true;

    // In a real app, this would connect to health APIs
    // For demo, we'll simulate step and heart rate data
    _startStepSimulation();
    _startHeartRateSimulation();
  }

  // Stop monitoring
  void stopMonitoring() {
    _isMonitoring = false;
    _stepSimulationTimer?.cancel();
    _heartRateSimulationTimer?.cancel();
  }

  // Simulate step counting
  void _startStepSimulation() {
    _stepSimulationTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      // Simulate 2-5 steps every 2 seconds while active
      final random = Random();
      final newSteps = random.nextInt(4) + 2;
      _currentSteps += newSteps;
      _stepsController.add(_currentSteps);
    });
  }

  // Simulate heart rate monitoring
  void _startHeartRateSimulation() {
    _heartRateSimulationTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) {
      // Simulate heart rate between 70-130 bpm during activity
      final random = Random();
      _currentHeartRate = 70 + random.nextInt(60).toDouble();
      _heartRateController.add(_currentHeartRate);
    });
  }

  // Reset steps for new session
  void resetSteps() {
    _currentSteps = 0;
    _stepsController.add(_currentSteps);
  }

  // Calculate calories burned from steps
  double calculateCaloriesFromSteps(int steps, {User? user}) {
    // Base calculation: ~0.04 calories per step
    // Adjusted by weight if available
    double caloriesPerStep = AppConstants.caloriesPerStep;

    if (user?.weight != null) {
      // Heavier people burn more calories per step
      caloriesPerStep = 0.035 + (user!.weight! * 0.0001);
    }

    return steps * caloriesPerStep;
  }

  // Calculate fat burned from calories
  double calculateFatBurned(double calories) {
    // ~7700 calories = 1kg of fat
    // So 1 calorie = ~0.00013 kg = 0.13g of fat
    return calories * AppConstants.fatPerCalorie * 1000; // Convert to grams
  }

  // Calculate distance from steps
  double calculateDistanceFromSteps(int steps, {User? user}) {
    // Average step length based on height
    double stepsPerKm = AppConstants.stepsPerKm;

    if (user?.height != null) {
      // Taller people have longer strides
      // Average stride = 0.415 * height
      final strideLength = 0.415 * (user!.height! / 100); // meters
      stepsPerKm = 1000 / strideLength;
    }

    return steps / stepsPerKm;
  }

  // Calculate average heart rate from a list of readings
  double calculateAverageHeartRate(List<double> readings) {
    if (readings.isEmpty) return 0;
    return readings.reduce((a, b) => a + b) / readings.length;
  }

  // Estimate steps from distance (useful when GPS tracking)
  int estimateStepsFromDistance(double distanceKm, {User? user}) {
    double stepsPerKm = AppConstants.stepsPerKm;

    if (user?.height != null) {
      final strideLength = 0.415 * (user!.height! / 100);
      stepsPerKm = 1000 / strideLength;
    }

    return (distanceKm * stepsPerKm).round();
  }

  // Calculate session statistics from raw data
  Map<String, dynamic> calculateSessionStats({
    required List<LatLng> route,
    required int durationMinutes,
    required List<double> heartRateReadings,
    User? user,
  }) {
    double distanceKm = 0;

    // Calculate distance from route
    if (route.length >= 2) {
      for (int i = 0; i < route.length - 1; i++) {
        distanceKm += _calculateHaversineDistance(
          route[i].latitude,
          route[i].longitude,
          route[i + 1].latitude,
          route[i + 1].longitude,
        );
      }
    }

    final steps = estimateStepsFromDistance(distanceKm, user: user);
    final calories = calculateCaloriesFromSteps(steps, user: user);
    final fatBurned = calculateFatBurned(calories);
    final avgHeartRate = calculateAverageHeartRate(heartRateReadings);

    return {
      'steps': steps,
      'distanceKm': distanceKm,
      'calories': calories,
      'fatBurned': fatBurned,
      'heartRateAvg': avgHeartRate,
      'heartRateMax': heartRateReadings.isNotEmpty
          ? heartRateReadings.reduce((a, b) => a > b ? a : b)
          : 0.0,
      'heartRateMin': heartRateReadings.isNotEmpty
          ? heartRateReadings.reduce((a, b) => a < b ? a : b)
          : 0.0,
    };
  }

  // Haversine formula to calculate distance between two coordinates
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  // Get daily step goal progress
  double getStepGoalProgress(int currentSteps, int stepGoal) {
    if (stepGoal <= 0) return 0;
    return (currentSteps / stepGoal).clamp(0.0, 1.0);
  }

  // Calculate BMR (Basal Metabolic Rate)
  double calculateBMR(User user) {
    if (user.weight == null || user.height == null || user.age == null) {
      return 1500; // Default BMR
    }

    // Mifflin-St Jeor Equation
    double bmr = 10 * user.weight! + 6.25 * user.height! - 5 * user.age!;

    if (user.gender?.toLowerCase() == 'male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }

    return bmr;
  }

  // Calculate TDEE (Total Daily Energy Expenditure) based on activity level
  double calculateTDEE(User user, {String activityLevel = 'moderate'}) {
    final bmr = calculateBMR(user);

    final activityMultipliers = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };

    return bmr * (activityMultipliers[activityLevel] ?? 1.55);
  }

  void dispose() {
    _stepSimulationTimer?.cancel();
    _heartRateSimulationTimer?.cancel();
    _stepsController.close();
    _heartRateController.close();
  }
}
