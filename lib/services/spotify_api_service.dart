import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';
import '../data/models/spotify_models.dart';
import 'spotify_auth_service.dart';

/// Spotify API Service for fetching user data, playlists, and tracks
class SpotifyApiService {
  final SpotifyAuthService _authService;

  final _playerStateController =
      StreamController<SpotifyPlayerState>.broadcast();
  Stream<SpotifyPlayerState> get playerStateStream =>
      _playerStateController.stream;

  SpotifyApiService({required SpotifyAuthService authService})
      : _authService = authService;

  /// Check if connected to Spotify
  Future<bool> get isConnected async {
    final token = await _authService.getAccessToken();
    return token != null;
  }

  /// Get authenticated HTTP headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getAccessToken();
    if (token == null) {
      throw SpotifyApiException('Not authenticated with Spotify');
    }
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  /// Make authenticated GET request
  Future<dynamic> _get(String endpoint) async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.spotifyApiBaseUrl}$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else if (response.statusCode == 401) {
      // Token expired, try to refresh
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed) {
        return await _get(endpoint);
      }
      throw SpotifyApiException('Authentication expired');
    } else {
      throw SpotifyApiException('API request failed: ${response.statusCode}');
    }
  }

  /// Make authenticated PUT request
  Future<void> _put(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getAuthHeaders();
    final response = await http.put(
      Uri.parse('${AppConstants.spotifyApiBaseUrl}$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed) {
        await _put(endpoint, body: body);
        return;
      }
      throw SpotifyApiException('Authentication expired');
    } else if (response.statusCode >= 400) {
      throw SpotifyApiException('API request failed: ${response.statusCode}');
    }
  }

  /// Make authenticated POST request
  Future<dynamic> _post(String endpoint, {Map<String, dynamic>? body}) async {
    final headers = await _getAuthHeaders();
    final response = await http.post(
      Uri.parse('${AppConstants.spotifyApiBaseUrl}$endpoint'),
      headers: headers,
      body: body != null ? json.encode(body) : null,
    );

    if (response.statusCode == 401) {
      final refreshed = await _authService.refreshAccessToken();
      if (refreshed) {
        return await _post(endpoint, body: body);
      }
      throw SpotifyApiException('Authentication expired');
    } else if (response.statusCode >= 400) {
      throw SpotifyApiException('API request failed: ${response.statusCode}');
    }

    if (response.body.isNotEmpty) {
      return json.decode(response.body);
    }
    return null;
  }

  /// Initiate OAuth connection
  Future<bool> connect() async {
    final result = await _authService.authenticate();
    return result.isSuccess;
  }

  /// Get current user's profile
  Future<Map<String, dynamic>> getCurrentUser() async {
    final data = await _get('/me');
    return data as Map<String, dynamic>;
  }

  /// Get user's playlists
  Future<List<SpotifyPlaylist>> getPlaylists(
      {int limit = 50, int offset = 0}) async {
    final data = await _get('/me/playlists?limit=$limit&offset=$offset');
    final items = data['items'] as List;
    return items.map((item) => SpotifyPlaylist.fromJson(item)).toList();
  }

  /// Get playlist tracks
  Future<List<SpotifyTrack>> getPlaylistTracks(String playlistId,
      {int limit = 100, int offset = 0}) async {
    final data =
        await _get('/playlists/$playlistId/tracks?limit=$limit&offset=$offset');
    final items = data['items'] as List;
    return items
        .where((item) => item['track'] != null)
        .map((item) => SpotifyTrack.fromJson(item['track']))
        .toList();
  }

  /// Get user's saved tracks (liked songs)
  Future<List<SpotifyTrack>> getSavedTracks(
      {int limit = 50, int offset = 0}) async {
    final data = await _get('/me/tracks?limit=$limit&offset=$offset');
    final items = data['items'] as List;
    return items.map((item) => SpotifyTrack.fromJson(item['track'])).toList();
  }

  /// Get current playback state
  Future<SpotifyPlayerState?> getPlayerState() async {
    try {
      final data = await _get('/me/player');
      if (data == null) return null;

      final state = SpotifyPlayerState.fromJson(data);
      _playerStateController.add(state);
      return state;
    } catch (e) {
      return null;
    }
  }

  /// Get currently playing track
  Future<SpotifyPlayerState?> getCurrentlyPlaying() async {
    try {
      final data = await _get('/me/player/currently-playing');
      if (data == null) return null;

      final state = SpotifyPlayerState.fromJson(data);
      _playerStateController.add(state);
      return state;
    } catch (e) {
      return null;
    }
  }

  /// Start/resume playback
  Future<void> play({String? uri, String? contextUri}) async {
    final body = <String, dynamic>{};
    if (contextUri != null) {
      body['context_uri'] = contextUri;
    }
    if (uri != null) {
      body['uris'] = [uri];
    }
    await _put('/me/player/play', body: body.isNotEmpty ? body : null);
  }

  /// Pause playback
  Future<void> pause() async {
    await _put('/me/player/pause');
  }

  /// Skip to next track
  Future<void> skipNext() async {
    await _post('/me/player/next');
  }

  /// Skip to previous track
  Future<void> skipPrevious() async {
    await _post('/me/player/previous');
  }

  /// Seek to position
  Future<void> seekTo(int positionMs) async {
    await _put('/me/player/seek?position_ms=$positionMs');
  }

  /// Set volume
  Future<void> setVolume(int volumePercent) async {
    await _put('/me/player/volume?volume_percent=$volumePercent');
  }

  /// Toggle shuffle
  Future<void> setShuffle(bool state) async {
    await _put('/me/player/shuffle?state=$state');
  }

  /// Set repeat mode ('track', 'context', 'off')
  Future<void> setRepeat(String state) async {
    await _put('/me/player/repeat?state=$state');
  }

  /// Get available devices
  Future<List<SpotifyDevice>> getAvailableDevices() async {
    final data = await _get('/me/player/devices');
    final devices = data['devices'] as List;
    return devices.map((d) => SpotifyDevice.fromJson(d)).toList();
  }

  /// Transfer playback to a device
  Future<void> transferPlayback(String deviceId, {bool play = false}) async {
    await _put('/me/player', body: {
      'device_ids': [deviceId],
      'play': play,
    });
  }

  /// Search for tracks, albums, artists, playlists
  Future<SpotifySearchResult> search(String query,
      {List<String>? types, int limit = 20}) async {
    final searchTypes = types ?? ['track', 'album', 'artist', 'playlist'];
    final typeParam = searchTypes.join(',');
    final data = await _get(
        '/search?q=${Uri.encodeComponent(query)}&type=$typeParam&limit=$limit');
    return SpotifySearchResult.fromJson(data);
  }

  void dispose() {
    _playerStateController.close();
  }
}

