import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/map_bloc.dart';
import '../../../widgets/cards/soft_card.dart';
import '../../../widgets/buttons/soft_button.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    context.read<MapBloc>().add(MapInitRequested());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<MapBloc, MapState>(
        listener: (context, state) {
          if (state is MapReady &&
              state.trackingStatus == TrackingStatus.tracking &&
              _mapController != null &&
              state.currentPosition != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(LatLng(
                state.currentPosition!.latitude,
                state.currentPosition!.longitude,
              )),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              // Google Map
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _getInitialPosition(state),
                  zoom: 16,
                ),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _setMapStyle(controller);
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                polylines: _getPolylines(state),
                markers: _getMarkers(state),
              ),
              // Top overlay
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Farm button
                      SoftIconButton(
                        icon: Icons.agriculture_rounded,
                        onPressed: () => context.go('/map/farm'),
                      ).animate().fadeIn().slideX(begin: -0.5),
                      // Recenter button
                      SoftIconButton(
                        icon: Icons.my_location_rounded,
                        onPressed: () => _recenterMap(state),
                      ).animate().fadeIn().slideX(begin: 0.5),
                    ],
                  ),
                ),
              ),
              // Stats overlay (when tracking)
              if (state is MapReady &&
                  state.trackingStatus == TrackingStatus.tracking)
                Positioned(
                  top: 100,
                  left: 16,
                  right: 16,
                  child: _TrackingStatsCard(state: state)
                      .animate()
                      .fadeIn()
                      .slideY(begin: -0.5),
                ),
              // Bottom control panel
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _ControlPanel(
                  state: state,
                  pulseController: _pulseController,
                ).animate().fadeIn().slideY(begin: 0.5),
              ),
            ],
          );
        },
      ),
    );
  }

  LatLng _getInitialPosition(MapState state) {
    if (state is MapReady && state.currentPosition != null) {
      return LatLng(
        state.currentPosition!.latitude,
        state.currentPosition!.longitude,
      );
    }
    return const LatLng(0, 0);
  }

  void _recenterMap(MapState state) {
    if (state is MapReady &&
        _mapController != null &&
        state.currentPosition != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(
          state.currentPosition!.latitude,
          state.currentPosition!.longitude,
        )),
      );
    }
  }

  void _setMapStyle(GoogleMapController controller) async {
    const mapStyle = '''
    [
      {
        "featureType": "poi",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "stylers": [{"visibility": "off"}]
      }
    ]
    ''';
    // ignore: deprecated_member_use
    await controller.setMapStyle(mapStyle);
  }

  Set<Polyline> _getPolylines(MapState state) {
    if (state is MapReady && state.currentRoute.length > 1) {
      // Convert model.LatLng to google_maps LatLng
      final points = state.currentRoute
          .map((coord) => LatLng(coord.latitude, coord.longitude))
          .toList();
      return {
        Polyline(
          polylineId: const PolylineId('route'),
          points: points,
          color: AppColors.primary,
          width: 5,
          patterns: [PatternItem.dot, PatternItem.gap(10)],
        ),
      };
    }
    return {};
  }

  Set<Marker> _getMarkers(MapState state) {
    final markers = <Marker>{};

    if (state is MapReady && state.currentRoute.isNotEmpty) {
      final firstCoord = state.currentRoute.first;
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(firstCoord.latitude, firstCoord.longitude),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    return markers;
  }
}

class _TrackingStatsCard extends StatelessWidget {
  final MapReady state;

  const _TrackingStatsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    // Use real step count from pedometer
    final steps = state.currentSteps;

    return SoftCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            icon: Icons.timer_rounded,
            value: _formatDuration(state.trackingDuration),
            label: 'Duration',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _StatItem(
            icon: Icons.straighten_rounded,
            value: '${state.currentDistance.toStringAsFixed(2)} km',
            label: 'Distance',
          ),
          Container(
            width: 1,
            height: 40,
            color: AppColors.divider,
          ),
          _StatItem(
            icon: Icons.directions_walk_rounded,
            value: '$steps',
            label: 'Steps',
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _ControlPanel extends StatelessWidget {
  final MapState state;
  final AnimationController pulseController;

  const _ControlPanel({
    required this.state,
    required this.pulseController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Control buttons based on state
            _buildControls(context),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    if (state is MapLoading) {
      return const CircularProgressIndicator();
    }

    if (state is MapReady) {
      final mapReady = state as MapReady;
      switch (mapReady.trackingStatus) {
        case TrackingStatus.idle:
          return _buildIdleControls(context);
        case TrackingStatus.tracking:
          return _buildTrackingControls(context, mapReady);
        case TrackingStatus.paused:
          return _buildPausedControls(context);
        case TrackingStatus.saving:
          return const CircularProgressIndicator();
      }
    }

    return _buildIdleControls(context);
  }

  Widget _buildIdleControls(BuildContext context) {
    return Column(
      children: [
        Text(
          'Ready to walk?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the button below to start tracking your walk',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AnimatedBuilder(
          animation: pulseController,
          builder: (context, child) {
            return Transform.scale(
              scale: 1 + (pulseController.value * 0.05),
              child: child,
            );
          },
          child: GestureDetector(
            onTap: () => context.read<MapBloc>().add(MapStartTracking()),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackingControls(BuildContext context, MapReady trackingState) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tracking',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Pause button
            _ControlButton(
              icon: Icons.pause_rounded,
              label: 'Pause',
              color: AppColors.secondary,
              onTap: () => context.read<MapBloc>().add(MapPauseTracking()),
            ),
            // Stop button (larger)
            GestureDetector(
              onTap: () => _showStopConfirmation(context),
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.error.withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.stop_rounded,
                  color: Colors.white,
                  size: 36,
                ),
              ),
            ),
            // Music button
            _ControlButton(
              icon: Icons.music_note_rounded,
              label: 'Music',
              color: AppColors.purple,
              onTap: () => context.go('/spotify'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPausedControls(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.pause_rounded, color: AppColors.accent, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Paused',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Resume button
            _ControlButton(
              icon: Icons.play_arrow_rounded,
              label: 'Resume',
              color: AppColors.primary,
              onTap: () => context.read<MapBloc>().add(MapResumeTracking()),
            ),
            // Stop button
            _ControlButton(
              icon: Icons.stop_rounded,
              label: 'Stop',
              color: AppColors.error,
              onTap: () => _showStopConfirmation(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showStopConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('End Walk?'),
        content: const Text(
          'Are you sure you want to end this walk? Your progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<MapBloc>().add(MapStopTracking());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('End Walk'),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
