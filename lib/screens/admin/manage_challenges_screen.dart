import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/challenge_provider.dart';
import '../../services/challenge_service.dart';

class ManageChallengesScreen extends ConsumerWidget {
  const ManageChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(activeChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Challenges')),
      body: challengesAsync.when(
        data: (challenges) {
          if (challenges.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('No active challenges'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: challenges.length,
            itemBuilder: (context, index) {
              final challenge = challenges[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.emoji_events,
                              color: Colors.amber),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              challenge.title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (action) async {
                              if (action == 'delete') {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Challenge'),
                                    content: Text(
                                        'Delete "${challenge.title}"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true && challenge.id != null) {
                                  final challengeService =
                                      ref.read(challengeServiceProvider);
                                  await challengeService
                                      .deleteChallenge(challenge.id!);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Challenge deleted')),
                                    );
                                  }
                                }
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Delete'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(challenge.description),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          Chip(
                            label: Text(challenge.type),
                            avatar: const Icon(Icons.flag, size: 16),
                          ),
                          Chip(
                            label:
                                Text('Target: ${challenge.targetValue}'),
                            avatar:
                                const Icon(Icons.track_changes, size: 16),
                          ),
                          Chip(
                            label: Text(
                                '${challenge.participants.length} joined'),
                            avatar:
                                const Icon(Icons.people, size: 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ends: ${DateFormat.yMMMd().format(challenge.endDate)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
