import 'dart:async';
import 'package:flutter/material.dart';
import '../services/music_service.dart';

/// A compact music player widget designed to sit inside workout screens.
/// It shows the current track, artist, playback controls, and a seek bar.
class MusicPlayerWidget extends StatefulWidget {
  const MusicPlayerWidget({super.key, required this.musicService});

  final MusicService musicService;

  @override
  State<MusicPlayerWidget> createState() => _MusicPlayerWidgetState();
}

class _MusicPlayerWidgetState extends State<MusicPlayerWidget> {
  Timer? _ticker;

  MusicService get _service => widget.musicService;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onServiceChanged);
    _ticker =
        Timer.periodic(const Duration(seconds: 1), (_) => _service.tick(const Duration(seconds: 1)));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _service.removeListener(_onServiceChanged);
    super.dispose();
  }

  void _onServiceChanged() {
    if (mounted) setState(() {});
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = _service.state;

    if (state == MusicPlaybackState.disconnected) {
      return _DisconnectedBanner(
        onConnect: () async {
          try {
            await _service.connect();
          } catch (_) {}
        },
      );
    }

    if (state == MusicPlaybackState.error) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.music_off, size: 36, color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              const Text(
                'Music unavailable',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Could not reach the music service.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh, size: 14),
                label: const Text('Retry'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                onPressed: () async {
                  try {
                    await _service.connect();
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      );
    }

    final position = _service.position;
    final duration =
        _service.duration.inSeconds > 0 ? _service.duration : MusicService.defaultTrackDuration;
    final progress =
        duration.inSeconds > 0 ? position.inSeconds / duration.inSeconds : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Icon(Icons.music_note, size: 16),
                const SizedBox(width: 6),
                Text('Music',
                    style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.link_off, size: 14),
                  label: const Text('Disconnect'),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: () => _service.disconnect(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Track info
            Text(
              _service.currentTrack.isNotEmpty
                  ? _service.currentTrack
                  : 'Unknown track',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _service.currentArtist.isNotEmpty
                  ? _service.currentArtist
                  : 'Unknown artist',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Seek bar
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (v) {
                  _service.seekTo(Duration(
                      seconds: (v * duration.inSeconds).round()));
                },
              ),
            ),

            // Time labels
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_formatDuration(position),
                    style: Theme.of(context).textTheme.labelSmall),
                Text(_formatDuration(duration),
                    style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
            const SizedBox(height: 4),

            // Playback controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () => _service.skipPrevious(),
                ),
                IconButton(
                  iconSize: 40,
                  icon: Icon(_service.isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  onPressed: () => _service.isPlaying
                      ? _service.pause()
                      : _service.play(),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () => _service.skipNext(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DisconnectedBanner extends StatelessWidget {
  const _DisconnectedBanner({required this.onConnect});

  final VoidCallback onConnect;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.music_off),
        title: const Text('Music not connected'),
        subtitle: const Text('Connect to control playback during workouts'),
        trailing: ElevatedButton(
          onPressed: onConnect,
          style: ElevatedButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            textStyle: const TextStyle(fontSize: 12),
          ),
          child: const Text('Connect'),
        ),
      ),
    );
  }
}
