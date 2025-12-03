import 'package:equatable/equatable.dart';

/// Crop types available in the farm
enum CropType {
  wheat,
  corn,
  carrot,
  tomato,
  potato,
  strawberry,
  pumpkin,
  sunflower,
}

/// Crop growth stages
enum GrowthStage {
  seed,
  sprout,
  growing,
  mature,
  harvestable,
  withered,
}

/// Animal types available in the farm
enum AnimalType {
  chicken,
  cow,
  pig,
  sheep,
}

/// Animal states
enum AnimalState {
  hungry,
  eating,
  producing,
  ready, // Ready to collect product
  sleeping,
}

/// Farm building types
enum FarmBuildingType {
  barn,
  silo,
  coop,
  stable,
  mill,
  bakery,
  well,
}

/// Tile types for the farm grid
enum TileType {
  grass,
  dirt,
  plowed,
  planted,
  water,
  path,
  building,
}

/// Extension for crop properties
extension CropTypeExtension on CropType {
  String get name {
    switch (this) {
      case CropType.wheat:
        return 'Wheat';
      case CropType.corn:
        return 'Corn';
      case CropType.carrot:
        return 'Carrot';
      case CropType.tomato:
        return 'Tomato';
      case CropType.potato:
        return 'Potato';
      case CropType.strawberry:
        return 'Strawberry';
      case CropType.pumpkin:
        return 'Pumpkin';
      case CropType.sunflower:
        return 'Sunflower';
    }
  }

  int get growthTimeMinutes {
    switch (this) {
      case CropType.wheat:
        return 2;
      case CropType.corn:
        return 5;
      case CropType.carrot:
        return 3;
      case CropType.tomato:
        return 8;
      case CropType.potato:
        return 10;
      case CropType.strawberry:
        return 15;
      case CropType.pumpkin:
        return 20;
      case CropType.sunflower:
        return 12;
    }
  }

  int get seedCost {
    switch (this) {
      case CropType.wheat:
        return 50;
      case CropType.corn:
        return 100;
      case CropType.carrot:
        return 80;
      case CropType.tomato:
        return 150;
      case CropType.potato:
        return 120;
      case CropType.strawberry:
        return 200;
      case CropType.pumpkin:
        return 300;
      case CropType.sunflower:
        return 180;
    }
  }

  int get harvestValue {
    switch (this) {
      case CropType.wheat:
        return 100;
      case CropType.corn:
        return 200;
      case CropType.carrot:
        return 160;
      case CropType.tomato:
        return 300;
      case CropType.potato:
        return 250;
      case CropType.strawberry:
        return 400;
      case CropType.pumpkin:
        return 600;
      case CropType.sunflower:
        return 350;
    }
  }

  int get harvestAmount {
    switch (this) {
      case CropType.wheat:
        return 3;
      case CropType.corn:
        return 2;
      case CropType.carrot:
        return 4;
      case CropType.tomato:
        return 3;
      case CropType.potato:
        return 5;
      case CropType.strawberry:
        return 6;
      case CropType.pumpkin:
        return 1;
      case CropType.sunflower:
        return 2;
    }
  }

  String get emoji {
    switch (this) {
      case CropType.wheat:
        return '🌾';
      case CropType.corn:
        return '🌽';
      case CropType.carrot:
        return '🥕';
      case CropType.tomato:
        return '🍅';
      case CropType.potato:
        return '🥔';
      case CropType.strawberry:
        return '🍓';
      case CropType.pumpkin:
        return '🎃';
      case CropType.sunflower:
        return '🌻';
    }
  }
}

/// Extension for animal properties
extension AnimalTypeExtension on AnimalType {
  String get name {
    switch (this) {
      case AnimalType.chicken:
        return 'Chicken';
      case AnimalType.cow:
        return 'Cow';
      case AnimalType.pig:
        return 'Pig';
      case AnimalType.sheep:
        return 'Sheep';
    }
  }

  int get purchaseCost {
    switch (this) {
      case AnimalType.chicken:
        return 500;
      case AnimalType.cow:
        return 2000;
      case AnimalType.pig:
        return 1500;
      case AnimalType.sheep:
        return 1200;
    }
  }

  String get product {
    switch (this) {
      case AnimalType.chicken:
        return 'Egg';
      case AnimalType.cow:
        return 'Milk';
      case AnimalType.pig:
        return 'Truffle';
      case AnimalType.sheep:
        return 'Wool';
    }
  }

