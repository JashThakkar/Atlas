import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/music_provider.dart';
import '../services/spotify_service.dart';

/// Full-screen bottom-sheet Spotify player.
/// Open with:
/// ```dart
/// showSpotifyPlayerSheet(context);
/// ```
class SpotifyPlayerSheet extends ConsumerWidget {
  const SpotifyPlayerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spotify = ref.watch(spotifyServiceProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 12, left: 24, right: 24, bottom: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Row(
            children: [
              const Icon(Icons.queue_music),
              const SizedBox(width: 8),
              Text(
                'Spotify',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              if (spotify.isConnected)
                TextButton.icon(
                  icon: const Icon(Icons.link_off, size: 14),
                  label: const Text('Disconnect'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => spotify.disconnect(),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Error banner
          if (spotify.error != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: colorScheme.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      spotify.error!,
                      style: TextStyle(
                          color: colorScheme.onErrorContainer, fontSize: 12),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    color: colorScheme.onErrorContainer,
                    onPressed: () {
                      // Clear error by refreshing state
                      ref.read(spotifyServiceProvider).fetchCurrentlyPlaying();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Not connected → show connect UI
          if (!spotify.isConnected) ...[
            _NotConnectedBody(spotify: spotify),
          ] else ...[
            // Album art
            _AlbumArt(url: spotify.albumArtUrl),
            const SizedBox(height: 20),

            // Track info
            Text(
              spotify.trackName.isNotEmpty ? spotify.trackName : '—',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              spotify.artistName.isNotEmpty ? spotify.artistName : 'Unknown artist',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),

            // Progress bar
            _ProgressBar(spotify: spotify),
            const SizedBox(height: 8),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_previous_rounded),
                  onPressed: spotify.isLoading ? null : () => spotify.skipPrevious(),
                ),
                IconButton(
                  iconSize: 56,
                  icon: spotify.isLoading
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          spotify.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_filled_rounded,
                          color: const Color(0xFF1DB954), // Spotify green
                        ),
                  onPressed: spotify.isLoading
                      ? null
                      : () =>
                          spotify.isPlaying ? spotify.pause() : spotify.play(),
                ),
                IconButton(
                  iconSize: 32,
                  icon: const Icon(Icons.skip_next_rounded),
                  onPressed: spotify.isLoading ? null : () => spotify.skipNext(),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Refresh button
            TextButton.icon(
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                  foregroundColor: Colors.grey, textStyle: const TextStyle(fontSize: 12)),
              onPressed: () => spotify.fetchCurrentlyPlaying(),
            ),
          ],

          // Bottom spacer for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NotConnectedBody extends StatelessWidget {
  const _NotConnectedBody({required this.spotify});

  final SpotifyService spotify;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.music_note, size: 56, color: Color(0xFF1DB954)),
        ),
        const SizedBox(height: 24),
        Text(
          'Connect to Spotify',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          spotify.isConfigured
              ? 'Link your Spotify account to control music during workouts.'
              : 'Add your SPOTIFY_CLIENT_ID in the .env file to enable this feature.',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        if (spotify.isConfigured)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: spotify.isLoading ? null : () => spotify.startAuthFlow(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1DB954),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
              icon: spotify.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.login),
              label: Text(spotify.isLoading ? 'Connecting…' : 'Connect with Spotify'),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _AlbumArt extends StatelessWidget {
  const _AlbumArt({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url!,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 200,
      height: 200,
      color: const Color(0xFF1DB954).withOpacity(0.15),
      child: const Icon(Icons.album, size: 80, color: Color(0xFF1DB954)),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.spotify});

  final SpotifyService spotify;

  String _fmt(int ms) {
    final total = Duration(milliseconds: ms);
    final m = total.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = total.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final progress = spotify.durationMs > 0
        ? (spotify.progressMs / spotify.durationMs).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            activeTrackColor: const Color(0xFF1DB954),
            thumbColor: const Color(0xFF1DB954),
            overlayColor: const Color(0xFF1DB954).withOpacity(0.2),
          ),
          child: Slider(
            value: progress,
            onChanged: (_) {}, // visual feedback only while dragging
            onChangeEnd: (v) {
              spotify.seekTo((v * spotify.durationMs).round());
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_fmt(spotify.progressMs),
                  style: Theme.of(context).textTheme.labelSmall),
              Text(_fmt(spotify.durationMs),
                  style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper to open the Spotify player bottom sheet.
void showSpotifyPlayerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const SpotifyPlayerSheet(),
  );
}
