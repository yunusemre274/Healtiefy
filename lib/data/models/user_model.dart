import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? avatarUrl;
  final double? height; // in cm
  final double? weight; // in kg
  final String? gender;
  final int? age;
  final int stepGoal;
  final double waterGoal; // in liters
  final int calorieGoal;
  final int streak;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.avatarUrl,
    this.height,
    this.weight,
    this.gender,
    this.age,
    this.stepGoal = 10000,
    this.waterGoal = 2.5,
    this.calorieGoal = 2000,
    this.streak = 0,
    required this.createdAt,
    this.updatedAt,
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? avatarUrl,
    double? height,
    double? weight,
    String? gender,
    int? age,
    int? stepGoal,
    double? waterGoal,
    int? calorieGoal,
    int? streak,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      stepGoal: stepGoal ?? this.stepGoal,
      waterGoal: waterGoal ?? this.waterGoal,
      calorieGoal: calorieGoal ?? this.calorieGoal,
      streak: streak ?? this.streak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'avatarUrl': avatarUrl,
      'height': height,
      'weight': weight,
      'gender': gender,
      'age': age,
      'stepGoal': stepGoal,
      'waterGoal': waterGoal,
      'calorieGoal': calorieGoal,
      'streak': streak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      photoUrl: json['photoUrl'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      gender: json['gender'] as String?,
      age: json['age'] as int?,
      stepGoal: json['stepGoal'] as int? ?? 10000,
      waterGoal: (json['waterGoal'] as num?)?.toDouble() ?? 2.5,
      calorieGoal: json['calorieGoal'] as int? ?? 2000,
      streak: json['streak'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  // Calculate BMI if height and weight are available
  double? get bmi {
    if (height == null || weight == null || height == 0) return null;
    final heightInMeters = height! / 100;
    return weight! / (heightInMeters * heightInMeters);
  }

  // Get BMI category
  String? get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return null;
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        photoUrl,
        avatarUrl,
        height,
        weight,
        gender,
        age,
        stepGoal,
        waterGoal,
        calorieGoal,
        streak,
        createdAt,
        updatedAt,
      ];
}
