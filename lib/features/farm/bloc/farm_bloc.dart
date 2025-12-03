import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/farm_models.dart';
import '../../../services/farm_service.dart';
import '../../../services/storage_service.dart';

// Events
abstract class FarmEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class FarmLoadRequested extends FarmEvent {}

class FarmPlowTile extends FarmEvent {
  final int x;
  final int y;

  FarmPlowTile({required this.x, required this.y});

  @override
  List<Object?> get props => [x, y];
}

class FarmPlantCrop extends FarmEvent {
  final int x;
  final int y;
  final CropType cropType;

  FarmPlantCrop({required this.x, required this.y, required this.cropType});

  @override
  List<Object?> get props => [x, y, cropType];
}

class FarmWaterCrop extends FarmEvent {
  final String cropId;

  FarmWaterCrop({required this.cropId});

  @override
  List<Object?> get props => [cropId];
}

class FarmHarvestCrop extends FarmEvent {
  final String cropId;

  FarmHarvestCrop({required this.cropId});

  @override
  List<Object?> get props => [cropId];
}

class FarmBuyAnimal extends FarmEvent {
  final AnimalType type;
  final String name;
  final int x;
  final int y;

  FarmBuyAnimal({
    required this.type,
    required this.name,
    required this.x,
    required this.y,
  });

  @override
  List<Object?> get props => [type, name, x, y];
}

class FarmFeedAnimal extends FarmEvent {
  final String animalId;

  FarmFeedAnimal({required this.animalId});

  @override
  List<Object?> get props => [animalId];
}

class FarmCollectProduct extends FarmEvent {
  final String animalId;

  FarmCollectProduct({required this.animalId});

  @override
  List<Object?> get props => [animalId];
}

class FarmBuyBuilding extends FarmEvent {
  final FarmBuildingType type;
  final int x;
  final int y;

  FarmBuyBuilding({required this.type, required this.x, required this.y});

  @override
  List<Object?> get props => [type, x, y];
}

class FarmSellItem extends FarmEvent {
  final String itemId;
  final int quantity;

  FarmSellItem({required this.itemId, required this.quantity});

  @override
  List<Object?> get props => [itemId, quantity];
}

class FarmAddSteps extends FarmEvent {
  final int steps;

  FarmAddSteps({required this.steps});

  @override
  List<Object?> get props => [steps];
}

class FarmSelectTile extends FarmEvent {
  final int? x;
  final int? y;

  FarmSelectTile({this.x, this.y});

  @override
  List<Object?> get props => [x, y];
}

class FarmSetTool extends FarmEvent {
  final FarmTool tool;

  FarmSetTool({required this.tool});

  @override
  List<Object?> get props => [tool];
}

class FarmRefresh extends FarmEvent {}

// Farm tools
enum FarmTool {
  none,
  plow,
  plant,
  water,
  harvest,
  feed,
  collect,
  build,
}

// States
abstract class FarmStateBase extends Equatable {
  @override
  List<Object?> get props => [];
}

class FarmInitial extends FarmStateBase {}

class FarmLoading extends FarmStateBase {}

class FarmLoaded extends FarmStateBase {
  final FarmState farmState;
  final int? selectedX;
  final int? selectedY;
  final FarmTool currentTool;
  final CropType? selectedCropType;
  final AnimalType? selectedAnimalType;
  final FarmBuildingType? selectedBuildingType;
  final String? message;
  final bool isError;

  FarmLoaded({
    required this.farmState,
    this.selectedX,
    this.selectedY,
    this.currentTool = FarmTool.none,
    this.selectedCropType,
    this.selectedAnimalType,
    this.selectedBuildingType,
    this.message,
    this.isError = false,
  });

  FarmLoaded copyWith({
    FarmState? farmState,
    int? selectedX,
    int? selectedY,
    FarmTool? currentTool,
    CropType? selectedCropType,
    AnimalType? selectedAnimalType,
    FarmBuildingType? selectedBuildingType,
    String? message,
    bool? isError,
    bool clearSelection = false,
    bool clearMessage = false,
  }) {
    return FarmLoaded(
      farmState: farmState ?? this.farmState,
      selectedX: clearSelection ? null : (selectedX ?? this.selectedX),
      selectedY: clearSelection ? null : (selectedY ?? this.selectedY),
      currentTool: currentTool ?? this.currentTool,
      selectedCropType: selectedCropType ?? this.selectedCropType,
      selectedAnimalType: selectedAnimalType ?? this.selectedAnimalType,
      selectedBuildingType: selectedBuildingType ?? this.selectedBuildingType,
      message: clearMessage ? null : (message ?? this.message),
      isError: isError ?? this.isError,
    );
  }

  /// Get selected tile
  FarmTile? get selectedTile {
    if (selectedX == null || selectedY == null) return null;
    return farmState.getTileAt(selectedX!, selectedY!);
  }

  /// Get crop at selected tile
  FarmCrop? get selectedCrop {
    final tile = selectedTile;
    if (tile?.cropId == null) return null;
    return farmState.getCrop(tile!.cropId!);
  }

  /// Get animal at selected tile
  FarmAnimal? get selectedAnimal {
    final tile = selectedTile;
    if (tile?.animalId == null) return null;
    return farmState.getAnimal(tile!.animalId!);
  }

  /// Get building at selected tile
  FarmBuilding? get selectedBuilding {
    final tile = selectedTile;
    if (tile?.buildingId == null) return null;
    return farmState.getBuilding(tile!.buildingId!);
  }

