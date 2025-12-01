import 'package:equatable/equatable.dart';

enum BuildingType {
  house,
  shop,
  park,
  factory,
  school,
}

extension BuildingTypeExtension on BuildingType {
  String get displayName {
    switch (this) {
      case BuildingType.house:
        return 'House';
      case BuildingType.shop:
        return 'Shop';
      case BuildingType.park:
        return 'Park';
      case BuildingType.factory:
        return 'Factory';
      case BuildingType.school:
        return 'School';
    }
  }

  String get emoji {
    switch (this) {
      case BuildingType.house:
        return '🏠';
      case BuildingType.shop:
        return '🏪';
      case BuildingType.park:
        return '🌳';
      case BuildingType.factory:
        return '🏭';
      case BuildingType.school:
        return '🏫';
    }
  }

  int get cost {
    switch (this) {
      case BuildingType.house:
        return 100;
      case BuildingType.shop:
        return 150;
      case BuildingType.park:
        return 200;
      case BuildingType.factory:
        return 250;
      case BuildingType.school:
        return 300;
    }
  }

  String get description {
    switch (this) {
      case BuildingType.house:
        return 'A cozy home for your citizens';
      case BuildingType.shop:
        return 'A place for commerce and trade';
      case BuildingType.park:
        return 'Green space for relaxation';
      case BuildingType.factory:
        return 'Industrial building for production';
      case BuildingType.school:
        return 'Education center for learning';
    }
  }
}

class Building extends Equatable {
  final String id;
  final BuildingType type;
  final double positionLat;
  final double positionLng;
  final DateTime createdAt;
  final int level;

  const Building({
    required this.id,
    required this.type,
    required this.positionLat,
    required this.positionLng,
    required this.createdAt,
    this.level = 1,
  });

  Building copyWith({
    String? id,
    BuildingType? type,
    double? positionLat,
    double? positionLng,
    DateTime? createdAt,
    int? level,
  }) {
    return Building(
      id: id ?? this.id,
      type: type ?? this.type,
      positionLat: positionLat ?? this.positionLat,
      positionLng: positionLng ?? this.positionLng,
      createdAt: createdAt ?? this.createdAt,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'positionLat': positionLat,
      'positionLng': positionLng,
      'createdAt': createdAt.toIso8601String(),
      'level': level,
    };
  }

  factory Building.fromJson(Map<String, dynamic> json) {
    return Building(
      id: json['id'] as String,
      type: BuildingType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BuildingType.house,
      ),
      positionLat: (json['positionLat'] as num).toDouble(),
      positionLng: (json['positionLng'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      level: json['level'] as int? ?? 1,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        positionLat,
        positionLng,
        createdAt,
        level,
      ];
}

class CityZone extends Equatable {
  final String id;
  final String sessionId;
  final String userId;
  final String name;
  final List<Building> buildings;
  final double centerLat;
  final double centerLng;
  final double radiusKm;
  final DateTime createdAt;
  final bool isUnlocked;

  const CityZone({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.name = 'New City',
    this.buildings = const [],
    required this.centerLat,
    required this.centerLng,
    this.radiusKm = 0.5,
    required this.createdAt,
    this.isUnlocked = true,
  });

  CityZone copyWith({
    String? id,
    String? sessionId,
    String? userId,
    String? name,
    List<Building>? buildings,
    double? centerLat,
    double? centerLng,
    double? radiusKm,
    DateTime? createdAt,
    bool? isUnlocked,
  }) {
    return CityZone(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      buildings: buildings ?? this.buildings,
      centerLat: centerLat ?? this.centerLat,
      centerLng: centerLng ?? this.centerLng,
      radiusKm: radiusKm ?? this.radiusKm,
      createdAt: createdAt ?? this.createdAt,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sessionId': sessionId,
      'userId': userId,
      'name': name,
      'buildings': buildings.map((b) => b.toJson()).toList(),
      'centerLat': centerLat,
      'centerLng': centerLng,
      'radiusKm': radiusKm,
      'createdAt': createdAt.toIso8601String(),
      'isUnlocked': isUnlocked,
    };
  }

  factory CityZone.fromJson(Map<String, dynamic> json) {
    return CityZone(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String? ?? 'New City',
      buildings: (json['buildings'] as List?)
              ?.map((b) => Building.fromJson(b as Map<String, dynamic>))
              .toList() ??
          [],
      centerLat: (json['centerLat'] as num).toDouble(),
      centerLng: (json['centerLng'] as num).toDouble(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 0.5,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isUnlocked: json['isUnlocked'] as bool? ?? true,
    );
  }

  // Get total building count
  int get totalBuildings => buildings.length;

  // Get building count by type
  int buildingCountByType(BuildingType type) {
    return buildings.where((b) => b.type == type).length;
  }

  // Check if can add more buildings
  bool get canAddBuilding => buildings.length < 5;

  @override
  List<Object?> get props => [
        id,
        sessionId,
        userId,
        name,
        buildings,
        centerLat,
        centerLng,
        radiusKm,
        createdAt,
        isUnlocked,
      ];
}
