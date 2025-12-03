import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/models/farm_models.dart';

/// Service for managing farm game state
class FarmService {
  final FirebaseFirestore? _firestore;
  late Box<String> _farmBox;
  bool _initialized = false;

  FarmService({FirebaseFirestore? firestore}) : _firestore = firestore;

  /// Initialize the service
  Future<void> init() async {
    if (_initialized) return;
    _farmBox = await Hive.openBox<String>('farm_state');
    _initialized = true;
  }

  /// Get farm state for a user
  Future<FarmState> getFarmState(String userId) async {
    await init();

    // Try local storage first
    final localData = _farmBox.get(userId);
    if (localData != null) {
      return FarmState.fromJson(jsonDecode(localData));
    }

    // Try Firestore if available
    if (_firestore != null) {
      try {
        final doc = await _firestore!.collection('farms').doc(userId).get();

        if (doc.exists) {
          final farmState = FarmState.fromJson(doc.data()!);
          // Save to local storage
          await _saveFarmStateLocally(farmState);
          return farmState;
        }
      } catch (e) {
        print('Failed to load farm from Firestore: $e');
      }
    }

    // Create new farm for user
    final newFarm = FarmState.initial(userId);
    await saveFarmState(newFarm);
    return newFarm;
  }

  /// Save farm state
  Future<void> saveFarmState(FarmState state) async {
    await init();

    // Save locally
    await _saveFarmStateLocally(state);

    // Save to Firestore if available
    if (_firestore != null) {
      try {
        await _firestore!
            .collection('farms')
            .doc(state.userId)
            .set(state.toJson());
      } catch (e) {
        print('Failed to save farm to Firestore: $e');
      }
    }
  }

  Future<void> _saveFarmStateLocally(FarmState state) async {
    await _farmBox.put(state.userId, jsonEncode(state.toJson()));
  }

