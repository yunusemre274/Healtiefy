import 'package:equatable/equatable.dart';

class LatLng extends Equatable {
  final double latitude;
  final double longitude;

  const LatLng({
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LatLng.fromJson(Map<String, dynamic> json) {
    return LatLng(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [latitude, longitude];
}

class Session extends Equatable {
  final String id;
  final String userId;
  final DateTime date;
  final int steps;
  final double calories; // kcal
  final double fatBurned; // grams
  final double distanceKm;
  final double? heartRateAvg;
  final double? heartRateMax;
  final double? heartRateMin;
  final int durationMinutes;
  final List<LatLng> routeCoordinates;
  final bool isCompleted;
  final DateTime? startTime;
  final DateTime? endTime;

  const Session({
    required this.id,
    required this.userId,
    required this.date,
    this.steps = 0,
    this.calories = 0,
    this.fatBurned = 0,
    this.distanceKm = 0,
    this.heartRateAvg,
    this.heartRateMax,
    this.heartRateMin,
    this.durationMinutes = 0,
    this.routeCoordinates = const [],
    this.isCompleted = false,
    this.startTime,
    this.endTime,
  });

  Session copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? steps,
    double? calories,
    double? fatBurned,
    double? distanceKm,
    double? heartRateAvg,
    double? heartRateMax,
    double? heartRateMin,
    int? durationMinutes,
    List<LatLng>? routeCoordinates,
    bool? isCompleted,
    DateTime? startTime,
    DateTime? endTime,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      steps: steps ?? this.steps,
      calories: calories ?? this.calories,
      fatBurned: fatBurned ?? this.fatBurned,
      distanceKm: distanceKm ?? this.distanceKm,
      heartRateAvg: heartRateAvg ?? this.heartRateAvg,
      heartRateMax: heartRateMax ?? this.heartRateMax,
      heartRateMin: heartRateMin ?? this.heartRateMin,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      routeCoordinates: routeCoordinates ?? this.routeCoordinates,
      isCompleted: isCompleted ?? this.isCompleted,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'date': date.toIso8601String(),
      'steps': steps,
      'calories': calories,
      'fatBurned': fatBurned,
      'distanceKm': distanceKm,
      'heartRateAvg': heartRateAvg,
      'heartRateMax': heartRateMax,
      'heartRateMin': heartRateMin,
      'durationMinutes': durationMinutes,
      'routeCoordinates': routeCoordinates.map((c) => c.toJson()).toList(),
      'isCompleted': isCompleted,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
    };
  }

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      userId: json['userId'] as String,
      date: DateTime.parse(json['date'] as String),
      steps: json['steps'] as int? ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      fatBurned: (json['fatBurned'] as num?)?.toDouble() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      heartRateAvg: (json['heartRateAvg'] as num?)?.toDouble(),
      heartRateMax: (json['heartRateMax'] as num?)?.toDouble(),
      heartRateMin: (json['heartRateMin'] as num?)?.toDouble(),
      durationMinutes: json['durationMinutes'] as int? ?? 0,
      routeCoordinates: (json['routeCoordinates'] as List?)
              ?.map((c) => LatLng.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
    );
  }

  // Helper method to format duration
  String get formattedDuration {
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  // Calculate pace (min/km)
  double? get pace {
    if (distanceKm == 0) return null;
    return durationMinutes / distanceKm;
  }

  String get formattedPace {
    final paceValue = pace;
    if (paceValue == null) return '--:--';
    final paceMinutes = paceValue.floor();
    final paceSeconds = ((paceValue - paceMinutes) * 60).round();
    return '${paceMinutes}:${paceSeconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        date,
        steps,
        calories,
        fatBurned,
        distanceKm,
        heartRateAvg,
        heartRateMax,
        heartRateMin,
        durationMinutes,
        routeCoordinates,
        isCompleted,
        startTime,
        endTime,
      ];
}