/// Exception for Spotify API errors
class SpotifyApiException implements Exception {
  final String message;
  SpotifyApiException(this.message);

  @override
  String toString() => 'SpotifyApiException: $message';
}

/// Spotify user model
class SpotifyUser {
  final String id;
  final String displayName;
  final String? email;
  final String? imageUrl;
  final String? country;
  final String? product;

  SpotifyUser({
    required this.id,
    required this.displayName,
    this.email,
    this.imageUrl,
    this.country,
    this.product,
  });

  factory SpotifyUser.fromJson(Map<String, dynamic> json) {
    final images = json['images'] as List?;
    return SpotifyUser(
      id: json['id'],
      displayName: json['display_name'] ?? 'Unknown',
      email: json['email'],
      imageUrl: images?.isNotEmpty == true ? images!.first['url'] : null,
      country: json['country'],
      product: json['product'],
    );
  }
}

/// Spotify device model
class SpotifyDevice {
  final String id;
  final String name;
  final String type;
  final bool isActive;
  final bool isRestricted;
  final int? volumePercent;

  SpotifyDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.isActive,
    required this.isRestricted,
    this.volumePercent,
  });

  factory SpotifyDevice.fromJson(Map<String, dynamic> json) {
    return SpotifyDevice(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      isActive: json['is_active'] ?? false,
      isRestricted: json['is_restricted'] ?? false,
      volumePercent: json['volume_percent'],
    );
  }
}

/// Spotify search result model
class SpotifySearchResult {
  final List<SpotifyTrack> tracks;
  final List<SpotifyPlaylist> playlists;

  SpotifySearchResult({
    required this.tracks,
    required this.playlists,
  });

  factory SpotifySearchResult.fromJson(Map<String, dynamic> json) {
    final tracksData = json['tracks']?['items'] as List? ?? [];
    final playlistsData = json['playlists']?['items'] as List? ?? [];

    return SpotifySearchResult(
      tracks: tracksData.map((t) => SpotifyTrack.fromJson(t)).toList(),
      playlists: playlistsData.map((p) => SpotifyPlaylist.fromJson(p)).toList(),
    );
  }
}
