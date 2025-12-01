import 'package:equatable/equatable.dart';

class SpotifyPlaylist extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final int trackCount;
  final String ownerName;
  final List<SpotifyTrack> tracks;

  const SpotifyPlaylist({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.trackCount = 0,
    required this.ownerName,
    this.tracks = const [],
  });

  SpotifyPlaylist copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? trackCount,
    String? ownerName,
    List<SpotifyTrack>? tracks,
  }) {
    return SpotifyPlaylist(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      trackCount: trackCount ?? this.trackCount,
      ownerName: ownerName ?? this.ownerName,
      tracks: tracks ?? this.tracks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'trackCount': trackCount,
      'ownerName': ownerName,
      'tracks': tracks.map((t) => t.toJson()).toList(),
    };
  }

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    // Handle Spotify API response format
    final images = json['images'] as List?;
    String? imageUrl;
    if (images != null && images.isNotEmpty) {
      imageUrl = images[0]['url'] as String?;
    }

    final owner = json['owner'] as Map<String, dynamic>?;
    final ownerName = owner?['display_name'] as String? ?? 'Unknown';

    final tracksData = json['tracks'] as Map<String, dynamic>?;
    final trackCount = tracksData?['total'] as int? ?? 0;

    return SpotifyPlaylist(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: imageUrl ?? json['imageUrl'] as String?,
      trackCount: trackCount,
      ownerName: ownerName,
      tracks: (json['trackItems'] as List?)
              ?.map((t) => SpotifyTrack.fromJson(t as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        imageUrl,
        trackCount,
        ownerName,
        tracks,
      ];
}

class SpotifyTrack extends Equatable {
  final String id;
  final String name;
  final String artistName;
  final String albumName;
  final String? albumImageUrl;
  final int durationMs;
  final String? previewUrl;
  final String uri;

  const SpotifyTrack({
    required this.id,
    required this.name,
    required this.artistName,
    required this.albumName,
    this.albumImageUrl,
    required this.durationMs,
    this.previewUrl,
    required this.uri,
  });

  SpotifyTrack copyWith({
    String? id,
    String? name,
    String? artistName,
    String? albumName,
    String? albumImageUrl,
    int? durationMs,
    String? previewUrl,
    String? uri,
  }) {
    return SpotifyTrack(
      id: id ?? this.id,
      name: name ?? this.name,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumImageUrl: albumImageUrl ?? this.albumImageUrl,
      durationMs: durationMs ?? this.durationMs,
      previewUrl: previewUrl ?? this.previewUrl,
      uri: uri ?? this.uri,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'artistName': artistName,
      'albumName': albumName,
      'albumImageUrl': albumImageUrl,
      'durationMs': durationMs,
      'previewUrl': previewUrl,
      'uri': uri,
    };
  }

  factory SpotifyTrack.fromJson(Map<String, dynamic> json) {
    // Handle Spotify API response format
    final track = json['track'] as Map<String, dynamic>? ?? json;

    final artists = track['artists'] as List?;
    final artistName = artists?.isNotEmpty == true
        ? (artists![0]['name'] as String? ?? 'Unknown Artist')
        : 'Unknown Artist';

    final album = track['album'] as Map<String, dynamic>?;
    final albumName = album?['name'] as String? ?? 'Unknown Album';

    final albumImages = album?['images'] as List?;
    String? albumImageUrl;
    if (albumImages != null && albumImages.isNotEmpty) {
      albumImageUrl = albumImages[0]['url'] as String?;
    }

    return SpotifyTrack(
      id: track['id'] as String,
      name: track['name'] as String,
      artistName: artistName,
      albumName: albumName,
      albumImageUrl: albumImageUrl ?? track['albumImageUrl'] as String?,
      durationMs:
          track['duration_ms'] as int? ?? track['durationMs'] as int? ?? 0,
      previewUrl:
          track['preview_url'] as String? ?? track['previewUrl'] as String?,
      uri: track['uri'] as String? ?? 'spotify:track:${track['id']}',
    );
  }

  // Format duration as mm:ss
  String get formattedDuration {
    final totalSeconds = durationMs ~/ 1000;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        artistName,
        albumName,
        albumImageUrl,
        durationMs,
        previewUrl,
        uri,
      ];
}

class SpotifyPlayerState extends Equatable {
  final bool isPlaying;
  final SpotifyTrack? currentTrack;
  final int progressMs;
  final int durationMs;
  final double volume;
  final bool shuffleEnabled;
  final String repeatMode; // 'off', 'context', 'track'

  const SpotifyPlayerState({
    this.isPlaying = false,
    this.currentTrack,
    this.progressMs = 0,
    this.durationMs = 0,
    this.volume = 1.0,
    this.shuffleEnabled = false,
    this.repeatMode = 'off',
  });

  SpotifyPlayerState copyWith({
    bool? isPlaying,
    SpotifyTrack? currentTrack,
    int? progressMs,
    int? durationMs,
    double? volume,
    bool? shuffleEnabled,
    String? repeatMode,
  }) {
    return SpotifyPlayerState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentTrack: currentTrack ?? this.currentTrack,
      progressMs: progressMs ?? this.progressMs,
      durationMs: durationMs ?? this.durationMs,
      volume: volume ?? this.volume,
      shuffleEnabled: shuffleEnabled ?? this.shuffleEnabled,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }

  factory SpotifyPlayerState.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;

    return SpotifyPlayerState(
      isPlaying: json['is_playing'] as bool? ?? false,
      currentTrack:
          item != null ? SpotifyTrack.fromJson({'track': item}) : null,
      progressMs: json['progress_ms'] as int? ?? 0,
      durationMs: item?['duration_ms'] as int? ?? 0,
      volume: ((json['device'] as Map<String, dynamic>?)?['volume_percent']
                  as int? ??
              100) /
          100,
      shuffleEnabled: json['shuffle_state'] as bool? ?? false,
      repeatMode: json['repeat_state'] as String? ?? 'off',
    );
  }

  double get progress {
    if (durationMs == 0) return 0;
    return progressMs / durationMs;
  }

  @override
  List<Object?> get props => [
        isPlaying,
        currentTrack,
        progressMs,
        durationMs,
        volume,
        shuffleEnabled,
        repeatMode,
      ];
}
