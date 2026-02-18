import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/social_service.dart';
import '../models/post_model.dart';

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
