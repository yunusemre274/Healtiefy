import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:pedometer/pedometer.dart';
import 'package:uuid/uuid.dart';

import '../../../data/models/session_model.dart';
import '../../../data/models/city_zone_model.dart';
import '../../../services/location_service.dart';
import '../../../services/city_builder_service.dart';
import '../../../services/storage_service.dart';

// Events
abstract class MapEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class MapInitRequested extends MapEvent {}

class MapStartTracking extends MapEvent {}

class MapStopTracking extends MapEvent {}

class MapPauseTracking extends MapEvent {}

class MapResumeTracking extends MapEvent {}

class MapSaveSession extends MapEvent {
  final String? cityName;

  MapSaveSession({this.cityName});

  @override
  List<Object?> get props => [cityName];
}

class MapDiscardSession extends MapEvent {}

class MapLocationUpdated extends MapEvent {
  final Position position;

  MapLocationUpdated({required this.position});

  @override
  List<Object?> get props => [position];
}

class MapAddBuilding extends MapEvent {
  final String zoneId;
  final BuildingType buildingType;
  final double latitude;
  final double longitude;

  MapAddBuilding({
    required this.zoneId,
    required this.buildingType,
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [zoneId, buildingType, latitude, longitude];
}

class MapLoadCityZones extends MapEvent {}

class MapSelectCityZone extends MapEvent {
  final String zoneId;

  MapSelectCityZone({required this.zoneId});

  @override
  List<Object?> get props => [zoneId];
}

class MapStepCountUpdated extends MapEvent {
  final int steps;

  MapStepCountUpdated({required this.steps});

  @override
  List<Object?> get props => [steps];
}

// States
enum TrackingStatus { idle, tracking, paused, saving }

abstract class MapState extends Equatable {
  @override
  List<Object?> get props => [];
}

class MapInitial extends MapState {}

class MapLoading extends MapState {}

class MapReady extends MapState {
  final Position? currentPosition;
  final List<LatLng> currentRoute;
  final TrackingStatus trackingStatus;
  final Duration trackingDuration;
  final double currentDistance;
  final int currentSteps;
  final List<CityZone> cityZones;
  final CityZone? selectedZone;
  final Session? activeSession;
  final List<double> heartRateReadings;

  MapReady({
    this.currentPosition,
    this.currentRoute = const [],
    this.trackingStatus = TrackingStatus.idle,
    this.trackingDuration = Duration.zero,
    this.currentDistance = 0,
    this.currentSteps = 0,
    this.cityZones = const [],
    this.selectedZone,
    this.activeSession,
    this.heartRateReadings = const [],
  });

  MapReady copyWith({
    Position? currentPosition,
    List<LatLng>? currentRoute,
    TrackingStatus? trackingStatus,
    Duration? trackingDuration,
    double? currentDistance,
    int? currentSteps,
    List<CityZone>? cityZones,
    CityZone? selectedZone,
    Session? activeSession,
    List<double>? heartRateReadings,
  }) {
    return MapReady(
      currentPosition: currentPosition ?? this.currentPosition,
      currentRoute: currentRoute ?? this.currentRoute,
      trackingStatus: trackingStatus ?? this.trackingStatus,
      trackingDuration: trackingDuration ?? this.trackingDuration,
      currentDistance: currentDistance ?? this.currentDistance,
      currentSteps: currentSteps ?? this.currentSteps,
      cityZones: cityZones ?? this.cityZones,
      selectedZone: selectedZone ?? this.selectedZone,
      activeSession: activeSession ?? this.activeSession,
      heartRateReadings: heartRateReadings ?? this.heartRateReadings,
    );
  }

  @override
  List<Object?> get props => [
        currentPosition,
        currentRoute,
        trackingStatus,
        trackingDuration,
        currentDistance,
        currentSteps,
        cityZones,
        selectedZone,
        activeSession,
        heartRateReadings,
      ];
}

class MapError extends MapState {
  final String message;

  MapError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class MapBloc extends Bloc<MapEvent, MapState> {
  final LocationService locationService;
  final CityBuilderService cityBuilderService;
  final StorageService storageService;

  StreamSubscription<Position>? _locationSubscription;
  StreamSubscription<List<LatLng>>? _trackingSubscription;
  StreamSubscription<StepCount>? _stepCountSubscription;
  Timer? _durationTimer;
  DateTime? _trackingStartTime;
  int _initialStepCount = 0;

  MapBloc({
    required this.locationService,
    required this.cityBuilderService,
    required this.storageService,
  }) : super(MapInitial()) {
    on<MapInitRequested>(_onInitRequested);
    on<MapStartTracking>(_onStartTracking);
    on<MapStopTracking>(_onStopTracking);
    on<MapPauseTracking>(_onPauseTracking);
    on<MapResumeTracking>(_onResumeTracking);
    on<MapSaveSession>(_onSaveSession);
    on<MapDiscardSession>(_onDiscardSession);
    on<MapLocationUpdated>(_onLocationUpdated);
    on<MapAddBuilding>(_onAddBuilding);
    on<MapLoadCityZones>(_onLoadCityZones);
    on<MapSelectCityZone>(_onSelectCityZone);
    on<MapStepCountUpdated>(_onStepCountUpdated);
  }

  void _onStepCountUpdated(
    MapStepCountUpdated event,
    Emitter<MapState> emit,
  ) {
    final currentState = state;
    if (currentState is! MapReady) return;
    if (currentState.trackingStatus != TrackingStatus.tracking) return;

    final sessionSteps = event.steps - _initialStepCount;
    emit(currentState.copyWith(
        currentSteps: sessionSteps > 0 ? sessionSteps : 0));
  }

  Future<void> _onInitRequested(
    MapInitRequested event,
    Emitter<MapState> emit,
  ) async {
    emit(MapLoading());

    try {
      final hasPermission = await locationService.requestPermission();
      if (!hasPermission) {
        emit(MapError(message: 'Location permission denied'));
        return;
      }

      final position = await locationService.getCurrentPosition();
      final cityZones = storageService.getCityZones();

      emit(MapReady(
        currentPosition: position,
        cityZones: cityZones,
      ));
    } catch (e) {
      emit(MapError(message: 'Failed to initialize map: ${e.toString()}'));
    }
  }

  Future<void> _onStartTracking(
    MapStartTracking event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    try {
      final started = await locationService.startTracking();
      if (!started) {
        emit(MapError(message: 'Failed to start tracking'));
        return;
      }

      _trackingStartTime = DateTime.now();
      _initialStepCount = 0;

      // Start pedometer for step counting
      try {
        _stepCountSubscription?.cancel();
        _stepCountSubscription = Pedometer.stepCountStream.listen(
          (StepCount stepCount) {
            if (_initialStepCount == 0) {
              _initialStepCount = stepCount.steps;
            }
            add(MapStepCountUpdated(steps: stepCount.steps));
          },
          onError: (error) {
            // Pedometer not available, fallback to distance-based estimation
            debugPrint('Pedometer error: $error');
          },
        );
      } catch (e) {
        debugPrint('Failed to initialize pedometer: $e');
      }

      // Start duration timer
      _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state is MapReady) {
          final ready = state as MapReady;
          if (ready.trackingStatus == TrackingStatus.tracking) {
            if (locationService.lastPosition != null) {
              add(MapLocationUpdated(position: locationService.lastPosition!));
            }
          }
        }
      });

      // Listen to location updates
      _locationSubscription = locationService.positionStream.listen((position) {
        add(MapLocationUpdated(position: position));
      });

      // Listen to route updates
      _trackingSubscription = locationService.trackingStream.listen((route) {
        if (state is MapReady) {
          final ready = state as MapReady;
          final distance = locationService.calculateRouteDistance(route);
          emit(ready.copyWith(
            currentRoute: route,
            currentDistance: distance,
          ));
        }
      });

      emit(currentState.copyWith(
        trackingStatus: TrackingStatus.tracking,
        currentRoute: [],
        currentDistance: 0,
        currentSteps: 0,
        trackingDuration: Duration.zero,
      ));
    } catch (e) {
      emit(MapError(message: 'Failed to start tracking: ${e.toString()}'));
    }
  }

