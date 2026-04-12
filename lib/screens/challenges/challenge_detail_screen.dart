import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/challenge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/challenge_provider.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final ChallengeModel challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final userId = user?.uid;
    final challengeId = challenge.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(challenge.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events,
                            color: Colors.amber, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            challenge.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(challenge.description),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Chip(
                          label: Text(challenge.type),
                          avatar: const Icon(Icons.flag, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Text('Target: ${challenge.targetValue}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Ends: ${DateFormat.yMMMd().format(challenge.endDate)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Text(
                          '${challenge.participants.length} participants',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Progress section
            if (userId != null && challengeId != null) ...[
              Text(
                'Your Progress',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ref
                  .watch(userChallengeProgressProvider(
                      (userId: userId, challengeId: challengeId)))
                  .when(
                    data: (progress) {
                      if (progress == null) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No progress data found.'),
                          ),
                        );
                      }

                      final pct = (challenge.targetValue > 0
                              ? progress.currentValue /
                                  challenge.targetValue
                              : 0.0)
                          .clamp(0.0, 1.0);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${progress.currentValue} / ${challenge.targetValue}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                            fontWeight: FontWeight.bold),
                                  ),
                                  if (progress.completed)
                                    Chip(
                                      label: const Text('Completed!'),
                                      backgroundColor:
                                          Colors.green.shade100,
                                      avatar: const Icon(Icons.check_circle,
                                          color: Colors.green, size: 16),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              LinearProgressIndicator(
                                value: pct,
                                minHeight: 10,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(pct * 100).toStringAsFixed(0)}% complete',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (progress.completed &&
                                  progress.completedAt != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Completed on ${DateFormat.yMMMd().format(progress.completedAt!)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: Colors.green),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) =>
                        Text('Error loading progress: $e'),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
