import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Spotify Web API integration with PKCE OAuth 2.0.
///
/// Free Spotify API features supported (all Spotify accounts):
///   - Read currently-playing track and playback state
///
/// Premium-only features (gracefully degraded for free users):
///   - Play / pause / skip controls
///   - Seek position
///
/// Setup (developer.spotify.com):
///   1. Create an app, copy the Client ID.
///   2. Add redirect URI: atlasfit://spotify-callback
///   3. Set SPOTIFY_CLIENT_ID in your .env file.
class SpotifyService extends ChangeNotifier {
  // ── OAuth constants ────────────────────────────────────────────────────────
  static const String _authBase = 'https://accounts.spotify.com';
  static const String _apiBase = 'https://api.spotify.com/v1';
  static const String _redirectUri = 'atlasfit://spotify-callback';
  static const String _scopes =
      'user-read-currently-playing '
      'user-read-playback-state '
      'user-modify-playback-state';

  // ── Secure storage keys ───────────────────────────────────────────────────
  static const _kAccessToken = 'spotify_access_token';
  static const _kRefreshToken = 'spotify_refresh_token';
  static const _kTokenExpiry = 'spotify_token_expiry';

  // ── State ─────────────────────────────────────────────────────────────────
  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  String _trackName = '';
  String _artistName = '';
  String? _albumArtUrl;
  bool _isPlaying = false;
  int _progressMs = 0;
  int _durationMs = 0;
  bool _isConnected = false;
  bool _isLoading = false;
  String? _error;

  // PKCE in-flight verifier — kept until callback completes.
  String? _pendingCodeVerifier;

  Timer? _pollTimer;
  final _storage = const FlutterSecureStorage();

  // ── Getters ───────────────────────────────────────────────────────────────
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  String get trackName => _trackName;
  String get artistName => _artistName;
  String? get albumArtUrl => _albumArtUrl;
  int get progressMs => _progressMs;
  int get durationMs => _durationMs;
  String? get error => _error;

  String get clientId => dotenv.env['SPOTIFY_CLIENT_ID'] ?? '';
  bool get isConfigured => clientId.isNotEmpty;

  // ── Initialisation ────────────────────────────────────────────────────────

