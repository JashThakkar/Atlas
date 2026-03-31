import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/spotify_service.dart';

/// App-wide singleton for the Spotify service.
/// Use [spotifyServiceProvider] from any widget to read or watch Spotify state.
final spotifyServiceProvider = ChangeNotifierProvider<SpotifyService>(
  (ref) => SpotifyService(),
);
