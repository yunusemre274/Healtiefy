import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;

import '../core/constants/app_constants.dart';

/// Spotify OAuth 2.0 with PKCE (Proof Key for Code Exchange) Service
class SpotifyAuthService {
  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _codeVerifier;

  SpotifyAuthService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Check if user is authenticated with Spotify
  bool get isAuthenticated =>
      _accessToken != null &&
      _expiresAt != null &&
      DateTime.now().isBefore(_expiresAt!);

  /// Get current access token (auto-refreshes if expired)
  Future<String?> getAccessToken() async {
    if (_accessToken == null) {
      await _loadTokensFromStorage();
    }

    if (_accessToken == null) return null;

    // Check if token is expired or about to expire (within 5 minutes)
    if (_expiresAt != null &&
        DateTime.now()
            .isAfter(_expiresAt!.subtract(const Duration(minutes: 5)))) {
      await refreshAccessToken();
    }

    return _accessToken;
  }

  /// Generate a cryptographically random code verifier for PKCE
  String generateCodeVerifier() {
    final random = Random.secure();
    final values = List<int>.generate(64, (_) => random.nextInt(256));
    _codeVerifier = base64UrlEncode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    return _codeVerifier!;
  }

  /// Generate code challenge from verifier using SHA-256
  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64UrlEncode(digest.bytes)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
  }

  /// Build the Spotify authorization URL with PKCE
  String buildAuthorizationUrl() {
    final verifier = generateCodeVerifier();
    final challenge = generateCodeChallenge(verifier);

    // Store verifier for later use
    _secureStorage.write(
        key: AppConstants.spotifyCodeVerifierKey, value: verifier);

    final params = {
      'client_id': AppConstants.spotifyClientId,
      'response_type': 'code',
      'redirect_uri': AppConstants.spotifyRedirectUri,
      'code_challenge_method': 'S256',
      'code_challenge': challenge,
      'scope': AppConstants.spotifyScopes.join(' '),
      'show_dialog': 'true',
    };

    final uri =
        Uri.parse(AppConstants.spotifyAuthUrl).replace(queryParameters: params);
    return uri.toString();
  }

  /// Start the OAuth flow and return tokens
  Future<SpotifyAuthResult> authenticate() async {
    try {
      final authUrl = buildAuthorizationUrl();

      // Open browser for Spotify login
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'healtiefy',
      );

      // Parse the callback URL
      final uri = Uri.parse(result);
      return await handleRedirectCallback(uri);
    } catch (e) {
      return SpotifyAuthResult.failure('Authentication failed: $e');
    }
  }

  /// Handle the redirect callback from Spotify
  Future<SpotifyAuthResult> handleRedirectCallback(Uri uri) async {
    final error = uri.queryParameters['error'];
    if (error != null) {
      return SpotifyAuthResult.failure('Spotify authorization error: $error');
    }

    final code = uri.queryParameters['code'];
    if (code == null) {
      return SpotifyAuthResult.failure('No authorization code received');
    }

    return await exchangeCodeForToken(code);
  }

  /// Exchange authorization code for access and refresh tokens
  Future<SpotifyAuthResult> exchangeCodeForToken(String code) async {
    try {
      // Retrieve the code verifier
      final verifier =
          await _secureStorage.read(key: AppConstants.spotifyCodeVerifierKey);
      if (verifier == null) {
        return SpotifyAuthResult.failure('Code verifier not found');
      }

      final response = await http.post(
        Uri.parse(AppConstants.spotifyTokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': AppConstants.spotifyRedirectUri,
          'client_id': AppConstants.spotifyClientId,
          'code_verifier': verifier,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(data);
        return SpotifyAuthResult.success(
          accessToken: _accessToken!,
          refreshToken: _refreshToken,
          expiresAt: _expiresAt!,
        );
      } else {
        final error = json.decode(response.body);
        return SpotifyAuthResult.failure(
            'Token exchange failed: ${error['error_description'] ?? error['error']}');
      }
    } catch (e) {
      return SpotifyAuthResult.failure('Token exchange error: $e');
    }
  }

  /// Refresh the access token using the refresh token
  Future<bool> refreshAccessToken() async {
    try {
      if (_refreshToken == null) {
        _refreshToken =
            await _secureStorage.read(key: AppConstants.spotifyRefreshTokenKey);
      }

      if (_refreshToken == null) {
        return false;
      }

      final response = await http.post(
        Uri.parse(AppConstants.spotifyTokenUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken,
          'client_id': AppConstants.spotifyClientId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(data);
        return true;
      } else {
        // If refresh fails, clear tokens
        await logout();
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  /// Save tokens to secure storage
  Future<void> _saveTokens(Map<String, dynamic> data) async {
    _accessToken = data['access_token'];
    _refreshToken = data['refresh_token'] ?? _refreshToken;

    final expiresIn = data['expires_in'] as int;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    await _secureStorage.write(
      key: AppConstants.spotifyAccessTokenKey,
      value: _accessToken,
    );

    if (_refreshToken != null) {
      await _secureStorage.write(
        key: AppConstants.spotifyRefreshTokenKey,
        value: _refreshToken,
      );
    }

    await _secureStorage.write(
      key: AppConstants.spotifyExpiresAtKey,
      value: _expiresAt!.toIso8601String(),
    );
  }

  /// Load tokens from secure storage
  Future<void> _loadTokensFromStorage() async {
    _accessToken =
        await _secureStorage.read(key: AppConstants.spotifyAccessTokenKey);
    _refreshToken =
        await _secureStorage.read(key: AppConstants.spotifyRefreshTokenKey);

    final expiresAtStr =
        await _secureStorage.read(key: AppConstants.spotifyExpiresAtKey);
    if (expiresAtStr != null) {
      _expiresAt = DateTime.parse(expiresAtStr);
    }
  }

  /// Check if tokens exist in storage
  Future<bool> hasStoredTokens() async {
    final token =
        await _secureStorage.read(key: AppConstants.spotifyAccessTokenKey);
    return token != null;
  }

  /// Logout and clear all tokens
  Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _expiresAt = null;
    _codeVerifier = null;

    await _secureStorage.delete(key: AppConstants.spotifyAccessTokenKey);
    await _secureStorage.delete(key: AppConstants.spotifyRefreshTokenKey);
    await _secureStorage.delete(key: AppConstants.spotifyExpiresAtKey);
    await _secureStorage.delete(key: AppConstants.spotifyCodeVerifierKey);
  }
}

/// Result class for Spotify authentication
class SpotifyAuthResult {
  final bool isSuccess;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? errorMessage;

  SpotifyAuthResult._({
    required this.isSuccess,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.errorMessage,
  });

  factory SpotifyAuthResult.success({
    required String accessToken,
    String? refreshToken,
    required DateTime expiresAt,
  }) {
    return SpotifyAuthResult._(
      isSuccess: true,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
    );
  }

  factory SpotifyAuthResult.failure(String message) {
    return SpotifyAuthResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}
