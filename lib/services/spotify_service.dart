import 'dart:async';

import '../data/models/spotify_models.dart';
import 'spotify_auth_service.dart';
import 'spotify_api_service.dart';

/// SpotifyService acts as a facade for Spotify functionality.
/// It delegates to SpotifyAuthService for authentication and
/// SpotifyApiService for API calls.
class SpotifyService {
  final SpotifyAuthService _authService;
  final SpotifyApiService _apiService;

  // For demo/fallback when real API fails
  bool _useMockData = false;

  final _playerStateController =
      StreamController<SpotifyPlayerState>.broadcast();
  Stream<SpotifyPlayerState> get playerStateStream =>
      _playerStateController.stream;

  SpotifyService({
    SpotifyAuthService? authService,
    SpotifyApiService? apiService,
  })  : _authService = authService ?? SpotifyAuthService(),
        _apiService = apiService ??
            SpotifyApiService(
              authService: authService ?? SpotifyAuthService(),
            ) {
    // Forward player state from API service
    _apiService.playerStateStream.listen((state) {
      _playerStateController.add(state);
    });
  }

  bool get isConnected => _authService.isAuthenticated || _useMockData;

  /// Connect to Spotify using OAuth PKCE flow
  Future<bool> connect() async {
    try {
      final connected = await _apiService.connect();
      if (connected) {
        _useMockData = false;
        return true;
      }
    } catch (e) {
      print('Spotify connection error: $e');
    }

    // Fallback to mock data for demo purposes
    _useMockData = true;
    return true;
  }

  /// Disconnect from Spotify and clear tokens
  Future<void> disconnect() async {
    await _authService.logout();
    _useMockData = false;
  }