  int get productValue {
    switch (this) {
      case AnimalType.chicken:
        return 150;
      case AnimalType.cow:
        return 400;
      case AnimalType.pig:
        return 350;
      case AnimalType.sheep:
        return 300;
    }
  }

  int get productionTimeMinutes {
    switch (this) {
      case AnimalType.chicken:
        return 10;
      case AnimalType.cow:
        return 30;
      case AnimalType.pig:
        return 45;
      case AnimalType.sheep:
        return 25;
    }
  }

  String get emoji {
    switch (this) {
      case AnimalType.chicken:
        return '🐔';
      case AnimalType.cow:
        return '🐄';
      case AnimalType.pig:
        return '🐷';
      case AnimalType.sheep:
        return '🐑';
    }
  }

  String get productEmoji {
    switch (this) {
      case AnimalType.chicken:
        return '🥚';
      case AnimalType.cow:
        return '🥛';
      case AnimalType.pig:
        return '🍄';
      case AnimalType.sheep:
        return '🧶';
    }
  }
}

/// Extension for building properties
extension FarmBuildingTypeExtension on FarmBuildingType {
  String get name {
    switch (this) {
      case FarmBuildingType.barn:
        return 'Barn';
      case FarmBuildingType.silo:
        return 'Silo';
      case FarmBuildingType.coop:
        return 'Chicken Coop';
      case FarmBuildingType.stable:
        return 'Stable';
      case FarmBuildingType.mill:
        return 'Windmill';
      case FarmBuildingType.bakery:
        return 'Bakery';
      case FarmBuildingType.well:
        return 'Well';
    }
  }

  int get buildCost {
    switch (this) {
      case FarmBuildingType.barn:
        return 3000;
      case FarmBuildingType.silo:
        return 2000;
      case FarmBuildingType.coop:
        return 1500;
      case FarmBuildingType.stable:
        return 2500;
      case FarmBuildingType.mill:
        return 4000;
      case FarmBuildingType.bakery:
        return 5000;
      case FarmBuildingType.well:
        return 1000;
    }
  }

  String get description {
    switch (this) {
      case FarmBuildingType.barn:
        return 'Store animals and animal products';
      case FarmBuildingType.silo:
        return 'Store harvested crops';
      case FarmBuildingType.coop:
        return 'House for chickens';
      case FarmBuildingType.stable:
        return 'House for larger animals';
      case FarmBuildingType.mill:
        return 'Process wheat into flour';
      case FarmBuildingType.bakery:
        return 'Bake goods for extra coins';
      case FarmBuildingType.well:
        return 'Water source for crops';
    }
  }

  int get storageCapacity {
    switch (this) {
      case FarmBuildingType.barn:
        return 50;
      case FarmBuildingType.silo:
        return 100;
      case FarmBuildingType.coop:
        return 10;
      case FarmBuildingType.stable:
        return 8;
      case FarmBuildingType.mill:
        return 20;
      case FarmBuildingType.bakery:
        return 15;
      case FarmBuildingType.well:
        return 0;
    }
  }

  String get emoji {
    switch (this) {
      case FarmBuildingType.barn:
        return '🏚️';
      case FarmBuildingType.silo:
        return '🏛️';
      case FarmBuildingType.coop:
        return '🐔';
      case FarmBuildingType.stable:
        return '🐴';
      case FarmBuildingType.mill:
        return '🌬️';
      case FarmBuildingType.bakery:
        return '🥖';
      case FarmBuildingType.well:
        return '🪣';
    }
  }

  /// Size in grid tiles (width x height)
  List<int> get size {
    switch (this) {
      case FarmBuildingType.barn:
        return [3, 3];
      case FarmBuildingType.silo:
        return [2, 2];
      case FarmBuildingType.coop:
        return [2, 2];
      case FarmBuildingType.stable:
        return [3, 2];
      case FarmBuildingType.mill:
        return [2, 2];
      case FarmBuildingType.bakery:
        return [2, 2];
      case FarmBuildingType.well:
        return [1, 1];
    }
  }
}

/// Represents a single crop on a tile
class FarmCrop extends Equatable {
  final String id;
  final CropType type;
  final GrowthStage stage;
  final DateTime plantedAt;
  final DateTime? lastWatered;
  final bool needsWater;
  final int gridX;
  final int gridY;

  const FarmCrop({
    required this.id,
    required this.type,
    required this.stage,
    required this.plantedAt,
    this.lastWatered,
    this.needsWater = false,
    required this.gridX,
    required this.gridY,
  });

