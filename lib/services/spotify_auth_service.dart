import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../core/constants/app_constants.dart';

/// Spotify OAuth 2.0 with PKCE (Proof Key for Code Exchange) Service
/// Uses url_launcher for the OAuth flow with deep link callback handling
class SpotifyAuthService {
  final FlutterSecureStorage _secureStorage;

  String? _accessToken;
  String? _refreshToken;
  DateTime? _expiresAt;
  String? _codeVerifier;

  // Completer for handling the OAuth callback
  Completer<SpotifyAuthResult>? _authCompleter;

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
  /// Must be between 43-128 characters (RFC 7636)
  String generateCodeVerifier() {
    final random = Random.secure();
    // Generate 32 random bytes (will result in 43 base64 characters)
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    _codeVerifier = base64UrlEncode(values)
        .replaceAll('=', '')
        .replaceAll('+', '-')
        .replaceAll('/', '_');
    return _codeVerifier!;
  }

  /// Generate code challenge from verifier using SHA-256 (S256 method)
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

    // Store verifier securely for later use during token exchange
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

  /// Start the OAuth flow using url_launcher
  /// Returns a Future that completes when the callback is handled
  Future<SpotifyAuthResult> authenticate() async {
    try {
      // Build the authorization URL (also generates and stores code verifier)
      final authUrl = buildAuthorizationUrl();
      print('[SpotifyAuth] Generated auth URL: $authUrl');

      // Create a completer to await the callback
      _authCompleter = Completer<SpotifyAuthResult>();

      // Launch the URL in external browser
      final uri = Uri.parse(authUrl);
      final canLaunch = await canLaunchUrl(uri);

      if (!canLaunch) {
        print('[SpotifyAuth] Cannot launch URL');
        _authCompleter = null;
        return SpotifyAuthResult.failure(
            'Cannot open browser for Spotify authentication');
      }

      print('[SpotifyAuth] Launching browser...');
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        print('[SpotifyAuth] Failed to launch browser');
        _authCompleter = null;
        return SpotifyAuthResult.failure(
            'Failed to open browser for Spotify authentication');
      }

      print('[SpotifyAuth] Browser launched, waiting for callback...');

      // Wait for the callback with a timeout
      final result = await _authCompleter!.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          print('[SpotifyAuth] Authentication timed out');
          _authCompleter = null;
          return SpotifyAuthResult.failure(
              'Authentication timed out. Please try again.');
        },
      );

      print('[SpotifyAuth] Auth result received: success=${result.isSuccess}');
      return result;
    } catch (e) {
      print('[SpotifyAuth] Authentication error: $e');
      _authCompleter = null;
      return SpotifyAuthResult.failure('Authentication failed: $e');
    }
  }

  /// Handle the redirect callback from Spotify deep link
  /// This should be called from your app's deep link handler
  Future<SpotifyAuthResult> handleRedirectCallback(Uri uri) async {
    try {
      print('[SpotifyAuth] Handling redirect callback: $uri');

      // Check for errors from Spotify
      final error = uri.queryParameters['error'];
      if (error != null) {
        final errorDescription =
            uri.queryParameters['error_description'] ?? error;
        print('[SpotifyAuth] Spotify returned error: $errorDescription');
        final result = SpotifyAuthResult.failure(
            'Spotify authorization error: $errorDescription');
        _authCompleter?.complete(result);
        _authCompleter = null;
        return result;
      }

      // Get the authorization code
      final code = uri.queryParameters['code'];
      if (code == null) {
        print('[SpotifyAuth] No authorization code in callback');
        final result = SpotifyAuthResult.failure(
            'No authorization code received from Spotify');
        _authCompleter?.complete(result);
        _authCompleter = null;
        return result;
      }

      print(
          '[SpotifyAuth] Received authorization code, exchanging for tokens...');

      // Exchange the code for tokens
      final result = await exchangeCodeForToken(code);

      // Complete the auth completer if it exists
      _authCompleter?.complete(result);
      _authCompleter = null;

      return result;
    } catch (e) {
      print('[SpotifyAuth] Callback handling error: $e');
      final result = SpotifyAuthResult.failure('Callback handling error: $e');
      _authCompleter?.complete(result);
      _authCompleter = null;
      return result;
    }
  }

  /// Cancel any pending authentication
  void cancelAuthentication() {
    if (_authCompleter != null && !_authCompleter!.isCompleted) {
      _authCompleter!.complete(
          SpotifyAuthResult.failure('Authentication cancelled by user'));
    }
    _authCompleter = null;
  }

  /// Exchange authorization code for access and refresh tokens
  Future<SpotifyAuthResult> exchangeCodeForToken(String code) async {
    try {
      // Retrieve the code verifier
      final verifier =
          await _secureStorage.read(key: AppConstants.spotifyCodeVerifierKey);
      if (verifier == null) {
        print('[SpotifyAuth] Code verifier not found in storage');
        return SpotifyAuthResult.failure('Code verifier not found');
      }

      print('[SpotifyAuth] Exchanging code for token...');
      print('[SpotifyAuth] Redirect URI: ${AppConstants.spotifyRedirectUri}');

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

      print('[SpotifyAuth] Token response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _saveTokens(data);
        print('[SpotifyAuth] Tokens saved successfully');
        return SpotifyAuthResult.success(
          accessToken: _accessToken!,
          refreshToken: _refreshToken,
          expiresAt: _expiresAt!,
        );
      } else {
        final error = json.decode(response.body);
        final errorMsg =
            'Token exchange failed: ${error['error_description'] ?? error['error']}';
        print('[SpotifyAuth] $errorMsg');
        print('[SpotifyAuth] Full error response: ${response.body}');
        return SpotifyAuthResult.failure(errorMsg);
      }
    } catch (e) {
      print('[SpotifyAuth] Token exchange error: $e');
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
