import 'package:flutter_test/flutter_test.dart';

import 'package:atlas/models/post_model.dart';

void main() {
  final testDate = DateTime(2024, 4, 20, 12, 0);

  group('PostModel', () {
    PostModel buildPost({List<String>? likes}) {
      return PostModel(
        id: 'post-1',
        userId: 'user-1',
        userName: 'Alice',
        content: 'Great workout today!',
        createdAt: testDate,
        likes: likes ?? [],
      );
    }

    group('isLikedBy', () {
      test('returns false when likes list is empty', () {
        final post = buildPost(likes: []);
        expect(post.isLikedBy('user-2'), isFalse);
      });

      test('returns true when userId is in likes list', () {
        final post = buildPost(likes: ['user-2', 'user-3']);
        expect(post.isLikedBy('user-2'), isTrue);
      });

      test('returns false when userId is not in likes list', () {
        final post = buildPost(likes: ['user-2', 'user-3']);
        expect(post.isLikedBy('user-4'), isFalse);
      });

      test('returns true for the only user in the likes list', () {
        final post = buildPost(likes: ['user-5']);
        expect(post.isLikedBy('user-5'), isTrue);
      });

      test('returns false for a user similar to but not matching a liked user',
          () {
        final post = buildPost(likes: ['user-10']);
        expect(post.isLikedBy('user-1'), isFalse);
      });
    });

    test('constructor sets optional fields to defaults', () {
      final post = PostModel(
        userId: 'user-1',
        userName: 'Bob',
        content: 'Hello!',
        createdAt: testDate,
      );

      expect(post.id, isNull);
      expect(post.userPhotoUrl, isNull);
      expect(post.imageUrl, isNull);
      expect(post.likes, isEmpty);
      expect(post.commentCount, 0);
    });

    test('constructor stores all provided fields', () {
      final post = PostModel(
        id: 'p-2',
        userId: 'user-2',
        userName: 'Carol',
        userPhotoUrl: 'https://example.com/photo.jpg',
        content: 'Feeling strong!',
        imageUrl: 'https://example.com/image.jpg',
        likes: ['user-1', 'user-3'],
        commentCount: 5,
        createdAt: testDate,
      );

      expect(post.id, 'p-2');
      expect(post.userPhotoUrl, 'https://example.com/photo.jpg');
      expect(post.imageUrl, 'https://example.com/image.jpg');
      expect(post.likes, ['user-1', 'user-3']);
      expect(post.commentCount, 5);
    });
  });

  group('CommentModel', () {
    test('constructor sets all required fields', () {
      final comment = CommentModel(
        id: 'c-1',
        postId: 'post-1',
        userId: 'user-1',
        userName: 'Alice',
        content: 'Great job!',
        createdAt: testDate,
      );

      expect(comment.id, 'c-1');
      expect(comment.postId, 'post-1');
      expect(comment.userId, 'user-1');
      expect(comment.userName, 'Alice');
      expect(comment.content, 'Great job!');
      expect(comment.createdAt, testDate);
    });

    test('constructor allows null userPhotoUrl', () {
      final comment = CommentModel(
        postId: 'post-1',
        userId: 'user-1',
        userName: 'Bob',
        content: 'Nice!',
        createdAt: testDate,
      );

      expect(comment.userPhotoUrl, isNull);
    });
  });
}
