import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/social_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/post_model.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitComment() async {
    final content = _commentController.text.trim();
    if (content.isEmpty) return;

    final authUser = ref.read(authStateProvider).value;
    final currentUser = ref.read(currentUserProvider).value;
    if (authUser == null) return;

    setState(() => _isPosting = true);
    try {
      final comment = CommentModel(
        postId: widget.postId,
        userId: authUser.uid,
        userName: currentUser?.displayName ?? authUser.displayName ?? 'Anonymous',
        userPhotoUrl: currentUser?.photoUrl ?? authUser.photoURL,
        content: content,
        createdAt: DateTime.now(),
      );
      await ref.read(socialServiceProvider).addComment(comment);
      _commentController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(postProvider(widget.postId));
    final commentsAsync = ref.watch(postCommentsProvider(widget.postId));
    final currentUserId = ref.watch(authStateProvider).value?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: postAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (post) {
          if (post == null) {
            return const Center(child: Text('Post not found'));
          }
          final isLiked = post.isLikedBy(currentUserId);
          return Column(
            children: [
              // Scrollable content: post + comments
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // --- Post card ---
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundImage: post.userPhotoUrl != null
                                      ? NetworkImage(post.userPhotoUrl!)
                                      : null,
                                  child: post.userPhotoUrl == null
                                      ? Text(post.userName.isNotEmpty
                                          ? post.userName[0].toUpperCase()
                                          : '?')
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        post.userName,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        timeago.format(post.createdAt),
                                        style:
                                            Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(post.content),
                            if (post.imageUrl != null) ...[
                              const SizedBox(height: 12),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  post.imageUrl!,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked ? Colors.red : null,
                                  ),
                                  onPressed: currentUserId.isEmpty
                                      ? null
                                      : () async {
                                          final svc = ref
                                              .read(socialServiceProvider);
                                          if (isLiked) {
                                            await svc.unlikePost(
                                                post.id!, currentUserId);
                                          } else {
                                            await svc.likePost(
                                                post.id!, currentUserId);
                                          }
                                        },
                                ),
                                Text('${post.likes.length}'),
                                const SizedBox(width: 16),
                                const Icon(Icons.comment_outlined, size: 20),
                                const SizedBox(width: 4),
                                Text('${post.commentCount}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    Text(
                      'Comments',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // --- Comments list ---
                    commentsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) =>
                          Center(child: Text('Error loading comments: $e')),
                      data: (comments) {
                        if (comments.isEmpty) {
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 24),
                            child: Center(
                              child: Text(
                                'No comments yet. Be the first!',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(color: Colors.grey),
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: comments
                              .map((comment) => _CommentTile(comment: comment))
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // --- New comment input ---
              const Divider(height: 1),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  8,
                  MediaQuery.of(context).viewInsets.bottom + 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        minLines: 1,
                        maxLines: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _isPosting
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _submitComment,
                          ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});

  final CommentModel comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: comment.userPhotoUrl != null
                ? NetworkImage(comment.userPhotoUrl!)
                : null,
            child: comment.userPhotoUrl == null
                ? Text(comment.userName.isNotEmpty
                    ? comment.userName[0].toUpperCase()
                    : '?')
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      comment.userName,
                      style:
                          const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      timeago.format(comment.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(comment.content),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
