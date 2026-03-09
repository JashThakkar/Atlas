import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitness_provider.dart';
import '../../models/exercise_log_model.dart';

class ExerciseHistoryScreen extends ConsumerWidget {
  const ExerciseHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise History'),
      ),
      body: currentUserAsync.when(
        data: (user) {
          if (user == null) return const SizedBox();

          final logsAsync = ref.watch(exerciseLogsProvider(user.uid));

          return logsAsync.when(
            data: (logs) {
              if (logs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.list_alt, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No exercises logged yet',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      const Text('Log your first exercise to see it here!'),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/exercise-logger'),
                        icon: const Icon(Icons.add),
                        label: const Text('Log Exercise'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  return _ExerciseLogCard(log: logs[index]);
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(child: Text('Error: $error')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              Text(
                error.toString().contains('unavailable')
                    ? 'Connection issue. Please check your internet and try again.'
                    : 'Error loading data. Please try again.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(currentUserProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/exercise-logger'),
        icon: const Icon(Icons.add),
        label: const Text('Log Exercise'),
      ),
    );
  }
}

class _ExerciseLogCard extends StatelessWidget {
  const _ExerciseLogCard({required this.log});

  final ExerciseLogModel log;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.exerciseName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  DateFormat.yMMMd().format(log.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.repeat, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${log.sets.length} set${log.sets.length == 1 ? '' : 's'}'),
                const SizedBox(width: 16),
                const Icon(Icons.fitness_center, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${log.totalReps} total reps'),
              ],
            ),
            if (log.sets.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: log.sets.map((set) {
                  final label = set.weight != null
                      ? 'Set ${set.setNumber}: ${set.reps} reps × ${set.weight}kg'
                      : 'Set ${set.setNumber}: ${set.reps} reps';
                  return Chip(
                    label: Text(label, style: const TextStyle(fontSize: 12)),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                log.notes!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
