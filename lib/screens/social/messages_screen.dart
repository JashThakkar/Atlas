import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/auth_provider.dart';
import '../../providers/social_provider.dart';
import '../../models/chat.dart';

class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final chatRoomsAsync = ref.watch(chatRoomsProvider(currentUser.uid));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => context.push('/discover-friends'),
            tooltip: 'Find Friends',
          ),
        ],
      ),
      body: chatRoomsAsync.when(
        data: (chatRooms) {
          if (chatRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text('Add friends to start chatting!'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Find Friends'),
                    onPressed: () => context.push('/discover-friends'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chatRooms.length,
            itemBuilder: (context, index) {
              final chatRoom = chatRooms[index];
              final otherUserId = chatRoom.participants
                  .firstWhere((id) => id != currentUser.uid,
                      orElse: () => chatRoom.participants.first);
              return _ChatRoomTile(
                chatRoom: chatRoom,
                otherUserId: otherUserId,
                currentUserId: currentUser.uid,
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

class _ChatRoomTile extends ConsumerWidget {
  final ChatRoom chatRoom;
  final String otherUserId;
  final String currentUserId;

  const _ChatRoomTile({
    required this.chatRoom,
    required this.otherUserId,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userByIdProvider(otherUserId));

    return userAsync.when(
      data: (user) {
        final name = user?['displayName'] ?? 'Unknown';
        final photoUrl = user?['photoUrl'] as String?;
        final lastMessage = chatRoom.lastMessage;
        final lastMessageTime = chatRoom.lastMessageTime;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage: photoUrl != null
                ? CachedNetworkImageProvider(photoUrl)
                : null,
            child: photoUrl == null ? Text(name[0].toUpperCase()) : null,
          ),
          title: Text(name),
          subtitle: lastMessage != null
              ? Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : const Text('No messages yet'),
          trailing: lastMessageTime != null
              ? Text(
                  timeago.format(lastMessageTime, allowFromNow: true),
                  style: Theme.of(context).textTheme.bodySmall,
                )
              : null,
          onTap: () {
            context.push('/chat/${chatRoom.id}', extra: {
              'otherUserId': otherUserId,
              'otherUserName': name,
            });
          },
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
