import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/models/spotify_models.dart';
import '../../../services/spotify_service.dart';

// Events
abstract class SpotifyEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SpotifyConnectRequested extends SpotifyEvent {}

class SpotifyDisconnectRequested extends SpotifyEvent {}

class SpotifyLoadPlaylists extends SpotifyEvent {}

class SpotifyLoadPlaylistTracks extends SpotifyEvent {
  final String playlistId;

  SpotifyLoadPlaylistTracks({required this.playlistId});

  @override
  List<Object?> get props => [playlistId];
}

class SpotifyPlayTrack extends SpotifyEvent {
  final String uri;
  final String? contextUri;

  SpotifyPlayTrack({required this.uri, this.contextUri});

  @override
  List<Object?> get props => [uri, contextUri];
}

class SpotifyPause extends SpotifyEvent {}

class SpotifyResume extends SpotifyEvent {}

class SpotifySkipNext extends SpotifyEvent {}

class SpotifySkipPrevious extends SpotifyEvent {}

class SpotifySeekTo extends SpotifyEvent {
  final int positionMs;

  SpotifySeekTo({required this.positionMs});

  @override
  List<Object?> get props => [positionMs];
}

class SpotifyPlayerStateUpdated extends SpotifyEvent {
  final SpotifyPlayerState playerState;

  SpotifyPlayerStateUpdated({required this.playerState});

  @override
  List<Object?> get props => [playerState];
}

// States
abstract class SpotifyState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SpotifyInitial extends SpotifyState {}

class SpotifyLoading extends SpotifyState {}

class SpotifyDisconnected extends SpotifyState {
  final String? errorMessage;

