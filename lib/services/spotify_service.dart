import 'dart:async';

import '../data/models/spotify_models.dart';

class SpotifyService {
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  final _playerStateController =
      StreamController<SpotifyPlayerState>.broadcast();
  Stream<SpotifyPlayerState> get playerStateStream =>
      _playerStateController.stream;

  bool get isConnected => _accessToken != null && !_isTokenExpired;

  bool get _isTokenExpired {
    if (_tokenExpiry == null) return true;
    return DateTime.now().isAfter(_tokenExpiry!);
  }

  // Connect to Spotify (OAuth flow)
  Future<bool> connect() async {
    // In a real app, this would use flutter_web_auth_2 for OAuth
    // For demo purposes, we'll simulate a successful connection

    await Future.delayed(const Duration(seconds: 1));

    // Simulate getting tokens
    _accessToken = 'demo_access_token';
    _refreshToken = 'demo_refresh_token';
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

    return true;
  }

  // Disconnect from Spotify
  Future<void> disconnect() async {
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
  }

  // Refresh access token
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    // In a real app, this would call Spotify's token refresh endpoint
    await Future.delayed(const Duration(milliseconds: 500));

    _accessToken = 'refreshed_access_token';
    _tokenExpiry = DateTime.now().add(const Duration(hours: 1));

    return true;
  }

  // Get user's playlists
  Future<List<SpotifyPlaylist>> getPlaylists() async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    // In a real app, this would fetch from Spotify API
    // For demo, return mock data
    await Future.delayed(const Duration(milliseconds: 500));

    return _getMockPlaylists();
  }

  // Get playlist tracks
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 300));

    return _getMockTracks();
  }

  // Get current playback state
  Future<SpotifyPlayerState?> getPlayerState() async {
    if (!isConnected) return null;

    await Future.delayed(const Duration(milliseconds: 200));

    // Return mock player state
    final state = SpotifyPlayerState(
      isPlaying: false,
      currentTrack: _getMockTracks().first,
      progressMs: 0,
      durationMs: _getMockTracks().first.durationMs,
    );

    _playerStateController.add(state);
    return state;
  }

  // Play a track or playlist
  Future<void> play({String? uri, String? contextUri}) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 200));

    final track = _getMockTracks().first;
    final state = SpotifyPlayerState(
      isPlaying: true,
      currentTrack: track,
      progressMs: 0,
      durationMs: track.durationMs,
    );

    _playerStateController.add(state);
  }

  // Pause playback
  Future<void> pause() async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 100));

    final track = _getMockTracks().first;
    final state = SpotifyPlayerState(
      isPlaying: false,
      currentTrack: track,
      progressMs: 30000,
      durationMs: track.durationMs,
    );

    _playerStateController.add(state);
  }

  // Resume playback
  Future<void> resume() async {
    await play();
  }

  // Skip to next track
  Future<void> skipNext() async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 200));

    final tracks = _getMockTracks();
    final track = tracks.length > 1 ? tracks[1] : tracks.first;
    final state = SpotifyPlayerState(
      isPlaying: true,
      currentTrack: track,
      progressMs: 0,
      durationMs: track.durationMs,
    );

    _playerStateController.add(state);
  }

  // Skip to previous track
  Future<void> skipPrevious() async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 200));

    final track = _getMockTracks().last;
    final state = SpotifyPlayerState(
      isPlaying: true,
      currentTrack: track,
      progressMs: 0,
      durationMs: track.durationMs,
    );

    _playerStateController.add(state);
  }

  // Seek to position
  Future<void> seekTo(int positionMs) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Set volume
  Future<void> setVolume(double volume) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Toggle shuffle
  Future<void> toggleShuffle(bool enabled) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Set repeat mode
  Future<void> setRepeatMode(String mode) async {
    if (!isConnected) {
      throw SpotifyException('Not connected to Spotify');
    }

    await Future.delayed(const Duration(milliseconds: 100));
  }

  // Mock data generators
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
  }
}

class SpotifyException implements Exception {
  final String message;
  SpotifyException(this.message);

  @override
  String toString() => message;
}
