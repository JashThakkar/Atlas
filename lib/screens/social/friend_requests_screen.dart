import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../../services/social_service.dart';

class FriendRequestsScreen extends ConsumerWidget {
  const FriendRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const Scaffold(body: SizedBox());

    final incomingAsync =
        ref.watch(incomingFriendRequestsProvider(currentUser.uid));
    final outgoingAsync =
        ref.watch(outgoingFriendRequestsProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Friend Requests')),
      body: ListView(
        children: [
          // Incoming requests
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Incoming Requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          incomingAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const ListTile(
                  title: Text('No incoming requests'),
                  leading: Icon(Icons.inbox),
                );
              }
              return Column(
                children: requests.map((req) {
                  final friendshipId = req['id'] as String;
                  final fromUserId = req['fromUserId'] as String;
                  return _IncomingRequestTile(
                    friendshipId: friendshipId,
                    fromUserId: fromUserId,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),

          const Divider(),

          // Outgoing requests
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Sent Requests',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          outgoingAsync.when(
            data: (requests) {
              if (requests.isEmpty) {
                return const ListTile(
                  title: Text('No sent requests'),
                  leading: Icon(Icons.send),
                );
              }
              return Column(
                children: requests.map((req) {
                  final friendshipId = req['id'] as String;
                  final toUserId = req['toUserId'] as String;
                  return _OutgoingRequestTile(
                    friendshipId: friendshipId,
                    toUserId: toUserId,
                  );
                }).toList(),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => ListTile(title: Text('Error: $e')),
          ),
        ],
      ),
    );
  }
}

class _IncomingRequestTile extends ConsumerWidget {
  final String friendshipId;
  final String fromUserId;

  const _IncomingRequestTile({
    required this.friendshipId,
    required this.fromUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(fromUserId));

    return userAsync.when(
      data: (user) {
        final name = user?['displayName'] ?? 'Unknown';
        final photoUrl = user?['photoUrl'] as String?;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null ? Text(name[0].toUpperCase()) : null,
          ),
          title: Text(name),
          subtitle: const Text('Wants to be your friend'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () async {
                  final socialService = ref.read(socialServiceProvider);
                  await socialService.acceptFriendRequest(friendshipId);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Friend request accepted!')),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () async {
                  final socialService = ref.read(socialServiceProvider);
                  await socialService.rejectFriendRequest(friendshipId);
                },
              ),
            ],
          ),
        );
      },
      loading: () => const ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator()),
        title: Text('Loading...'),
      ),
      error: (e, _) => ListTile(title: Text('Error: $e')),
    );
  }
}

class _OutgoingRequestTile extends ConsumerWidget {
  final String friendshipId;
  final String toUserId;

  const _OutgoingRequestTile({
    required this.friendshipId,
    required this.toUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(toUserId));

    return userAsync.when(
      data: (user) {
        final name = user?['displayName'] ?? 'Unknown';
        final photoUrl = user?['photoUrl'] as String?;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null ? Text(name[0].toUpperCase()) : null,
          ),
          title: Text(name),
          subtitle: const Text('Request pending'),
          trailing: TextButton(
            onPressed: () async {
              final socialService = ref.read(socialServiceProvider);
              await socialService.cancelFriendRequest(friendshipId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Request cancelled')),
                );
              }
            },
            child: const Text('Cancel'),
          ),
        );
      },
      loading: () => const ListTile(
        leading: CircleAvatar(child: CircularProgressIndicator()),
        title: Text('Loading...'),
      ),
      error: (e, _) => ListTile(title: Text('Error: $e')),
    );
  }
}