  /// Get user's playlists
  Future<List<SpotifyPlaylist>> getPlaylists() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _getMockPlaylists();
    }

    try {
      return await _apiService.getPlaylists();
    } catch (e) {
      print('Failed to fetch playlists: $e');
      return _getMockPlaylists();
    }
  }

  /// Get playlist tracks
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _getMockTracks();
    }

    try {
      return await _apiService.getPlaylistTracks(playlistId);
    } catch (e) {
      print('Failed to fetch playlist tracks: $e');
      return _getMockTracks();
    }
  }

  /// Get current playback state
  Future<SpotifyPlayerState?> getPlayerState() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      final state = SpotifyPlayerState(
        isPlaying: false,
        currentTrack: _getMockTracks().first,
        progressMs: 0,
        durationMs: _getMockTracks().first.durationMs,
      );
      _playerStateController.add(state);
      return state;
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
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      final track = _getMockTracks().first;
      _playerStateController.add(SpotifyPlayerState(
        isPlaying: true,
        currentTrack: track,
        progressMs: 0,
        durationMs: track.durationMs,
      ));
      return;
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
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      final track = _getMockTracks().first;
      _playerStateController.add(SpotifyPlayerState(
        isPlaying: false,
        currentTrack: track,
        progressMs: 30000,
        durationMs: track.durationMs,
      ));
      return;
    }

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
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      final tracks = _getMockTracks();
      final track = tracks.length > 1 ? tracks[1] : tracks.first;
      _playerStateController.add(SpotifyPlayerState(
        isPlaying: true,
        currentTrack: track,
        progressMs: 0,
        durationMs: track.durationMs,
      ));
      return;
    }

    try {
      await _apiService.skipNext();
    } catch (e) {
      print('Failed to skip next: $e');
    }
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 200));
      final track = _getMockTracks().last;
      _playerStateController.add(SpotifyPlayerState(
        isPlaying: true,
        currentTrack: track,
        progressMs: 0,
        durationMs: track.durationMs,
      ));
      return;
    }

    try {
      await _apiService.skipPrevious();
    } catch (e) {
      print('Failed to skip previous: $e');
    }
  }

  /// Seek to position
  Future<void> seekTo(int positionMs) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    try {
      await _apiService.seekTo(positionMs);
    } catch (e) {
      print('Failed to seek: $e');
    }
  }

  /// Set volume (0.0 to 1.0)
  Future<void> setVolume(double volume) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    try {
      await _apiService.setVolume((volume * 100).round());
    } catch (e) {
      print('Failed to set volume: $e');
    }
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle(bool enabled) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

    try {
      await _apiService.setShuffle(enabled);
    } catch (e) {
      print('Failed to toggle shuffle: $e');
    }
  }

  /// Set repeat mode: 'off', 'context', 'track'
  Future<void> setRepeatMode(String mode) async {
    if (_useMockData) {
      await Future.delayed(const Duration(milliseconds: 100));
      return;
    }

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
      await _authService.exchangeCodeForToken(code);
      _useMockData = false;
      return true;
    } catch (e) {
      print('Failed to handle auth callback: $e');
      return false;
    }
  }

  // Mock data generators for demo/fallback
  List<SpotifyPlaylist> _getMockPlaylists() {
    return [
      SpotifyPlaylist(
        id: '1',
        name: 'Running Hits 🏃',
        description: 'High energy tracks for your run',
        imageUrl:
            'https://i.scdn.co/image/ab67616d0000b273e8e28219724c2423afa4d320',
        trackCount: 50,
        ownerName: 'Spotify',
        tracks: _getMockTracks(),
      ),
      SpotifyPlaylist(
        id: '2',
        name: 'Workout Motivation',
        description: 'Push your limits',
        imageUrl:
            'https://i.scdn.co/image/ab67616d0000b273bd26ede1ae69327010d49946',
        trackCount: 35,
        ownerName: 'Fitness Music',
        tracks: [],
      ),
      SpotifyPlaylist(
        id: '3',
        name: 'Morning Walk',
        description: 'Peaceful tracks for your morning routine',
        imageUrl:
            'https://i.scdn.co/image/ab67616d0000b2731dc7483a9fcb765b7d9c7fac',
        trackCount: 28,
        ownerName: 'You',
        tracks: [],
      ),
      SpotifyPlaylist(
        id: '4',
        name: 'Power Walk Mix',
        description: 'Keep the pace with these energetic beats',
        imageUrl:
            'https://i.scdn.co/image/ab67616d0000b273b55ed804279d5ef2f5568e3c',
        trackCount: 42,
        ownerName: 'Workout Beats',
        tracks: [],
      ),
      SpotifyPlaylist(
        id: '5',
        name: 'Cardio Hits',
        description: 'Top cardio tracks',
        imageUrl:
            'https://i.scdn.co/image/ab67616d0000b273570f746a3b68d6e3c8c20c87',
        trackCount: 60,
        ownerName: 'Spotify',
        tracks: [],
      ),
    ];
  }

  List<SpotifyTrack> _getMockTracks() {
    return [
      const SpotifyTrack(
        id: 't1',
        name: 'Eye of the Tiger',
        artistName: 'Survivor',
        albumName: 'Eye of the Tiger',
        albumImageUrl:
            'https://i.scdn.co/image/ab67616d0000b273e8e28219724c2423afa4d320',
        durationMs: 245000,
        uri: 'spotify:track:2KH16WveTQWT6KOG9Rg6e2',
      ),
      const SpotifyTrack(
        id: 't2',
        name: 'Stronger',
        artistName: 'Kanye West',
        albumName: 'Graduation',
        albumImageUrl:
            'https://i.scdn.co/image/ab67616d0000b273bd26ede1ae69327010d49946',
        durationMs: 312000,
        uri: 'spotify:track:4fzsfWzRhPawzqhX8Qt9F3',
      ),
      const SpotifyTrack(
        id: 't3',
        name: "Can't Hold Us",
        artistName: 'Macklemore & Ryan Lewis',
        albumName: 'The Heist',
        albumImageUrl:
            'https://i.scdn.co/image/ab67616d0000b2731dc7483a9fcb765b7d9c7fac',
        durationMs: 258000,
        uri: 'spotify:track:3bidbhpOYeV4knp8AIu8Xn',
      ),
      const SpotifyTrack(
        id: 't4',
        name: 'Till I Collapse',
        artistName: 'Eminem',
        albumName: 'The Eminem Show',
        albumImageUrl:
            'https://i.scdn.co/image/ab67616d0000b273b55ed804279d5ef2f5568e3c',
        durationMs: 298000,
        uri: 'spotify:track:7w9bgPAmPTtrkt2v16LWxS',
      ),
      const SpotifyTrack(
        id: 't5',
        name: 'Lose Yourself',
        artistName: 'Eminem',
        albumName: '8 Mile',
        albumImageUrl:
            'https://i.scdn.co/image/ab67616d0000b273570f746a3b68d6e3c8c20c87',
        durationMs: 326000,
        uri: 'spotify:track:1v7L65Lc0cJJr8xBXsHKxe',
      ),
    ];
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