  /// Call once on app start to restore a previously stored session.
  Future<void> initialize() async {
    if (!isConfigured) {
      debugPrint('⚠️ SPOTIFY_CLIENT_ID not set — music features disabled.');
      return;
    }
    try {
      _accessToken = await _storage.read(key: _kAccessToken);
      _refreshToken = await _storage.read(key: _kRefreshToken);
      final expiryStr = await _storage.read(key: _kTokenExpiry);
      if (expiryStr != null) {
        _tokenExpiry = DateTime.tryParse(expiryStr);
      }

      if (_accessToken != null) {
        // Try to refresh so we start with a valid token.
        final ok = await _refreshAccessToken();
        if (ok) {
          _isConnected = true;
          _startPolling();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('SpotifyService.initialize error: $e');
    }
  }

  // ── OAuth PKCE ────────────────────────────────────────────────────────────

  /// Opens the Spotify authorization URL in the device browser.
  /// The user grants permission and the system deep-links back to
  /// [_redirectUri].  Call [handleRedirectCallback] with the incoming URI.
  Future<void> startAuthFlow() async {
    if (!isConfigured) {
      _setError('Spotify Client ID not configured. Add SPOTIFY_CLIENT_ID to .env');
      return;
    }

    _pendingCodeVerifier = _generateCodeVerifier();
    final codeChallenge = _codeChallenge(_pendingCodeVerifier!);

    final uri = Uri.parse('$_authBase/authorize').replace(
      queryParameters: {
        'client_id': clientId,
        'response_type': 'code',
        'redirect_uri': _redirectUri,
        'code_challenge_method': 'S256',
        'code_challenge': codeChallenge,
        'scope': _scopes,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _setError('Could not open browser for Spotify login.');
      }
    } catch (e) {
      _setError('Failed to open Spotify login: $e');
    }
  }

  /// Handle the deep-link URI that Spotify sends back to [_redirectUri].
  /// Call this from your deep-link listener (e.g. app_links).
  Future<void> handleRedirectCallback(Uri uri) async {
    if (_pendingCodeVerifier == null) return;
    final code = uri.queryParameters['code'];
    if (code == null) {
      _setError('Spotify auth cancelled or failed.');
      return;
    }

    _setLoading(true);
    try {
      await _exchangeCodeForTokens(code, _pendingCodeVerifier!);
      _pendingCodeVerifier = null;
      _isConnected = true;
      _error = null;
      _startPolling();
      notifyListeners();
    } catch (e) {
      _setError('Failed to get Spotify tokens: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _exchangeCodeForTokens(String code, String verifier) async {
    final response = await http.post(
      Uri.parse('$_authBase/api/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': _redirectUri,
        'client_id': clientId,
        'code_verifier': verifier,
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Token exchange failed: ${response.body}');
    }
    _storeTokenResponse(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await http.post(
        Uri.parse('$_authBase/api/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': _refreshToken!,
          'client_id': clientId,
        },
      );
      if (response.statusCode == 200) {
        _storeTokenResponse(jsonDecode(response.body) as Map<String, dynamic>);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void _storeTokenResponse(Map<String, dynamic> json) {
    _accessToken = json['access_token'] as String?;
    if (json['refresh_token'] != null) {
      _refreshToken = json['refresh_token'] as String;
    }
    final expiresIn = json['expires_in'] as int? ?? 3600;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn - 60));

    _storage.write(key: _kAccessToken, value: _accessToken);
    if (_refreshToken != null) {
      _storage.write(key: _kRefreshToken, value: _refreshToken);
    }
    _storage.write(key: _kTokenExpiry, value: _tokenExpiry?.toIso8601String());
  }

  // ── Token helper ──────────────────────────────────────────────────────────

  Future<String?> _validToken() async {
    if (_accessToken == null) return null;
    if (_tokenExpiry != null && DateTime.now().isAfter(_tokenExpiry!)) {
      final ok = await _refreshAccessToken();
      if (!ok) {
        _isConnected = false;
        notifyListeners();
        return null;
      }
    }
    return _accessToken;
  }

  // ── Playback polling ──────────────────────────────────────────────────────

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchCurrentlyPlaying());
    // Fetch immediately on connect.
    fetchCurrentlyPlaying();
  }

  Future<void> fetchCurrentlyPlaying() async {
    final token = await _validToken();
    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_apiBase/me/player/currently-playing'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        _parsePlaybackData(data);
      } else if (response.statusCode == 204) {
        // Nothing playing.
        _isPlaying = false;
        _trackName = 'Nothing playing';
        _artistName = '';
        _albumArtUrl = null;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('SpotifyService.fetchCurrentlyPlaying error: $e');
    }
  }

  void _parsePlaybackData(Map<String, dynamic> data) {
    _isPlaying = data['is_playing'] as bool? ?? false;
    _progressMs = data['progress_ms'] as int? ?? 0;

    final item = data['item'] as Map<String, dynamic>?;
    if (item != null) {
      _trackName = item['name'] as String? ?? '';
      _durationMs = item['duration_ms'] as int? ?? 0;

      final artists = item['artists'] as List<dynamic>?;
      _artistName = artists
              ?.map((a) => (a as Map<String, dynamic>)['name'] as String? ?? '')
              .join(', ') ??
          '';

      final album = item['album'] as Map<String, dynamic>?;
      final images = album?['images'] as List<dynamic>?;
      _albumArtUrl = images?.isNotEmpty == true
          ? (images!.first as Map<String, dynamic>)['url'] as String?
          : null;
    }
  }

  // ── Playback controls ─────────────────────────────────────────────────────

  Future<void> play() async => _playerCommand('PUT', '/me/player/play');
  Future<void> pause() async => _playerCommand('PUT', '/me/player/pause');
  Future<void> skipNext() async => _playerCommand('POST', '/me/player/next');
  Future<void> skipPrevious() async => _playerCommand('POST', '/me/player/previous');

  Future<void> seekTo(int positionMs) async {
    final token = await _validToken();
    if (token == null) return;
    await http.put(
      Uri.parse('$_apiBase/me/player/seek?position_ms=$positionMs'),
      headers: {'Authorization': 'Bearer $token'},
    );
    _progressMs = positionMs;
    notifyListeners();
  }

  Future<void> _playerCommand(String method, String path) async {
    final token = await _validToken();
    if (token == null) return;

    http.Response response;
    final uri = Uri.parse('$_apiBase$path');
    final headers = {'Authorization': 'Bearer $token', 'Content-Length': '0'};

    if (method == 'PUT') {
      response = await http.put(uri, headers: headers);
    } else {
      response = await http.post(uri, headers: headers);
    }

    if (response.statusCode == 403) {
      _setError('Playback control requires Spotify Premium.');
      return;
    }
    if (response.statusCode == 404) {
      _setError('No active Spotify device found. Open Spotify on a device first.');
      return;
    }

    // Refresh state after command.
    await Future.delayed(const Duration(milliseconds: 500));
    await fetchCurrentlyPlaying();
  }

  // ── Disconnect ────────────────────────────────────────────────────────────

  Future<void> disconnect() async {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isConnected = false;
    _accessToken = null;
    _refreshToken = null;
    _tokenExpiry = null;
    _trackName = '';
    _artistName = '';
    _albumArtUrl = null;
    _isPlaying = false;
    _progressMs = 0;
    _durationMs = 0;
    _error = null;

    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kTokenExpiry);

    notifyListeners();
  }

  // ── PKCE helpers ──────────────────────────────────────────────────────────

  String _generateCodeVerifier() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rng = Random.secure();
    return List.generate(128, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _codeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  void _setError(String msg) {
    _error = msg;
    debugPrint('SpotifyService error: $msg');
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
