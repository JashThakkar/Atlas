import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../core/constants.dart';

class SocialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Posts
  Future<String> createPost(PostModel post) async {
    final docRef = await _firestore
        .collection(AppConstants.postsCollection)
        .add(post.toFirestore());
    return docRef.id;
  }
  
  Stream<List<PostModel>> getFeed({int limit = 50}) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }
  
  Stream<List<PostModel>> getUserPosts(String userId) {
    return _firestore
        .collection(AppConstants.postsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList());
  }
  
  Future<void> likePost(String postId, String userId) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
      'likes': FieldValue.arrayUnion([userId]),
    });
  }
  
  Future<void> unlikePost(String postId, String userId) async {
    await _firestore.collection(AppConstants.postsCollection).doc(postId).update({
      'likes': FieldValue.arrayRemove([userId]),
    });
  }
  
  // Comments
  Future<void> addComment(CommentModel comment) async {
    await _firestore
        .collection(AppConstants.commentsCollection)
        .add(comment.toFirestore());
    
    // Increment comment count on post
    await _firestore
        .collection(AppConstants.postsCollection)
        .doc(comment.postId)
        .update({
      'commentCount': FieldValue.increment(1),
    });
  }
  
  Stream<List<CommentModel>> getPostComments(String postId) {
    return _firestore
        .collection(AppConstants.commentsCollection)
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CommentModel.fromFirestore(doc))
            .toList());
  }
  
  // Friends
  Future<void> sendFriendRequest(String fromUserId, String toUserId) async {
    await _firestore.collection(AppConstants.friendsCollection).add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': 'pending',
      'createdAt': Timestamp.now(),
    });
  }
  
  Future<void> acceptFriendRequest(String friendshipId) async {
    await _firestore
        .collection(AppConstants.friendsCollection)
        .doc(friendshipId)
        .update({'status': 'accepted'});
  }
  
  Future<void> rejectFriendRequest(String friendshipId) async {
    await _firestore
        .collection(AppConstants.friendsCollection)
        .doc(friendshipId)
        .delete();
  }

  Future<void> cancelFriendRequest(String friendshipId) =>
      rejectFriendRequest(friendshipId);
  
  Stream<List<String>> getUserFriends(String userId) {
    return _firestore
        .collection(AppConstants.friendsCollection)
        .where('status', isEqualTo: 'accepted')
        .snapshots()
        .map((snapshot) {
      final friendIds = <String>[];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['fromUserId'] == userId) {
          friendIds.add(data['toUserId']);
        } else if (data['toUserId'] == userId) {
          friendIds.add(data['fromUserId']);
        }
      }
      return friendIds;
    });
  }

  // Incoming friend requests for a user
  Stream<List<Map<String, dynamic>>> getIncomingFriendRequests(String userId) {
    return _firestore
        .collection(AppConstants.friendsCollection)
        .where('toUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList());
  }

  // Outgoing friend requests sent by a user
  Stream<List<Map<String, dynamic>>> getOutgoingFriendRequests(String userId) {
    return _firestore
        .collection(AppConstants.friendsCollection)
        .where('fromUserId', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              return {'id': doc.id, ...doc.data()};
            }).toList());
  }
  
  // Search users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final snapshot = await _firestore
        .collection(AppConstants.usersCollection)
        .where('displayName', isGreaterThanOrEqualTo: query)
        .where('displayName', isLessThanOrEqualTo: '$query\uf8ff')
        .limit(20)
        .get();
    
    return snapshot.docs.map((doc) {
      return {
        'uid': doc.id,
        ...doc.data(),
      };
    }).toList();
  }

  // Messaging
  Future<void> sendMessage(String chatId, String senderId, String content) async {
    final message = Message(
      chatId: chatId,
      senderId: senderId,
      content: content,
      timestamp: DateTime.now(),
    );

    final batch = _firestore.batch();

    // Add message
    final messageRef = _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .doc();
    batch.set(messageRef, message.toFirestore());

    // Update chat room metadata
    final chatRef = _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId);
    batch.set(chatRef, {
      'lastMessage': content,
      'lastMessageTime': Timestamp.fromDate(message.timestamp),
      'lastMessageSenderId': senderId,
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Stream<List<Message>> getChatMessages(String chatId, {int limit = 50}) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Message.fromFirestore(doc)).toList());
  }

  Future<void> getOrCreateChatRoom(
      String chatId, List<String> participants) async {
    final chatRef = _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId);

    final doc = await chatRef.get();
    if (!doc.exists) {
      await chatRef.set({
        'participants': participants,
        'lastMessage': null,
        'lastMessageTime': null,
        'lastMessageSenderId': null,
      });
    }
  }

  Stream<List<ChatRoom>> getUserChatRooms(String userId) {
    return _firestore
        .collection(AppConstants.messagesCollection)
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ChatRoom.fromFirestore(doc)).toList());
  }

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final messages = await _firestore
        .collection(AppConstants.messagesCollection)
        .doc(chatId)
        .collection('messages')
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}

