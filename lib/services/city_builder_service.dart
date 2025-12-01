import 'package:uuid/uuid.dart';

import '../data/models/session_model.dart';
import '../data/models/city_zone_model.dart';
import 'storage_service.dart';

class CityBuilderService {
  final StorageService storageService;

  CityBuilderService({required this.storageService});

  // Create a new city zone from a completed session
  Future<CityZone> createCityZone({
    required Session session,
    required String userId,
    String? name,
  }) async {
    // Get the center point of the route
    if (session.routeCoordinates.isEmpty) {
      throw CityBuilderException('No route coordinates available');
    }

    final center = _calculateCenter(session.routeCoordinates);

    final zone = CityZone(
      id: const Uuid().v4(),
      sessionId: session.id,
      userId: userId,
      name: name ?? 'New City ${DateTime.now().millisecondsSinceEpoch}',
      centerLat: center.latitude,
      centerLng: center.longitude,
      radiusKm: session.distanceKm / 2,
      createdAt: DateTime.now(),
      isUnlocked: session.distanceKm >= 0.5, // Unlock if walked at least 0.5km
    );

    await storageService.saveCityZone(zone);
    return zone;
  }

  // Add a building to a city zone
  Future<CityZone> addBuilding({
    required String zoneId,
    required BuildingType type,
    required double latitude,
    required double longitude,
    required int userSteps, // Current user's total steps
  }) async {
    final zone = storageService.getCityZone(zoneId);
    if (zone == null) {
      throw CityBuilderException('City zone not found');
    }

    if (!zone.isUnlocked) {
      throw CityBuilderException('This zone is locked. Walk more to unlock!');
    }

    if (!zone.canAddBuilding) {
      throw CityBuilderException('Maximum buildings reached for this zone');
    }

    // Check if user has enough steps to build
    final cost = type.cost;
    if (userSteps < cost) {
      throw CityBuilderException(
          'Not enough steps! Need $cost steps to build a ${type.displayName}');
    }

    final building = Building(
      id: const Uuid().v4(),
      type: type,
      positionLat: latitude,
      positionLng: longitude,
      createdAt: DateTime.now(),
    );

    final updatedZone = zone.copyWith(
      buildings: [...zone.buildings, building],
    );

    await storageService.saveCityZone(updatedZone);
    return updatedZone;
  }

  // Remove a building from a city zone
  Future<CityZone> removeBuilding({
    required String zoneId,
    required String buildingId,
  }) async {
    final zone = storageService.getCityZone(zoneId);
    if (zone == null) {
      throw CityBuilderException('City zone not found');
    }

    final updatedBuildings =
        zone.buildings.where((b) => b.id != buildingId).toList();

    final updatedZone = zone.copyWith(buildings: updatedBuildings);
    await storageService.saveCityZone(updatedZone);
    return updatedZone;
  }

  // Upgrade a building
  Future<CityZone> upgradeBuilding({
    required String zoneId,
    required String buildingId,
    required int userSteps,
  }) async {
    final zone = storageService.getCityZone(zoneId);
    if (zone == null) {
      throw CityBuilderException('City zone not found');
    }

    final buildingIndex = zone.buildings.indexWhere((b) => b.id == buildingId);
    if (buildingIndex == -1) {
      throw CityBuilderException('Building not found');
    }

    final building = zone.buildings[buildingIndex];
    final upgradeCost = building.type.cost * building.level;

    if (userSteps < upgradeCost) {
      throw CityBuilderException(
          'Not enough steps! Need $upgradeCost steps to upgrade');
    }

    final upgradedBuilding = building.copyWith(level: building.level + 1);
    final updatedBuildings = List<Building>.from(zone.buildings);
    updatedBuildings[buildingIndex] = upgradedBuilding;

    final updatedZone = zone.copyWith(buildings: updatedBuildings);
    await storageService.saveCityZone(updatedZone);
    return updatedZone;
  }

  // Rename a city zone
  Future<CityZone> renameCity({
    required String zoneId,
    required String newName,
  }) async {
    final zone = storageService.getCityZone(zoneId);
    if (zone == null) {
      throw CityBuilderException('City zone not found');
    }

    final updatedZone = zone.copyWith(name: newName);
    await storageService.saveCityZone(updatedZone);
    return updatedZone;
  }

  // Get all city zones for a user
  List<CityZone> getUserCityZones(String userId) {
    return storageService
        .getCityZones()
        .where((z) => z.userId == userId)
        .toList();
  }

  // Get total buildings across all zones
  int getTotalBuildings(String userId) {
    return getUserCityZones(userId)
        .fold(0, (sum, zone) => sum + zone.buildings.length);
  }

  // Get building count by type
  Map<BuildingType, int> getBuildingCounts(String userId) {
    final counts = <BuildingType, int>{};
    for (final type in BuildingType.values) {
      counts[type] = 0;
    }

    for (final zone in getUserCityZones(userId)) {
      for (final building in zone.buildings) {
        counts[building.type] = (counts[building.type] ?? 0) + 1;
      }
    }

    return counts;
  }

  // Check if a position is within a buildable zone
  bool isPositionInZone(CityZone zone, double lat, double lng) {
    final distance = _calculateDistance(
      zone.centerLat,
      zone.centerLng,
      lat,
      lng,
    );
    return distance <= zone.radiusKm;
  }

  // Get available building types based on user progress
  List<BuildingType> getAvailableBuildingTypes(int totalSteps) {
    final available = <BuildingType>[];

    // Houses always available
    available.add(BuildingType.house);

    // Unlock shops at 5000 total steps
    if (totalSteps >= 5000) {
      available.add(BuildingType.shop);
    }

    // Unlock parks at 10000 total steps
    if (totalSteps >= 10000) {
      available.add(BuildingType.park);
    }

    // Unlock factories at 25000 total steps
    if (totalSteps >= 25000) {
      available.add(BuildingType.factory);
    }

    // Unlock schools at 50000 total steps
    if (totalSteps >= 50000) {
      available.add(BuildingType.school);
    }

    return available;
  }

  // Calculate center point of coordinates
  LatLng _calculateCenter(List<LatLng> coordinates) {
    if (coordinates.isEmpty) {
      throw CityBuilderException('No coordinates provided');
    }

    double sumLat = 0;
    double sumLng = 0;

    for (final coord in coordinates) {
      sumLat += coord.latitude;
      sumLng += coord.longitude;
    }

    return LatLng(
      latitude: sumLat / coordinates.length,
      longitude: sumLng / coordinates.length,
    );
  }

  // Calculate distance between two points (in km)
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Simplified distance calculation
    // For more accuracy, use Haversine formula
    final latDiff = (lat1 - lat2).abs();
    final lngDiff = (lng1 - lng2).abs();

    // Rough approximation: 1 degree ≈ 111 km
    return ((latDiff * 111).abs() + (lngDiff * 111).abs()) / 2;
  }
}

class CityBuilderException implements Exception {
  final String message;
  CityBuilderException(this.message);

  @override
  String toString() => message;
}
