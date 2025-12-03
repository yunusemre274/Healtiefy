import 'dart:async';

import '../data/models/spotify_models.dart';
import 'spotify_auth_service.dart';
import 'spotify_api_service.dart';

/// SpotifyService acts as a facade for Spotify functionality.
/// It delegates to SpotifyAuthService for authentication and
/// SpotifyApiService for API calls.
class SpotifyService {
  final SpotifyAuthService _authService;
  late final SpotifyApiService _apiService;

  // Connection state tracking
  bool _isReallyConnected = false;
  String? _lastConnectionError;

  final _playerStateController =
      StreamController<SpotifyPlayerState>.broadcast();
  Stream<SpotifyPlayerState> get playerStateStream =>
      _playerStateController.stream;

  SpotifyService({
    required SpotifyAuthService authService,
    SpotifyApiService? apiService,
  }) : _authService = authService {
    _apiService = apiService ?? SpotifyApiService(authService: _authService);

    // Forward player state from API service
    _apiService.playerStateStream.listen((state) {
      _playerStateController.add(state);
    });

    // Check if already authenticated
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final hasTokens = await _authService.hasStoredTokens();
    if (hasTokens) {
      _isReallyConnected = true;
    }
  }

  bool get isConnected => _isReallyConnected && _authService.isAuthenticated;
  String? get lastError => _lastConnectionError;

  /// Connect to Spotify using OAuth PKCE flow
  Future<bool> connect() async {
    try {
      _lastConnectionError = null;
      final result = await _authService.authenticate();

      if (result.isSuccess) {
        _isReallyConnected = true;
        return true;
      } else {
        _lastConnectionError = result.errorMessage;
        _isReallyConnected = false;
        return false;
      }
    } catch (e) {
      _lastConnectionError = e.toString();
      _isReallyConnected = false;
      print('Spotify connection error: $e');
      return false;
    }
  }

  /// Disconnect from Spotify and clear tokens
  Future<void> disconnect() async {
    await _authService.logout();
    _isReallyConnected = false;
    _lastConnectionError = null;
  }

  /// Get user's playlists - returns empty list if not connected
  Future<List<SpotifyPlaylist>> getPlaylists() async {
    if (!isConnected) {
      return [];
    }

    try {
      return await _apiService.getPlaylists();
    } catch (e) {
      print('Failed to fetch playlists: $e');
      _lastConnectionError = e.toString();
      return [];
    }
  }

  /// Get playlist tracks
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId) async {
    if (!isConnected) {
      return [];
    }

    try {
      return await _apiService.getPlaylistTracks(playlistId);
    } catch (e) {
      print('Failed to fetch playlist tracks: $e');
      return [];
    }
  }

  /// Get current playback state
  Future<SpotifyPlayerState?> getPlayerState() async {
    if (!isConnected) {
      return null;
    }

    try {
      return await _apiService.getCurrentlyPlaying();
    } catch (e) {
      print('Failed to get player state: $e');
      return null;
    }
  }

  /// Play a track or playlist
  Future<void> play({String? uri, String? contextUri}) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    try {
      await _apiService.play(uri: uri, contextUri: contextUri);
    } catch (e) {
      print('Failed to play: $e');
      throw SpotifyException('Failed to play track');
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (!isConnected) return;

    try {
      await _apiService.pause();
    } catch (e) {
      print('Failed to pause: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    await play();
  }

  /// Skip to next track
  Future<void> skipNext() async {
    if (!isConnected) return;

    try {
      await _apiService.skipNext();
    } catch (e) {
      print('Failed to skip next: $e');
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (!isConnected) return;

    try {
      await _apiService.skipPrevious();
    } catch (e) {
      print('Failed to skip previous: $e');
    }
  }

  /// Seek to position
  Future<void> seekTo(int positionMs) async {
    if (!isConnected) return;

    try {
      await _apiService.seekTo(positionMs);
    } catch (e) {
      print('Failed to seek: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (!isConnected) return;

    try {
      await _apiService.setVolume((volume * 100).round());
    } catch (e) {
      print('Failed to set volume: $e');
    }
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle(bool enabled) async {
    if (!isConnected) return;

    try {
      await _apiService.setShuffle(enabled);
    } catch (e) {
      print('Failed to toggle shuffle: $e');
    }
  }

  /// Set repeat mode: 'off', 'context', 'track'
  Future<void> setRepeatMode(String mode) async {
    if (!isConnected) return;

    try {
      await _apiService.setRepeat(mode);
    } catch (e) {
      print('Failed to set repeat mode: $e');
    }
  }

  /// Get the authorization URL for manual OAuth flow
  String getAuthorizationUrl() {
    return _authService.buildAuthorizationUrl();
  }

  /// Handle OAuth callback with authorization code
  Future<bool> handleAuthCallback(String code) async {
    try {
      final result = await _authService.exchangeCodeForToken(code);
      if (result.isSuccess) {
        _isReallyConnected = true;
        return true;
      }
      _lastConnectionError = result.errorMessage;
      return false;
    } catch (e) {
      print('Failed to handle auth callback: $e');
      _lastConnectionError = e.toString();
      return false;
    }
  }

  void dispose() {
    _playerStateController.close();
    _apiService.dispose();
  }
}

class SpotifyException implements Exception {
  final String message;
  SpotifyException(this.message);

  @override
  String toString() => message;
}