  /// Plow a tile (prepare for planting)
  Future<FarmState> plowTile(FarmState state, int x, int y) async {
    final plowCost = 10;
    if (state.coins < plowCost) {
      throw FarmException('Not enough coins to plow');
    }

    final tile = state.getTileAt(x, y);
    if (tile == null) {
      throw FarmException('Invalid tile position');
    }

    if (tile.type != TileType.grass && tile.type != TileType.dirt) {
      throw FarmException('Cannot plow this tile');
    }

    final updatedTiles = state.tiles.map((t) {
      if (t.x == x && t.y == y) {
        return t.copyWith(type: TileType.plowed);
      }
      return t;
    }).toList();

    final newState = state.copyWith(
      tiles: updatedTiles,
      coins: state.coins - plowCost,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Plant a crop on a plowed tile
  Future<FarmState> plantCrop(
      FarmState state, int x, int y, CropType cropType) async {
    final seedCost = cropType.seedCost;
    if (state.coins < seedCost) {
      throw FarmException('Not enough coins for seeds');
    }

    final tile = state.getTileAt(x, y);
    if (tile == null) {
      throw FarmException('Invalid tile position');
    }

    if (tile.type != TileType.plowed) {
      throw FarmException('Tile must be plowed first');
    }

    if (tile.cropId != null) {
      throw FarmException('Tile already has a crop');
    }

    final cropId = const Uuid().v4();
    final newCrop = FarmCrop(
      id: cropId,
      type: cropType,
      stage: GrowthStage.seed,
      plantedAt: DateTime.now(),
      gridX: x,
      gridY: y,
    );

    final updatedTiles = state.tiles.map((t) {
      if (t.x == x && t.y == y) {
        return t.copyWith(type: TileType.planted, cropId: cropId);
      }
      return t;
    }).toList();

    final newState = state.copyWith(
      tiles: updatedTiles,
      crops: [...state.crops, newCrop],
      coins: state.coins - seedCost,
      experience: state.experience + 10,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Water a crop
  Future<FarmState> waterCrop(FarmState state, String cropId) async {
    final crop = state.getCrop(cropId);
    if (crop == null) {
      throw FarmException('Crop not found');
    }

    final updatedCrops = state.crops.map((c) {
      if (c.id == cropId) {
        return c.copyWith(
          lastWatered: DateTime.now(),
          needsWater: false,
        );
      }
      return c;
    }).toList();

    final newState = state.copyWith(
      crops: updatedCrops,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Harvest a mature crop
  Future<FarmState> harvestCrop(FarmState state, String cropId) async {
    final crop = state.getCrop(cropId);
    if (crop == null) {
      throw FarmException('Crop not found');
    }

    if (crop.calculateGrowthStage() != GrowthStage.harvestable) {
      throw FarmException('Crop is not ready to harvest');
    }

    // Calculate harvest reward
    final reward = crop.type.harvestValue * crop.type.harvestAmount;
    final experience = crop.type.harvestValue ~/ 10;

    // Add to inventory
    final existingItem = state.inventory
        .where(
          (i) => i.id == 'crop_${crop.type.name}',
        )
        .firstOrNull;

    List<InventoryItem> updatedInventory;
    if (existingItem != null) {
      updatedInventory = state.inventory.map((i) {
        if (i.id == 'crop_${crop.type.name}') {
          return i.copyWith(quantity: i.quantity + crop.type.harvestAmount);
        }
        return i;
      }).toList();
    } else {
      updatedInventory = [
        ...state.inventory,
        InventoryItem(
          id: 'crop_${crop.type.name}',
          name: crop.type.name,
          emoji: crop.type.emoji,
          quantity: crop.type.harvestAmount,
          value: crop.type.harvestValue,
        ),
      ];
    }

    // Update tile back to plowed
    final updatedTiles = state.tiles.map((t) {
      if (t.x == crop.gridX && t.y == crop.gridY) {
        return FarmTile(x: t.x, y: t.y, type: TileType.plowed);
      }
      return t;
    }).toList();

    // Remove crop
    final updatedCrops = state.crops.where((c) => c.id != cropId).toList();

    final newState = state.copyWith(
      tiles: updatedTiles,
      crops: updatedCrops,
      coins: state.coins + reward,
      experience: state.experience + experience,
      inventory: updatedInventory,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Buy and place an animal
  Future<FarmState> buyAnimal(
    FarmState state,
    AnimalType type,
    String name,
    int x,
    int y,
  ) async {
    final cost = type.purchaseCost;
    if (state.coins < cost) {
      throw FarmException('Not enough coins to buy animal');
    }

    final tile = state.getTileAt(x, y);
    if (tile == null || tile.isOccupied) {
      throw FarmException('Cannot place animal here');
    }

    final animalId = const Uuid().v4();
    final newAnimal = FarmAnimal(
      id: animalId,
      type: type,
      name: name,
      state: AnimalState.hungry,
      lastFed: DateTime.now().subtract(const Duration(hours: 2)),
      gridX: x,
      gridY: y,
    );

    final updatedTiles = state.tiles.map((t) {
      if (t.x == x && t.y == y) {
        return t.copyWith(animalId: animalId);
      }
      return t;
    }).toList();

    final newState = state.copyWith(
      tiles: updatedTiles,
      animals: [...state.animals, newAnimal],
      coins: state.coins - cost,
      experience: state.experience + 50,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Feed an animal
  Future<FarmState> feedAnimal(FarmState state, String animalId) async {
    final animal = state.getAnimal(animalId);
    if (animal == null) {
      throw FarmException('Animal not found');
    }

    final productionTime = Duration(minutes: animal.type.productionTimeMinutes);

    final updatedAnimals = state.animals.map((a) {
      if (a.id == animalId) {
        return a.copyWith(
          lastFed: DateTime.now(),
          state: AnimalState.eating,
          productReadyAt: DateTime.now().add(productionTime),
          happiness: (a.happiness + 20).clamp(0, 100),
        );
      }
      return a;
    }).toList();

    final newState = state.copyWith(
      animals: updatedAnimals,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Collect product from animal
  Future<FarmState> collectAnimalProduct(
      FarmState state, String animalId) async {
    final animal = state.getAnimal(animalId);
    if (animal == null) {
      throw FarmException('Animal not found');
    }

    if (!animal.hasProductReady) {
      throw FarmException('No product ready');
    }

    final reward = animal.type.productValue;
    final experience = reward ~/ 10;

    // Add to inventory
    final productId = 'animal_${animal.type.product.toLowerCase()}';
    final existingItem =
        state.inventory.where((i) => i.id == productId).firstOrNull;

    List<InventoryItem> updatedInventory;
    if (existingItem != null) {
      updatedInventory = state.inventory.map((i) {
        if (i.id == productId) {
          return i.copyWith(quantity: i.quantity + 1);
        }
        return i;
      }).toList();
    } else {
      updatedInventory = [
        ...state.inventory,
        InventoryItem(
          id: productId,
          name: animal.type.product,
          emoji: animal.type.productEmoji,
          quantity: 1,
          value: animal.type.productValue,
        ),
      ];
    }

    final updatedAnimals = state.animals.map((a) {
      if (a.id == animalId) {
        return a.copyWith(
          state: AnimalState.hungry,
          productReadyAt: null,
        );
      }
      return a;
    }).toList();

    final newState = state.copyWith(
      animals: updatedAnimals,
      coins: state.coins + reward,
      experience: state.experience + experience,
      inventory: updatedInventory,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Buy and place a building
  Future<FarmState> buyBuilding(
    FarmState state,
    FarmBuildingType type,
    int x,
    int y,
  ) async {
    final cost = type.buildCost;
    if (state.coins < cost) {
      throw FarmException('Not enough coins to build');
    }

    // Check if area is clear
    final size = type.size;
    for (int dy = 0; dy < size[1]; dy++) {
      for (int dx = 0; dx < size[0]; dx++) {
        final tile = state.getTileAt(x + dx, y + dy);
        if (tile == null || tile.isOccupied) {
          throw FarmException('Not enough space for building');
        }
      }
    }

    final buildingId = const Uuid().v4();
    final newBuilding = FarmBuilding(
      id: buildingId,
      type: type,
      gridX: x,
      gridY: y,
    );

    // Update all tiles covered by building
    final updatedTiles = state.tiles.map((t) {
      if (t.x >= x && t.x < x + size[0] && t.y >= y && t.y < y + size[1]) {
        return t.copyWith(type: TileType.building, buildingId: buildingId);
      }
      return t;
    }).toList();

    final newState = state.copyWith(
      tiles: updatedTiles,
      buildings: [...state.buildings, newBuilding],
      coins: state.coins - cost,
      experience: state.experience + 100,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Sell inventory item
  Future<FarmState> sellInventoryItem(
      FarmState state, String itemId, int quantity) async {
    final item = state.getInventoryItem(itemId);
    if (item == null) {
      throw FarmException('Item not found');
    }

    if (item.quantity < quantity) {
      throw FarmException('Not enough items');
    }

    final totalValue = item.value * quantity;

    List<InventoryItem> updatedInventory;
    if (item.quantity == quantity) {
      updatedInventory = state.inventory.where((i) => i.id != itemId).toList();
    } else {
      updatedInventory = state.inventory.map((i) {
        if (i.id == itemId) {
          return i.copyWith(quantity: i.quantity - quantity);
        }
        return i;
      }).toList();
    }

    final newState = state.copyWith(
      inventory: updatedInventory,
      coins: state.coins + totalValue,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Add steps (coins) to farm
  Future<FarmState> addSteps(FarmState state, int steps) async {
    final newState = state.copyWith(
      coins: state.coins + steps,
      lastUpdated: DateTime.now(),
    );

    await saveFarmState(newState);
    return newState;
  }

  /// Check for level up
  FarmState checkLevelUp(FarmState state) {
    if (state.experience >= state.experienceForNextLevel) {
      return state.copyWith(
        level: state.level + 1,
        experience: state.experience - state.experienceForNextLevel,
      );
    }
    return state;
  }

  /// Clear all farm data (for testing)
  Future<void> clearFarmData(String userId) async {
    await init();
    await _farmBox.delete(userId);

    if (_firestore != null) {
      try {
        await _firestore!.collection('farms').doc(userId).delete();
      } catch (e) {
        print('Failed to delete farm from Firestore: $e');
      }
    }
  }
}

class FarmException implements Exception {
  final String message;
  FarmException(this.message);

  @override
  String toString() => message;
}