  @override
  List<Object?> get props => [
        farmState,
        selectedX,
        selectedY,
        currentTool,
        selectedCropType,
        selectedAnimalType,
        selectedBuildingType,
        message,
        isError,
      ];
}

class FarmError extends FarmStateBase {
  final String message;

  FarmError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class FarmBloc extends Bloc<FarmEvent, FarmStateBase> {
  final FarmService farmService;
  final StorageService storageService;
  Timer? _refreshTimer;

  FarmBloc({
    required this.farmService,
    required this.storageService,
  }) : super(FarmInitial()) {
    on<FarmLoadRequested>(_onLoadRequested);
    on<FarmPlowTile>(_onPlowTile);
    on<FarmPlantCrop>(_onPlantCrop);
    on<FarmWaterCrop>(_onWaterCrop);
    on<FarmHarvestCrop>(_onHarvestCrop);
    on<FarmBuyAnimal>(_onBuyAnimal);
    on<FarmFeedAnimal>(_onFeedAnimal);
    on<FarmCollectProduct>(_onCollectProduct);
    on<FarmBuyBuilding>(_onBuyBuilding);
    on<FarmSellItem>(_onSellItem);
    on<FarmAddSteps>(_onAddSteps);
    on<FarmSelectTile>(_onSelectTile);
    on<FarmSetTool>(_onSetTool);
    on<FarmRefresh>(_onRefresh);
  }

  Future<void> _onLoadRequested(
    FarmLoadRequested event,
    Emitter<FarmStateBase> emit,
  ) async {
    emit(FarmLoading());

    try {
      final user = storageService.getUser();
      if (user == null) {
        emit(FarmError(message: 'Please log in to play'));
        return;
      }

      final farmState = await farmService.getFarmState(user.id);
      emit(FarmLoaded(farmState: farmState));

      // Start refresh timer for crop/animal updates
      _startRefreshTimer();
    } catch (e) {
      emit(FarmError(message: 'Failed to load farm: ${e.toString()}'));
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      add(FarmRefresh());
    });
  }

  Future<void> _onRefresh(
    FarmRefresh event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    // Just re-emit to trigger UI update for crop growth
    emit(currentState.copyWith(clearMessage: true));
  }

  Future<void> _onPlowTile(
    FarmPlowTile event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      final newFarmState = await farmService.plowTile(
        currentState.farmState,
        event.x,
        event.y,
      );
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Tile plowed! 🌱',
        clearSelection: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onPlantCrop(
    FarmPlantCrop event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      final newFarmState = await farmService.plantCrop(
        currentState.farmState,
        event.x,
        event.y,
        event.cropType,
      );
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Planted ${event.cropType.emoji} ${event.cropType.name}!',
        clearSelection: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onWaterCrop(
    FarmWaterCrop event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      final newFarmState = await farmService.waterCrop(
        currentState.farmState,
        event.cropId,
      );
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Crop watered! 💧',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onHarvestCrop(
    FarmHarvestCrop event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      var newFarmState = await farmService.harvestCrop(
        currentState.farmState,
        event.cropId,
      );
      newFarmState = farmService.checkLevelUp(newFarmState);
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Harvested! 🎉',
        clearSelection: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onBuyAnimal(
    FarmBuyAnimal event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      var newFarmState = await farmService.buyAnimal(
        currentState.farmState,
        event.type,
        event.name,
        event.x,
        event.y,
      );
      newFarmState = farmService.checkLevelUp(newFarmState);
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Welcome ${event.name}! ${event.type.emoji}',
        clearSelection: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onFeedAnimal(
    FarmFeedAnimal event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      final newFarmState = await farmService.feedAnimal(
        currentState.farmState,
        event.animalId,
      );
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Animal fed! 🍽️',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onCollectProduct(
    FarmCollectProduct event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      var newFarmState = await farmService.collectAnimalProduct(
        currentState.farmState,
        event.animalId,
      );
      newFarmState = farmService.checkLevelUp(newFarmState);
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Product collected! 📦',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onBuyBuilding(
    FarmBuyBuilding event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      var newFarmState = await farmService.buyBuilding(
        currentState.farmState,
        event.type,
        event.x,
        event.y,
      );
      newFarmState = farmService.checkLevelUp(newFarmState);
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Built ${event.type.name}! 🏗️',
        clearSelection: true,
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onSellItem(
    FarmSellItem event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      final newFarmState = await farmService.sellInventoryItem(
        currentState.farmState,
        event.itemId,
        event.quantity,
      );
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: 'Sold! 💰',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  Future<void> _onAddSteps(
    FarmAddSteps event,
    Emitter<FarmStateBase> emit,
  ) async {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    try {
      final newFarmState = await farmService.addSteps(
        currentState.farmState,
        event.steps,
      );
      emit(currentState.copyWith(
        farmState: newFarmState,
        message: '+${event.steps} coins from walking! 🚶',
      ));
    } catch (e) {
      emit(currentState.copyWith(
        message: e.toString(),
        isError: true,
      ));
    }
  }

  void _onSelectTile(
    FarmSelectTile event,
    Emitter<FarmStateBase> emit,
  ) {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    emit(currentState.copyWith(
      selectedX: event.x,
      selectedY: event.y,
      clearMessage: true,
    ));
  }

  void _onSetTool(
    FarmSetTool event,
    Emitter<FarmStateBase> emit,
  ) {
    final currentState = state;
    if (currentState is! FarmLoaded) return;

    emit(currentState.copyWith(
      currentTool: event.tool,
      clearMessage: true,
    ));
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
