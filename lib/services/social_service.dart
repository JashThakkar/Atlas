import 'package:uuid/uuid.dart';
import '../models/post_model.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'database_service.dart';

class SocialService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  // ── Posts ──────────────────────────────────────────────────────────────────

  Future<String> createPost(PostModel post) async {
    final db = await _db.database;
    final map = post.toMap();
    final id = map['id'] as String? ?? _uuid.v4();
    map['id'] = id;
    await db.insert('posts', map);
    _db.notify('posts');
    return id;
  }

  Stream<List<PostModel>> getFeed({int limit = 50}) async* {
    await for (final _ in _db.watchTable('posts')) {
      yield await _queryFeed(limit);
    }
  }

  Future<List<PostModel>> _queryFeed(int limit) async {
    final db = await _db.database;
    final rows = await db.query(
      'posts',
      orderBy: 'createdAt DESC',
      limit: limit,
    );
    return rows.map(PostModel.fromMap).toList();
  }

  Stream<List<PostModel>> getUserPosts(String userId) async* {
    await for (final _ in _db.watchTable('posts')) {
      yield await _queryUserPosts(userId);
    }
  }

  Future<List<PostModel>> _queryUserPosts(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'posts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(PostModel.fromMap).toList();
  }

  Stream<PostModel?> getPost(String postId) async* {
    await for (final _ in _db.watchTable('posts')) {
      final db = await _db.database;
      final rows = await db.query(
        'posts',
        where: 'id = ?',
        whereArgs: [postId],
        limit: 1,
      );
      yield rows.isEmpty ? null : PostModel.fromMap(rows.first);
    }
  }

  Future<void> likePost(String postId, String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final post = PostModel.fromMap(rows.first);
    if (post.likes.contains(userId)) return;
    final updated = [...post.likes, userId];
    await db.update(
      'posts',
      {'likes': DatabaseService.encodeList(updated)},
      where: 'id = ?',
      whereArgs: [postId],
    );
    _db.notify('posts');
  }

  Future<void> unlikePost(String postId, String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'posts',
      where: 'id = ?',
      whereArgs: [postId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final post = PostModel.fromMap(rows.first);
    final updated = post.likes.where((id) => id != userId).toList();
    await db.update(
      'posts',
      {'likes': DatabaseService.encodeList(updated)},
      where: 'id = ?',
      whereArgs: [postId],
    );
    _db.notify('posts');
  }

  // ── Comments ───────────────────────────────────────────────────────────────

  Future<void> addComment(CommentModel comment) async {
    final db = await _db.database;
    final map = comment.toMap();
    map['id'] ??= _uuid.v4();
    await db.insert('comments', map);
    await db.rawUpdate(
      'UPDATE posts SET commentCount = commentCount + 1 WHERE id = ?',
      [comment.postId],
    );
    _db.notify('comments');
    _db.notify('posts');
  }

  Stream<List<CommentModel>> getPostComments(String postId) async* {
    await for (final _ in _db.watchTable('comments')) {
      yield await _queryComments(postId);
    }
  }

  Future<List<CommentModel>> _queryComments(String postId) async {
    final db = await _db.database;
    final rows = await db.query(
      'comments',
      where: 'postId = ?',
      whereArgs: [postId],
      orderBy: 'createdAt ASC',
    );
    return rows.map(CommentModel.fromMap).toList();
  }

  // ── Friends ────────────────────────────────────────────────────────────────

  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    final db = await _db.database;
    final existing = await db.query(
      'friends',
      where: '(fromUserId = ? AND toUserId = ?) OR (fromUserId = ? AND toUserId = ?)',
      whereArgs: [fromUserId, toUserId, toUserId, fromUserId],
      limit: 1,
    );
    if (existing.isNotEmpty) return;
    await db.insert('friends', {
      'id': _uuid.v4(),
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    });
    _db.notify('friends');
  }

  Future<void> acceptFriendRequest(String friendshipId) async {
    final db = await _db.database;
    await db.update(
      'friends',
      {'status': 'accepted'},
      where: 'id = ?',
      whereArgs: [friendshipId],
    );
    _db.notify('friends');
  }

  Future<void> rejectFriendRequest(String friendshipId) async {
    final db = await _db.database;
    await db.delete('friends', where: 'id = ?', whereArgs: [friendshipId]);
    _db.notify('friends');
  }

  Future<void> cancelFriendRequest(String friendshipId) =>
      rejectFriendRequest(friendshipId);

  Stream<List<String>> getUserFriends(String userId) async* {
    await for (final _ in _db.watchTable('friends')) {
      yield await _queryFriendIds(userId);
    }
  }

  Future<List<String>> _queryFriendIds(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'friends',
      where:
          'status = ? AND (fromUserId = ? OR toUserId = ?)',
      whereArgs: ['accepted', userId, userId],
    );
    return rows.map((r) {
      return r['fromUserId'] == userId
          ? r['toUserId'] as String
          : r['fromUserId'] as String;
    }).toList();
  }

  Future<Set<String>> getRelatedUserIds(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'friends',
      where: 'fromUserId = ? OR toUserId = ?',
      whereArgs: [userId, userId],
    );
    final ids = <String>{};
    for (final r in rows) {
      if (r['fromUserId'] == userId) {
        ids.add(r['toUserId'] as String);
      } else {
        ids.add(r['fromUserId'] as String);
      }
    }
    return ids;
  }

  Future<Set<String>> getPendingOutgoingIds(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'friends',
      where: 'fromUserId = ? AND status = ?',
      whereArgs: [userId, 'pending'],
    );
    return rows.map((r) => r['toUserId'] as String).toSet();
  }

  Stream<List<Map<String, dynamic>>> getIncomingFriendRequests(
      String userId) async* {
    await for (final _ in _db.watchTable('friends')) {
      final db = await _db.database;
      final rows = await db.query(
        'friends',
        where: 'toUserId = ? AND status = ?',
        whereArgs: [userId, 'pending'],
      );
      yield rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
  }

  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequests(
      String userId) async* {
    await for (final _ in _db.watchTable('friends')) {
      final db = await _db.database;
      final rows = await db.query(
        'friends',
        where: 'fromUserId = ? AND status = ?',
        whereArgs: [userId, 'pending'],
      );
      yield rows.map((r) => Map<String, dynamic>.from(r)).toList();
    }
  }

  // ── User search ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'displayName LIKE ?',
      whereArgs: ['$query%'],
      limit: 20,
    );
    // Expose the primary key as both 'id' and 'uid' for callers that use either.
    return rows.map((r) {
      final m = Map<String, dynamic>.from(r);
      m['uid'] = m['id'];
      return m;
    }).toList();
  }

  // ── Messaging ──────────────────────────────────────────────────────────────

  Future<void> sendMessage(
      String chatId, String senderId, String content) async {
    final db = await _db.database;
    final now = DateTime.now();
    await db.insert('messages', {
      'id': _uuid.v4(),
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'timestamp': now.millisecondsSinceEpoch,
      'isRead': 0,
    });
    await db.update(
      'chat_rooms',
      {
        'lastMessage': content,
        'lastMessageTime': now.millisecondsSinceEpoch,
        'lastMessageSenderId': senderId,
      },
      where: 'id = ?',
      whereArgs: [chatId],
    );
    _db.notify('messages');
    _db.notify('chat_rooms');
  }

  Stream<List<Message>> getChatMessages(String chatId,
      {int limit = 50}) async* {
    await for (final _ in _db.watchTable('messages')) {
      final db = await _db.database;
      final rows = await db.query(
        'messages',
        where: 'chatId = ?',
        whereArgs: [chatId],
        orderBy: 'timestamp DESC',
        limit: limit,
      );
      yield rows.map(Message.fromMap).toList();
    }
  }

  Future<void> getOrCreateChatRoom(
      String chatId, List<String> participants) async {
    final db = await _db.database;
    final rows = await db.query(
      'chat_rooms',
      where: 'id = ?',
      whereArgs: [chatId],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.insert('chat_rooms', {
        'id': chatId,
        'participants': DatabaseService.encodeList(participants),
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
      });
      _db.notify('chat_rooms');
    }
  }

  Stream<List<ChatRoom>> getUserChatRooms(String userId) async* {
    await for (final _ in _db.watchTable('chat_rooms')) {
      yield await _queryUserChatRooms(userId);
    }
  }

  Future<List<ChatRoom>> _queryUserChatRooms(String userId) async {
    final db = await _db.database;
    final rows = await db.query('chat_rooms');
    return rows
        .map(ChatRoom.fromMap)
        .where((room) => room.participants.contains(userId))
        .toList();
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final db = await _db.database;
    await db.update(
      'messages',
      {'isRead': 1},
      where: 'chatId = ? AND senderId != ? AND isRead = 0',
      whereArgs: [chatId, userId],
    );
    _db.notify('messages');
  }
}