  FarmCrop copyWith({
    String? id,
    CropType? type,
    GrowthStage? stage,
    DateTime? plantedAt,
    DateTime? lastWatered,
    bool? needsWater,
    int? gridX,
    int? gridY,
  }) {
    return FarmCrop(
      id: id ?? this.id,
      type: type ?? this.type,
      stage: stage ?? this.stage,
      plantedAt: plantedAt ?? this.plantedAt,
      lastWatered: lastWatered ?? this.lastWatered,
      needsWater: needsWater ?? this.needsWater,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
    );
  }

  /// Calculate current growth stage based on time
  GrowthStage calculateGrowthStage() {
    final elapsed = DateTime.now().difference(plantedAt).inMinutes;
    final totalTime = type.growthTimeMinutes;
    final progress = elapsed / totalTime;

    if (progress >= 1.0) return GrowthStage.harvestable;
    if (progress >= 0.75) return GrowthStage.mature;
    if (progress >= 0.5) return GrowthStage.growing;
    if (progress >= 0.25) return GrowthStage.sprout;
    return GrowthStage.seed;
  }

  /// Get growth progress (0.0 to 1.0)
  double get growthProgress {
    final elapsed = DateTime.now().difference(plantedAt).inMinutes;
    final totalTime = type.growthTimeMinutes;
    return (elapsed / totalTime).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'stage': stage.index,
      'plantedAt': plantedAt.toIso8601String(),
      'lastWatered': lastWatered?.toIso8601String(),
      'needsWater': needsWater,
      'gridX': gridX,
      'gridY': gridY,
    };
  }

  factory FarmCrop.fromJson(Map<String, dynamic> json) {
    return FarmCrop(
      id: json['id'],
      type: CropType.values[json['type']],
      stage: GrowthStage.values[json['stage']],
      plantedAt: DateTime.parse(json['plantedAt']),
      lastWatered: json['lastWatered'] != null
          ? DateTime.parse(json['lastWatered'])
          : null,
      needsWater: json['needsWater'] ?? false,
      gridX: json['gridX'],
      gridY: json['gridY'],
    );
  }

  @override
  List<Object?> get props =>
      [id, type, stage, plantedAt, lastWatered, needsWater, gridX, gridY];
}

/// Represents an animal on the farm
class FarmAnimal extends Equatable {
  final String id;
  final AnimalType type;
  final String name;
  final AnimalState state;
  final DateTime lastFed;
  final DateTime? productReadyAt;
  final int gridX;
  final int gridY;
  final int happiness; // 0-100

  const FarmAnimal({
    required this.id,
    required this.type,
    required this.name,
    required this.state,
    required this.lastFed,
    this.productReadyAt,
    required this.gridX,
    required this.gridY,
    this.happiness = 100,
  });

  FarmAnimal copyWith({
    String? id,
    AnimalType? type,
    String? name,
    AnimalState? state,
    DateTime? lastFed,
    DateTime? productReadyAt,
    int? gridX,
    int? gridY,
    int? happiness,
  }) {
    return FarmAnimal(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      state: state ?? this.state,
      lastFed: lastFed ?? this.lastFed,
      productReadyAt: productReadyAt ?? this.productReadyAt,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      happiness: happiness ?? this.happiness,
    );
  }

  /// Check if animal is hungry (not fed in last hour)
  bool get isHungry {
    return DateTime.now().difference(lastFed).inMinutes > 60;
  }

  /// Check if product is ready to collect
  bool get hasProductReady {
    if (productReadyAt == null) return false;
    return DateTime.now().isAfter(productReadyAt!);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'state': state.index,
      'lastFed': lastFed.toIso8601String(),
      'productReadyAt': productReadyAt?.toIso8601String(),
      'gridX': gridX,
      'gridY': gridY,
      'happiness': happiness,
    };
  }

  factory FarmAnimal.fromJson(Map<String, dynamic> json) {
    return FarmAnimal(
      id: json['id'],
      type: AnimalType.values[json['type']],
      name: json['name'],
      state: AnimalState.values[json['state']],
      lastFed: DateTime.parse(json['lastFed']),
      productReadyAt: json['productReadyAt'] != null
          ? DateTime.parse(json['productReadyAt'])
          : null,
      gridX: json['gridX'],
      gridY: json['gridY'],
      happiness: json['happiness'] ?? 100,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, name, state, lastFed, productReadyAt, gridX, gridY, happiness];
}

