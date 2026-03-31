import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/circle_provider.dart';
import '../../providers/auth_provider.dart';

class CirclesScreen extends ConsumerWidget {
  const CirclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final circlesAsync = ref.watch(userCirclesProvider(user.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Circles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create or Join Circle',
            onPressed: () => context.push('/circles/join-or-create'),
          ),
        ],
      ),
      body: circlesAsync.when(
        data: (circles) {
          if (circles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group, size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No circles yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Create a circle or join one with an invite code.'),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create or Join Circle'),
                    onPressed: () => context.push('/circles/join-or-create'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: circles.length,
            itemBuilder: (context, index) {
              final circle = circles[index];
              final myScore = circle.activityScores[user.uid] ?? 0;
              final memberCount = circle.memberIds.length;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      circle.name.isNotEmpty ? circle.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(circle.name,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                      '$memberCount member${memberCount != 1 ? 's' : ''} · My score: $myScore'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/circles/${circle.id}'),
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
