import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../services/user_service.dart';
import '../models/post_model.dart';
import '../models/chat.dart';
import '../models/message.dart';

final socialServiceProvider = Provider<SocialService>((ref) => SocialService());
final _userServiceProvider = Provider<UserService>((ref) => UserService());

final feedProvider = StreamProvider<List<PostModel>>((ref) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getFeed();
});

final userPostsProvider = StreamProvider.family<List<PostModel>, String>((ref, userId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getUserPosts(userId);
});

final postProvider = StreamProvider.family<PostModel?, String>((ref, postId) {
  final socialService = ref.watch(socialServiceProvider);
  return socialService.getPost(postId);
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
  final userService = ref.watch(_userServiceProvider);
  final user = await userService.getUserById(userId);
  if (user == null) return null;
  return {'uid': user.uid, ...user.toMap()};
});

