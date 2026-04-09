import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/circle_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/circle_model.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen> {
  Map<String, String> _memberNames = {};
  bool _loadingMemberNames = false;

  Future<void> _loadMemberNames(CircleModel circle) async {
    if (_loadingMemberNames) return;
    setState(() => _loadingMemberNames = true);
    final service = ref.read(circleServiceProvider);
    final names = await service.getMemberDisplayNames(circle.memberIds);
    if (mounted) {
      setState(() {
        _memberNames = names;
        _loadingMemberNames = false;
      });
    }
  }

  Future<void> _leaveCircle(CircleModel circle, String userId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Circle'),
        content: Text(
            'Are you sure you want to leave "${circle.name}"?'
            '${circle.memberIds.length == 1 ? ' This will delete the circle.' : ''}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Leave')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final service = ref.read(circleServiceProvider);
      await service.leaveCircle(circleId: widget.circleId, userId: userId);
      if (mounted) {
        context.go('/circles');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final circleAsync = ref.watch(circleDetailProvider(widget.circleId));
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Circle Leaderboard'),
        actions: [
          if (user != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'leave') {
                  circleAsync.whenData(
                      (circle) => circle != null
                          ? _leaveCircle(circle, user.uid)
                          : null);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'leave',
                    child: ListTile(
                        leading: Icon(Icons.exit_to_app),
                        title: Text('Leave Circle'))),
              ],
            ),
        ],
      ),
      body: circleAsync.when(
        data: (circle) {
          if (circle == null) {
            return const Center(child: Text('Circle not found.'));
          }

          // Lazily load member names when circle first loads.
          if (_memberNames.isEmpty && !_loadingMemberNames &&
              circle.memberIds.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _loadMemberNames(circle));
          }

          final ranked = circle.rankedMembers;

          return CustomScrollView(
            slivers: [
              // Header info
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        circle.name,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (circle.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(circle.description),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 4),
                          Text('${circle.memberIds.length} member'
                              '${circle.memberIds.length != 1 ? 's' : ''}'),
                          const Spacer(),
                          // Invite code chip
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(
                                  ClipboardData(text: circle.inviteCode));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Invite code copied to clipboard')),
                              );
                            },
                            child: Chip(
                              avatar: const Icon(Icons.copy, size: 14),
                              label: Text(
                                'Code: ${circle.inviteCode}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Leaderboard title
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text('Rankings',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold)),
                ),
              ),

              // Leaderboard rows
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final member = ranked[index];
                    final name =
                        _memberNames[member.userId] ?? member.displayName;
                    final isMe = user?.uid == member.userId;

                    Color? tileColor;
                    if (member.rank == 1) {
                      tileColor = Colors.amber.withOpacity(0.15);
                    } else if (member.rank == 2) {
                      tileColor = Colors.grey.shade200.withOpacity(0.5);
                    } else if (member.rank == 3) {
                      tileColor = Colors.brown.shade100.withOpacity(0.5);
                    }

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: tileColor,
                        borderRadius: BorderRadius.circular(8),
                        border: isMe
                            ? Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1.5)
                            : null,
                      ),
                      child: ListTile(
                        leading: _RankBadge(rank: member.rank),
                        title: Row(
                          children: [
                            Text(name,
                                style: TextStyle(
                                    fontWeight: isMe
                                        ? FontWeight.bold
                                        : FontWeight.normal)),
                            if (isMe) ...[
                              const SizedBox(width: 6),
                              const Text('(You)',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey)),
                            ],
                          ],
                        ),
                        trailing: Text(
                          '${member.activityScore} min',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    );
                  },
                  childCount: ranked.length,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _RankBadge extends StatelessWidget {
  const _RankBadge({required this.rank});
  final int rank;

  @override
  Widget build(BuildContext context) {
    if (rank == 1) {
      return const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Text('🥇', style: TextStyle(fontSize: 18)));
    } else if (rank == 2) {
      return CircleAvatar(
          backgroundColor: Colors.grey.shade300,
          child: const Text('🥈', style: TextStyle(fontSize: 18)));
    } else if (rank == 3) {
      return CircleAvatar(
          backgroundColor: Colors.brown.shade200,
          child: const Text('🥉', style: TextStyle(fontSize: 18)));
    }
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Text('#$rank',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }
}