  SpotifyDisconnected({this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}

class SpotifyConnected extends SpotifyState {
  final List<SpotifyPlaylist> playlists;
  final SpotifyPlaylist? selectedPlaylist;
  final SpotifyPlayerState playerState;
  final bool isLoadingTracks;

  SpotifyConnected({
    this.playlists = const [],
    this.selectedPlaylist,
    this.playerState = const SpotifyPlayerState(),
    this.isLoadingTracks = false,
  });

  SpotifyConnected copyWith({
    List<SpotifyPlaylist>? playlists,
    SpotifyPlaylist? selectedPlaylist,
    SpotifyPlayerState? playerState,
    bool? isLoadingTracks,
  }) {
    return SpotifyConnected(
      playlists: playlists ?? this.playlists,
      selectedPlaylist: selectedPlaylist ?? this.selectedPlaylist,
      playerState: playerState ?? this.playerState,
      isLoadingTracks: isLoadingTracks ?? this.isLoadingTracks,
    );
  }

  @override
  List<Object?> get props =>
      [playlists, selectedPlaylist, playerState, isLoadingTracks];
}

class SpotifyError extends SpotifyState {
  final String message;

  SpotifyError({required this.message});

  @override
  List<Object?> get props => [message];
}

// BLoC
class SpotifyBloc extends Bloc<SpotifyEvent, SpotifyState> {
  final SpotifyService spotifyService;
  StreamSubscription<SpotifyPlayerState>? _playerStateSubscription;

  SpotifyBloc({required this.spotifyService}) : super(SpotifyInitial()) {
    on<SpotifyConnectRequested>(_onConnectRequested);
    on<SpotifyDisconnectRequested>(_onDisconnectRequested);
    on<SpotifyLoadPlaylists>(_onLoadPlaylists);
    on<SpotifyLoadPlaylistTracks>(_onLoadPlaylistTracks);
    on<SpotifyPlayTrack>(_onPlayTrack);
    on<SpotifyPause>(_onPause);
    on<SpotifyResume>(_onResume);
    on<SpotifySkipNext>(_onSkipNext);
    on<SpotifySkipPrevious>(_onSkipPrevious);
    on<SpotifySeekTo>(_onSeekTo);
    on<SpotifyPlayerStateUpdated>(_onPlayerStateUpdated);
  }

  Future<void> _onConnectRequested(
    SpotifyConnectRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    emit(SpotifyLoading());

    try {
      print('[SpotifyBloc] Starting Spotify connection...');
      final connected = await spotifyService.connect();

      if (connected) {
        print('[SpotifyBloc] Successfully connected to Spotify');
        _subscribeToPlayerState();
        // Load playlists after successful connection
        final playlists = await spotifyService.getPlaylists();
        final playerState = await spotifyService.getPlayerState();

        emit(SpotifyConnected(
          playlists: playlists,
          playerState: playerState ?? const SpotifyPlayerState(),
        ));
      } else {
        final errorMsg =
            spotifyService.lastError ?? 'Failed to connect to Spotify';
        print('[SpotifyBloc] Connection failed: $errorMsg');
        emit(SpotifyDisconnected(errorMessage: errorMsg));
      }
    } catch (e) {
      print('[SpotifyBloc] Connection error: $e');
      emit(SpotifyDisconnected(
          errorMessage: 'Connection error: ${e.toString()}'));
    }
  }

  Future<void> _onDisconnectRequested(
    SpotifyDisconnectRequested event,
    Emitter<SpotifyState> emit,
  ) async {
    await spotifyService.disconnect();
    await _playerStateSubscription?.cancel();
    emit(SpotifyDisconnected());
  }

  Future<void> _onLoadPlaylists(
    SpotifyLoadPlaylists event,
    Emitter<SpotifyState> emit,
  ) async {
    print(
        '[SpotifyBloc] Loading playlists, isConnected=${spotifyService.isConnected}');

    // Check if connected first
    if (!spotifyService.isConnected) {
      print('[SpotifyBloc] Not connected, showing disconnected state');
      emit(SpotifyDisconnected());
      return;
    }

    emit(SpotifyLoading());

    try {
      final playlists = await spotifyService.getPlaylists();
      final playerState = await spotifyService.getPlayerState();

      print('[SpotifyBloc] Loaded ${playlists.length} playlists');

      _subscribeToPlayerState();

      emit(SpotifyConnected(
        playlists: playlists,
        playerState: playerState ?? const SpotifyPlayerState(),
      ));
    } catch (e) {
      print('[SpotifyBloc] Failed to load playlists: $e');
      emit(SpotifyDisconnected(
          errorMessage: 'Failed to load playlists: ${e.toString()}'));
    }
  }

  Future<void> _onLoadPlaylistTracks(
    SpotifyLoadPlaylistTracks event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    emit(currentState.copyWith(isLoadingTracks: true));

    try {
      final tracks = await spotifyService.getPlaylistTracks(event.playlistId);

      final playlist = currentState.playlists.firstWhere(
        (p) => p.id == event.playlistId,
      );

      final updatedPlaylist = playlist.copyWith(tracks: tracks);

      emit(currentState.copyWith(
        selectedPlaylist: updatedPlaylist,
        isLoadingTracks: false,
      ));
    } catch (e) {
      emit(currentState.copyWith(isLoadingTracks: false));
    }
  }

  Future<void> _onPlayTrack(
    SpotifyPlayTrack event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    try {
      await spotifyService.play(uri: event.uri, contextUri: event.contextUri);
    } catch (e) {
      print('[SpotifyBloc] Failed to play track: $e');
    }
  }

  Future<void> _onPause(
    SpotifyPause event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    try {
      await spotifyService.pause();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onResume(
    SpotifyResume event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    try {
      await spotifyService.resume();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onSkipNext(
    SpotifySkipNext event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    try {
      await spotifyService.skipNext();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onSkipPrevious(
    SpotifySkipPrevious event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    try {
      await spotifyService.skipPrevious();
    } catch (e) {
      // Silent fail
    }
  }

  Future<void> _onSeekTo(
    SpotifySeekTo event,
    Emitter<SpotifyState> emit,
  ) async {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    try {
      await spotifyService.seekTo(event.positionMs);
    } catch (e) {
      // Silent fail
    }
  }

  void _onPlayerStateUpdated(
    SpotifyPlayerStateUpdated event,
    Emitter<SpotifyState> emit,
  ) {
    final currentState = state;
    if (currentState is! SpotifyConnected) return;

    emit(currentState.copyWith(playerState: event.playerState));
  }

  void _subscribeToPlayerState() {
    _playerStateSubscription?.cancel();
    _playerStateSubscription = spotifyService.playerStateStream.listen((state) {
      add(SpotifyPlayerStateUpdated(playerState: state));
    });
  }

  @override
  Future<void> close() {
    _playerStateSubscription?.cancel();
    return super.close();
  }
}
