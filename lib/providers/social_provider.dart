import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/social_service.dart';
import '../models/post_model.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../core/constants.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());

final feedProvider = StreamProvider<List<PostModel>>((ref) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getFeed();
});

final userPostsProvider = StreamProvider.family<List<PostModel>, String>((ref, userId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getUserPosts(userId);
});

final postCommentsProvider = StreamProvider.family<List<CommentModel>, String>((ref, postId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getPostComments(postId);
});

final userFriendsProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getUserFriends(userId);
});

final incomingFriendRequestsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getIncomingFriendRequests(userId);
});

final outgoingFriendRequestsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, userId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getOutgoingFriendRequests(userId);
});

final chatRoomsProvider =
    StreamProvider.family<List<ChatRoom>, String>((ref, userId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getUserChatRooms(userId);
});

final chatMessagesProvider =
    StreamProvider.family<List<Message>, String>((ref, chatId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getChatMessages(chatId);
});

// Provider to fetch a user's data by ID (for friend request tiles, etc.)
final userByIdProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, userId) async {
  final doc = await FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .get();
  if (!doc.exists) return null;
  return {'uid': doc.id, ...doc.data()!};
});

