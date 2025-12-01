import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalSteps;
  final double totalCalories;
  final double totalFatBurned;
  final double totalDistanceKm;
  final double averageHeartRate;
  final double waterConsumed;
  final double waterGoal;
  final int stepGoal;
  final int activeMinutes;
  final int sessionsCount;

  const DashboardStats({
    this.totalSteps = 0,
    this.totalCalories = 0,
    this.totalFatBurned = 0,
    this.totalDistanceKm = 0,
    this.averageHeartRate = 0,
    this.waterConsumed = 0,
    this.waterGoal = 2.5,
    this.stepGoal = 10000,
    this.activeMinutes = 0,
    this.sessionsCount = 0,
  });

  DashboardStats copyWith({
    int? totalSteps,
    double? totalCalories,
    double? totalFatBurned,
    double? totalDistanceKm,
    double? averageHeartRate,
    double? waterConsumed,
    double? waterGoal,
    int? stepGoal,
    int? activeMinutes,
    int? sessionsCount,
  }) {
    return DashboardStats(
      totalSteps: totalSteps ?? this.totalSteps,
      totalCalories: totalCalories ?? this.totalCalories,
      totalFatBurned: totalFatBurned ?? this.totalFatBurned,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      averageHeartRate: averageHeartRate ?? this.averageHeartRate,
      waterConsumed: waterConsumed ?? this.waterConsumed,
      waterGoal: waterGoal ?? this.waterGoal,
      stepGoal: stepGoal ?? this.stepGoal,
      activeMinutes: activeMinutes ?? this.activeMinutes,
      sessionsCount: sessionsCount ?? this.sessionsCount,
    );
  }

  // Progress percentages
  double get stepProgress =>
      stepGoal > 0 ? (totalSteps / stepGoal).clamp(0.0, 1.0) : 0;
  double get waterProgress =>
      waterGoal > 0 ? (waterConsumed / waterGoal).clamp(0.0, 1.0) : 0;

  @override
  List<Object?> get props => [
        totalSteps,
        totalCalories,
        totalFatBurned,
        totalDistanceKm,
        averageHeartRate,
        waterConsumed,
        waterGoal,
        stepGoal,
        activeMinutes,
        sessionsCount,
      ];
}

class AITip extends Equatable {
  final String id;
  final String title;
  final String message;
  final String category; // motivation, health, challenge, insight
  final DateTime createdAt;
  final bool isRead;

  const AITip({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    this.isRead = false,
  });

  AITip copyWith({
    String? id,
    String? title,
    String? message,
    String? category,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return AITip(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  factory AITip.fromJson(Map<String, dynamic> json) {
    return AITip(
      id: json['id'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  String get emoji {
    switch (category) {
      case 'motivation':
        return '💪';
      case 'health':
        return '❤️';
      case 'challenge':
        return '🏆';
      case 'insight':
        return '💡';
      default:
        return '✨';
    }
  }

  @override
  List<Object?> get props => [id, title, message, category, createdAt, isRead];
}

class Challenge extends Equatable {
  final String id;
  final String title;
  final String description;
  final int targetValue;
  final int currentValue;
  final String unit; // steps, km, calories, etc.
  final String reward;
  final DateTime startDate;
  final DateTime endDate;
  final bool isCompleted;

  const Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.targetValue,
    this.currentValue = 0,
    required this.unit,
    required this.reward,
    required this.startDate,
    required this.endDate,
    this.isCompleted = false,
  });

  Challenge copyWith({
    String? id,
    String? title,
    String? description,
    int? targetValue,
    int? currentValue,
    String? unit,
    String? reward,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCompleted,
  }) {
    return Challenge(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      reward: reward ?? this.reward,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  double get progress =>
      targetValue > 0 ? (currentValue / targetValue).clamp(0.0, 1.0) : 0;

  bool get isExpired => DateTime.now().isAfter(endDate);

  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'reward': reward,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      targetValue: json['targetValue'] as int,
      currentValue: json['currentValue'] as int? ?? 0,
      unit: json['unit'] as String,
      reward: json['reward'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        targetValue,
        currentValue,
        unit,
        reward,
        startDate,
        endDate,
        isCompleted,
      ];
}
