import '../services/database_service.dart';

class PostModel {
  final String? id;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    this.id,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    this.imageUrl,
    this.likes = const [],
    this.commentCount = 0,
    required this.createdAt,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      content: map['content'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      likes: List<String>.from(
          DatabaseService.decodeList(map['likes'] as String?)),
      commentCount: map['commentCount'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'imageUrl': imageUrl,
      'likes': DatabaseService.encodeList(likes),
      'commentCount': commentCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  bool isLikedBy(String userId) {
    return likes.contains(userId);
  }
}

class CommentModel {
  final String? id;
  final String postId;
  final String userId;
  final String userName;
  final String? userPhotoUrl;
  final String content;
  final DateTime createdAt;

  CommentModel({
    this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    this.userPhotoUrl,
    required this.content,
    required this.createdAt,
  });

  factory CommentModel.fromMap(Map<String, dynamic> map) {
    return CommentModel(
      id: map['id'] as String?,
      postId: map['postId'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhotoUrl: map['userPhotoUrl'] as String?,
      content: map['content'] as String? ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'postId': postId,
      'userId': userId,
      'userName': userName,
      'userPhotoUrl': userPhotoUrl,
      'content': content,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
