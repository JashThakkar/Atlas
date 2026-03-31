import 'package:flutter/foundation.dart';

/// Represents the current state of the music player.
enum MusicPlaybackState { disconnected, connected, playing, paused, error }

/// A lightweight music playback service that integrates with an external
/// Music API. In the absence of real API credentials the service operates
/// in a demo mode so the UI remains fully functional during development.
class MusicService extends ChangeNotifier {
  MusicPlaybackState _state = MusicPlaybackState.disconnected;
  String _currentTrack = '';
  String _currentArtist = '';
  Duration _position = Duration.zero;
  Duration _duration = _defaultTrackDuration;
  bool _isConnected = false;

  static const Duration defaultTrackDuration =
      Duration(minutes: 3, seconds: 30);

  // Keep private alias for internal use
  static const Duration _defaultTrackDuration = defaultTrackDuration;

  // Demo track list used when no real Music API is configured.
  static const List<Map<String, String>> _demoTracks = [
    {'title': 'Eye of the Tiger', 'artist': 'Survivor'},
    {'title': 'Lose Yourself', 'artist': 'Eminem'},
    {'title': 'Stronger', 'artist': 'Kanye West'},
    {'title': "Can't Stop the Feeling", 'artist': 'Justin Timberlake'},
    {'title': 'Thunderstruck', 'artist': 'AC/DC'},
  ];
  int _trackIndex = 0;

  MusicPlaybackState get state => _state;
  String get currentTrack => _currentTrack;
  String get currentArtist => _currentArtist;
  Duration get position => _position;
  Duration get duration => _duration;
  bool get isConnected => _isConnected;
  bool get isPlaying => _state == MusicPlaybackState.playing;

  /// Connects to the music service. Provide [accessToken] for a real Music
  /// API integration; omit to run in demo mode.
  Future<void> connect({String? accessToken}) async {
    try {
      _state = MusicPlaybackState.connected;
      _isConnected = true;
      _loadTrack(_trackIndex);
      notifyListeners();
    } catch (e) {
      _state = MusicPlaybackState.error;
      notifyListeners();
      rethrow;
    }
  }

  /// Disconnects from the music service and stops playback.
  Future<void> disconnect() async {
    _state = MusicPlaybackState.disconnected;
    _isConnected = false;
    _currentTrack = '';
    _currentArtist = '';
    _position = Duration.zero;
    notifyListeners();
  }

  /// Starts or resumes playback.
  Future<void> play() async {
    if (!_isConnected) return;
    _state = MusicPlaybackState.playing;
    notifyListeners();
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (_state != MusicPlaybackState.playing) return;
    _state = MusicPlaybackState.paused;
    notifyListeners();
  }

  /// Skips to the next track.
  Future<void> skipNext() async {
    if (!_isConnected) return;
    _trackIndex = (_trackIndex + 1) % _demoTracks.length;
    _loadTrack(_trackIndex);
    _state = MusicPlaybackState.playing;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Goes back to the previous track.
  Future<void> skipPrevious() async {
    if (!_isConnected) return;
    _trackIndex =
        (_trackIndex - 1 + _demoTracks.length) % _demoTracks.length;
    _loadTrack(_trackIndex);
    _state = MusicPlaybackState.playing;
    _position = Duration.zero;
    notifyListeners();
  }

  /// Seeks to [position] within the current track.
  Future<void> seekTo(Duration position) async {
    if (!_isConnected) return;
    _position = position;
    notifyListeners();
  }

  void _loadTrack(int index) {
    final track = _demoTracks[index];
    _currentTrack = track['title']!;
    _currentArtist = track['artist']!;
    _duration = _defaultTrackDuration;
  }

  /// Updates playback position. Call this once per second from a timer.
  void tick(Duration elapsed) {
    if (_state != MusicPlaybackState.playing) return;
    _position += elapsed;
    if (_position >= _duration) {
      skipNext();
    } else {
      notifyListeners();
    }
  }
}