  Future<void> _onStopTracking(
    MapStopTracking event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    _durationTimer?.cancel();
    await _locationSubscription?.cancel();
    await _trackingSubscription?.cancel();
    await _stepCountSubscription?.cancel();

    final route = await locationService.stopTracking();

    // Auto-save the session immediately
    add(MapSaveSession());

    emit(currentState.copyWith(
      trackingStatus: TrackingStatus.saving,
      currentRoute: route,
    ));
  }

  Future<void> _onPauseTracking(
    MapPauseTracking event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    locationService.pauseTracking();
    _durationTimer?.cancel();
    await _stepCountSubscription?.cancel();

    emit(currentState.copyWith(trackingStatus: TrackingStatus.paused));
  }

  Future<void> _onResumeTracking(
    MapResumeTracking event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    locationService.resumeTracking();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state is MapReady) {
        final ready = state as MapReady;
        if (ready.trackingStatus == TrackingStatus.tracking) {
          // Update duration
        }
      }
    });

    emit(currentState.copyWith(trackingStatus: TrackingStatus.tracking));
  }

  Future<void> _onSaveSession(
    MapSaveSession event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    try {
      final user = storageService.getUser();
      if (user == null) {
        emit(MapError(message: 'User not found'));
        return;
      }

      final durationMinutes = currentState.trackingDuration.inMinutes > 0
          ? currentState.trackingDuration.inMinutes
          : 1;

      // Use real step count from pedometer, fallback to distance estimation
      final steps = currentState.currentSteps > 0
          ? currentState.currentSteps
          : (currentState.currentDistance * 1312)
              .round(); // ~1312 steps per km fallback

      // Calculate calories based on steps (approx 0.04 kcal per step)
      final calories = steps * 0.04;
      final fatBurned = calories * 0.00013 * 1000;
      final avgHeartRate = currentState.heartRateReadings.isNotEmpty
          ? currentState.heartRateReadings.reduce((a, b) => a + b) /
              currentState.heartRateReadings.length
          : 75.0;

      final session = Session(
        id: const Uuid().v4(),
        userId: user.id,
        date: DateTime.now(),
        steps: steps,
        calories: calories,
        fatBurned: fatBurned,
        distanceKm: currentState.currentDistance,
        heartRateAvg: avgHeartRate,
        durationMinutes: durationMinutes,
        routeCoordinates: currentState.currentRoute,
        isCompleted: true,
        startTime: _trackingStartTime,
        endTime: DateTime.now(),
      );

      await storageService.saveSession(session);

      // Create city zone if distance is sufficient
      CityZone? newZone;
      if (currentState.currentDistance >= 0.5) {
        newZone = await cityBuilderService.createCityZone(
          session: session,
          userId: user.id,
          name: event.cityName,
        );
      }

      final updatedZones = storageService.getCityZones();
      locationService.clearRoute();

      emit(currentState.copyWith(
        trackingStatus: TrackingStatus.idle,
        currentRoute: [],
        currentDistance: 0,
        currentSteps: 0,
        trackingDuration: Duration.zero,
        cityZones: updatedZones,
        selectedZone: newZone,
        activeSession: session,
      ));
    } catch (e) {
      emit(MapError(message: 'Failed to save session: ${e.toString()}'));
    }
  }

  Future<void> _onDiscardSession(
    MapDiscardSession event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    locationService.clearRoute();

    emit(currentState.copyWith(
      trackingStatus: TrackingStatus.idle,
      currentRoute: [],
      currentDistance: 0,
      trackingDuration: Duration.zero,
    ));
  }

  void _onLocationUpdated(
    MapLocationUpdated event,
    Emitter<MapState> emit,
  ) {
    final currentState = state;
    if (currentState is! MapReady) return;

    final duration = _trackingStartTime != null
        ? DateTime.now().difference(_trackingStartTime!)
        : Duration.zero;

    emit(currentState.copyWith(
      currentPosition: event.position,
      trackingDuration: duration,
    ));
  }

  Future<void> _onAddBuilding(
    MapAddBuilding event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    try {
      final user = storageService.getUser();
      if (user == null) {
        emit(MapError(message: 'User not found'));
        return;
      }

      // Calculate total steps
      final sessions = storageService.getSessions();
      final totalSteps = sessions.fold(0, (sum, s) => sum + s.steps);

      final updatedZone = await cityBuilderService.addBuilding(
        zoneId: event.zoneId,
        type: event.buildingType,
        latitude: event.latitude,
        longitude: event.longitude,
        userSteps: totalSteps,
      );

      final updatedZones = currentState.cityZones.map((z) {
        return z.id == event.zoneId ? updatedZone : z;
      }).toList();

      emit(currentState.copyWith(
        cityZones: updatedZones,
        selectedZone: updatedZone,
      ));
    } on CityBuilderException catch (e) {
      emit(MapError(message: e.message));
    } catch (e) {
      emit(MapError(message: 'Failed to add building'));
    }
  }

  Future<void> _onLoadCityZones(
    MapLoadCityZones event,
    Emitter<MapState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MapReady) return;

    final cityZones = storageService.getCityZones();
    emit(currentState.copyWith(cityZones: cityZones));
  }

  void _onSelectCityZone(
    MapSelectCityZone event,
    Emitter<MapState> emit,
  ) {
    final currentState = state;
    if (currentState is! MapReady) return;

    final zone = currentState.cityZones.firstWhere(
      (z) => z.id == event.zoneId,
      orElse: () => throw Exception('Zone not found'),
    );

    emit(currentState.copyWith(selectedZone: zone));
  }

  @override
  Future<void> close() {
    _durationTimer?.cancel();
    _locationSubscription?.cancel();
    _trackingSubscription?.cancel();
    _stepCountSubscription?.cancel();
    return super.close();
  }
}
