import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../bloc/spotify_bloc.dart';
import '../../../data/models/spotify_models.dart';
import '../../../widgets/buttons/soft_button.dart';

class SpotifyScreen extends StatefulWidget {
  const SpotifyScreen({super.key});

  @override
  State<SpotifyScreen> createState() => _SpotifyScreenState();
}

class _SpotifyScreenState extends State<SpotifyScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SpotifyBloc>().add(SpotifyLoadPlaylists());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocConsumer<SpotifyBloc, SpotifyState>(
          listener: (context, state) {
            // Show error message if disconnected with error
            if (state is SpotifyDisconnected && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is SpotifyDisconnected || state is SpotifyInitial) {
              return _buildConnectView(context);
            }

            if (state is SpotifyLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is SpotifyConnected) {
              return _buildConnectedView(context, state);
            }

            if (state is SpotifyError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        state.message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context
                          .read<SpotifyBloc>()
                          .add(SpotifyConnectRequested()),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            return _buildConnectView(context);
          },
        ),
      ),
    );
  }

  Widget _buildConnectView(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Spotify icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 60,
              color: Color(0xFF1DB954),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 32),
          Text(
            'Connect Spotify',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          Text(
            'Listen to your favorite music while you walk. Control playback without leaving the app.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 48),
          SoftButton(
            text: 'Connect to Spotify',
            onPressed: () =>
                context.read<SpotifyBloc>().add(SpotifyConnectRequested()),
            backgroundColor: const Color(0xFF1DB954),
            width: double.infinity,
          ).animate().fadeIn(delay: 300.ms),
        ],
      ),
    );
  }

  Widget _buildConnectedView(BuildContext context, SpotifyConnected state) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Music',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1DB954),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Connected to Spotify',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () => context
                    .read<SpotifyBloc>()
                    .add(SpotifyDisconnectRequested()),
              ),
            ],
          ).animate().fadeIn(),
        ),
        // Now Playing
        if (state.playerState.isPlaying)
          _NowPlayingCard(playerState: state.playerState)
              .animate()
              .fadeIn(delay: 100.ms),
        // Playlists
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Your Playlists',
                  style: Theme.of(context).textTheme.titleLarge,
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                Expanded(
                  child: state.playlists.isEmpty
                      ? Center(
                          child: Text(
                            'No playlists found',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: state.playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = state.playlists[index];
                            return _PlaylistCard(
                              playlist: playlist,
                              onTap: () => context.read<SpotifyBloc>().add(
                                  SpotifyLoadPlaylistTracks(
                                      playlistId: playlist.id)),
                            ).animate().fadeIn(
                                delay: Duration(milliseconds: 100 * index));
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        // Mini Player
        _MiniPlayer(
          playerState: state.playerState,
          onPlayPause: () {
            if (state.playerState.isPlaying) {
              context.read<SpotifyBloc>().add(SpotifyPause());
            } else {
              context.read<SpotifyBloc>().add(SpotifyResume());
            }
          },
          onNext: () => context.read<SpotifyBloc>().add(SpotifySkipNext()),
          onPrevious: () =>
              context.read<SpotifyBloc>().add(SpotifySkipPrevious()),
        ),
      ],
    );
  }
}

class _NowPlayingCard extends StatelessWidget {
  final SpotifyPlayerState playerState;

  const _NowPlayingCard({required this.playerState});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1DB954),
            const Color(0xFF1DB954).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DB954).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Album art
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: playerState.currentTrack?.albumImageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      playerState.currentTrack!.albumImageUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    Icons.music_note_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 16),
          // Track info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NOW PLAYING',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  playerState.currentTrack?.name ?? 'Unknown Track',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  playerState.currentTrack?.artistName ?? 'Unknown Artist',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Equalizer animation
          Row(
            children: List.generate(3, (index) {
              return Container(
                width: 3,
                height: 20 - (index * 5),
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  final SpotifyPlaylist playlist;
  final VoidCallback onTap;

  const _PlaylistCard({
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Playlist image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: playlist.imageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16)),
                        child: Image.network(
                          playlist.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.music_note_rounded,
                          size: 40,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                      ),
              ),
            ),
            // Playlist info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${playlist.trackCount} tracks',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final SpotifyPlayerState playerState;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  const _MiniPlayer({
    required this.playerState,
    required this.onPlayPause,
    required this.onNext,
    required this.onPrevious,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
            // Progress bar
            LinearProgressIndicator(
              value: playerState.progress,
              backgroundColor: AppColors.divider,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF1DB954)),
              minHeight: 2,
            ),
            const SizedBox(height: 12),
            // Track info and controls
            Row(
              children: [
                // Album art
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: playerState.currentTrack?.albumImageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            playerState.currentTrack!.albumImageUrl!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.music_note_rounded,
                          color: AppColors.textSecondary,
                        ),
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playerState.currentTrack?.name ?? 'Unknown Track',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        playerState.currentTrack?.artistName ??
                            'Unknown Artist',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Controls
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: onPrevious,
                      iconSize: 28,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1DB954),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          playerState.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        onPressed: onPlayPause,
                        iconSize: 28,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: onNext,
                      iconSize: 28,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.5);
  }
}