/// Represents a building on the farm
class FarmBuilding extends Equatable {
  final String id;
  final FarmBuildingType type;
  final int level;
  final int gridX;
  final int gridY;
  final List<String> storedItems; // Item IDs stored in this building
  final bool isProcessing;
  final DateTime? processingCompleteAt;

  const FarmBuilding({
    required this.id,
    required this.type,
    this.level = 1,
    required this.gridX,
    required this.gridY,
    this.storedItems = const [],
    this.isProcessing = false,
    this.processingCompleteAt,
  });

  FarmBuilding copyWith({
    String? id,
    FarmBuildingType? type,
    int? level,
    int? gridX,
    int? gridY,
    List<String>? storedItems,
    bool? isProcessing,
    DateTime? processingCompleteAt,
  }) {
    return FarmBuilding(
      id: id ?? this.id,
      type: type ?? this.type,
      level: level ?? this.level,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      storedItems: storedItems ?? this.storedItems,
      isProcessing: isProcessing ?? this.isProcessing,
      processingCompleteAt: processingCompleteAt ?? this.processingCompleteAt,
    );
  }

  int get maxStorage => type.storageCapacity * level;
  int get currentStorage => storedItems.length;
  bool get isFull => currentStorage >= maxStorage;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'level': level,
      'gridX': gridX,
      'gridY': gridY,
      'storedItems': storedItems,
      'isProcessing': isProcessing,
      'processingCompleteAt': processingCompleteAt?.toIso8601String(),
    };
  }

  factory FarmBuilding.fromJson(Map<String, dynamic> json) {
    return FarmBuilding(
      id: json['id'],
      type: FarmBuildingType.values[json['type']],
      level: json['level'] ?? 1,
      gridX: json['gridX'],
      gridY: json['gridY'],
      storedItems: List<String>.from(json['storedItems'] ?? []),
      isProcessing: json['isProcessing'] ?? false,
      processingCompleteAt: json['processingCompleteAt'] != null
          ? DateTime.parse(json['processingCompleteAt'])
          : null,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        level,
        gridX,
        gridY,
        storedItems,
        isProcessing,
        processingCompleteAt
      ];
}

/// Represents a single tile on the farm grid
class FarmTile extends Equatable {
  final int x;
  final int y;
  final TileType type;
  final String? cropId;
  final String? animalId;
  final String? buildingId;

  const FarmTile({
    required this.x,
    required this.y,
    this.type = TileType.grass,
    this.cropId,
    this.animalId,
    this.buildingId,
  });

  FarmTile copyWith({
    int? x,
    int? y,
    TileType? type,
    String? cropId,
    String? animalId,
    String? buildingId,
  }) {
    return FarmTile(
      x: x ?? this.x,
      y: y ?? this.y,
      type: type ?? this.type,
      cropId: cropId ?? this.cropId,
      animalId: animalId ?? this.animalId,
      buildingId: buildingId ?? this.buildingId,
    );
  }

  bool get isEmpty => cropId == null && animalId == null && buildingId == null;
  bool get isOccupied => !isEmpty;

  Map<String, dynamic> toJson() {
    return {
      'x': x,
      'y': y,
      'type': type.index,
      'cropId': cropId,
      'animalId': animalId,
      'buildingId': buildingId,
    };
  }

  factory FarmTile.fromJson(Map<String, dynamic> json) {
    return FarmTile(
      x: json['x'],
      y: json['y'],
      type: TileType.values[json['type']],
      cropId: json['cropId'],
      animalId: json['animalId'],
      buildingId: json['buildingId'],
    );
  }

  @override
  List<Object?> get props => [x, y, type, cropId, animalId, buildingId];
}

/// Inventory item for the player
class InventoryItem extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final int quantity;
  final int value; // Steps value

  const InventoryItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.quantity,
    required this.value,
  });

  InventoryItem copyWith({
    String? id,
    String? name,
    String? emoji,
    int? quantity,
    int? value,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      quantity: quantity ?? this.quantity,
      value: value ?? this.value,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'quantity': quantity,
      'value': value,
    };
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      name: json['name'],
      emoji: json['emoji'],
      quantity: json['quantity'],
      value: json['value'],
    );
  }

  @override
  List<Object?> get props => [id, name, emoji, quantity, value];
}

/// Complete farm state
class FarmState extends Equatable {
  final String userId;
  final int coins; // Steps currency
  final int level;
  final int experience;
  final List<FarmTile> tiles;
  final List<FarmCrop> crops;
  final List<FarmAnimal> animals;
  final List<FarmBuilding> buildings;
  final List<InventoryItem> inventory;
  final DateTime lastUpdated;

  const FarmState({
    required this.userId,
    this.coins = 0,
    this.level = 1,
    this.experience = 0,
    this.tiles = const [],
    this.crops = const [],
    this.animals = const [],
    this.buildings = const [],
    this.inventory = const [],
    required this.lastUpdated,
  });

  FarmState copyWith({
    String? userId,
    int? coins,
    int? level,
    int? experience,
    List<FarmTile>? tiles,
    List<FarmCrop>? crops,
    List<FarmAnimal>? animals,
    List<FarmBuilding>? buildings,
    List<InventoryItem>? inventory,
    DateTime? lastUpdated,
  }) {
    return FarmState(
      userId: userId ?? this.userId,
      coins: coins ?? this.coins,
      level: level ?? this.level,
      experience: experience ?? this.experience,
      tiles: tiles ?? this.tiles,
      crops: crops ?? this.crops,
      animals: animals ?? this.animals,
      buildings: buildings ?? this.buildings,
      inventory: inventory ?? this.inventory,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Get experience needed for next level
  int get experienceForNextLevel => level * 1000;

  /// Get progress to next level (0.0 to 1.0)
  double get levelProgress => experience / experienceForNextLevel;

  /// Get tile at position
  FarmTile? getTileAt(int x, int y) {
    try {
      return tiles.firstWhere((t) => t.x == x && t.y == y);
    } catch (_) {
      return null;
    }
  }

  /// Get crop by ID
  FarmCrop? getCrop(String id) {
    try {
      return crops.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get animal by ID
  FarmAnimal? getAnimal(String id) {
    try {
      return animals.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get building by ID
  FarmBuilding? getBuilding(String id) {
    try {
      return buildings.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get inventory item by ID
  InventoryItem? getInventoryItem(String id) {
    try {
      return inventory.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Count harvestable crops
  int get harvestableCropsCount {
    return crops
        .where((c) => c.calculateGrowthStage() == GrowthStage.harvestable)
        .length;
  }

  /// Count animals ready to collect from
  int get animalsReadyCount {
    return animals.where((a) => a.hasProductReady).length;
  }

  /// Count hungry animals
  int get hungryAnimalsCount {
    return animals.where((a) => a.isHungry).length;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'coins': coins,
      'level': level,
      'experience': experience,
      'tiles': tiles.map((t) => t.toJson()).toList(),
      'crops': crops.map((c) => c.toJson()).toList(),
      'animals': animals.map((a) => a.toJson()).toList(),
      'buildings': buildings.map((b) => b.toJson()).toList(),
      'inventory': inventory.map((i) => i.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory FarmState.fromJson(Map<String, dynamic> json) {
    return FarmState(
      userId: json['userId'],
      coins: json['coins'] ?? 0,
      level: json['level'] ?? 1,
      experience: json['experience'] ?? 0,
      tiles:
          (json['tiles'] as List?)?.map((t) => FarmTile.fromJson(t)).toList() ??
              [],
      crops:
          (json['crops'] as List?)?.map((c) => FarmCrop.fromJson(c)).toList() ??
              [],
      animals: (json['animals'] as List?)
              ?.map((a) => FarmAnimal.fromJson(a))
              .toList() ??
          [],
      buildings: (json['buildings'] as List?)
              ?.map((b) => FarmBuilding.fromJson(b))
              .toList() ??
          [],
      inventory: (json['inventory'] as List?)
              ?.map((i) => InventoryItem.fromJson(i))
              .toList() ??
          [],
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'])
          : DateTime.now(),
    );
  }

  /// Create initial farm state for a new user
  factory FarmState.initial(String userId) {
    const gridSize = 10;
    final tiles = <FarmTile>[];

    for (int y = 0; y < gridSize; y++) {
      for (int x = 0; x < gridSize; x++) {
        tiles.add(FarmTile(x: x, y: y, type: TileType.grass));
      }
    }

    return FarmState(
      userId: userId,
      coins: 1000, // Starting coins (steps)
      level: 1,
      experience: 0,
      tiles: tiles,
      crops: [],
      animals: [],
      buildings: [],
      inventory: [],
      lastUpdated: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        userId,
        coins,
        level,
        experience,
        tiles,
        crops,
        animals,
        buildings,
        inventory,
        lastUpdated
      ];
}
