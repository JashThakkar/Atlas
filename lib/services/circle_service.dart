import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/circle_model.dart';
import '../core/constants.dart';

class CircleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Generates a unique 6-character alphanumeric invite code.
  /// Characters that look similar (I, O, 0, 1) are excluded to prevent
  /// user confusion when typing or reading the code aloud.
  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// Creates a new private circle and adds the creator as first member.
  Future<String> createCircle({
    required String creatorId,
    required String name,
    required String description,
  }) async {
    final inviteCode = _generateInviteCode();

    final circle = CircleModel(
      name: name,
      description: description,
      creatorId: creatorId,
      inviteCode: inviteCode,
      memberIds: [creatorId],
      activityScores: {creatorId: 0},
      createdAt: DateTime.now(),
    );

    final docRef = await _firestore
        .collection(AppConstants.circlesCollection)
        .add(circle.toFirestore());

    return docRef.id;
  }

  /// Joins a circle using an invite code. Returns the circle ID on success.
  Future<String> joinCircleByCode({
    required String userId,
    required String inviteCode,
  }) async {
    final snapshot = await _firestore
        .collection(AppConstants.circlesCollection)
        .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      throw Exception('Invalid invite code. Please check and try again.');
    }

    final doc = snapshot.docs.first;
    final circle = CircleModel.fromFirestore(doc);

    if (circle.memberIds.contains(userId)) {
      return doc.id;
    }

    await _firestore
        .collection(AppConstants.circlesCollection)
        .doc(doc.id)
        .update({
      'memberIds': FieldValue.arrayUnion([userId]),
      'activityScores.$userId': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return doc.id;
  }

  /// Returns a stream of circles the user belongs to.
  Stream<List<CircleModel>> getUserCircles(String userId) {
    return _firestore
        .collection(AppConstants.circlesCollection)
        .where('memberIds', arrayContains: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map(CircleModel.fromFirestore).toList());
  }

  /// Returns a stream for a single circle document.
  Stream<CircleModel?> getCircle(String circleId) {
    return _firestore
        .collection(AppConstants.circlesCollection)
        .doc(circleId)
        .snapshots()
        .map((doc) => doc.exists ? CircleModel.fromFirestore(doc) : null);
  }

  /// Increments the activity score for a user within all their circles.
  /// [minutes] is the number of minutes of experience to add.
  Future<void> incrementActivityScore(String userId, {int minutes = 0}) async {
    if (minutes <= 0) return;
    final snapshot = await _firestore
        .collection(AppConstants.circlesCollection)
        .where('memberIds', arrayContains: userId)
        .get();

    final batch = _firestore.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'activityScores.$userId': FieldValue.increment(minutes),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  /// Leaves a circle. If the user is the only member, the circle is deleted.
  Future<void> leaveCircle({
    required String circleId,
    required String userId,
  }) async {
    final doc = await _firestore
        .collection(AppConstants.circlesCollection)
        .doc(circleId)
        .get();

    if (!doc.exists) return;
    final circle = CircleModel.fromFirestore(doc);

    if (circle.memberIds.length <= 1) {
      await _firestore
          .collection(AppConstants.circlesCollection)
          .doc(circleId)
          .delete();
      return;
    }

    final updatedScores = Map<String, dynamic>.from(circle.activityScores)
      ..remove(userId);

    await _firestore
        .collection(AppConstants.circlesCollection)
        .doc(circleId)
        .update({
      'memberIds': FieldValue.arrayRemove([userId]),
      'activityScores': updatedScores,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetches display names for a list of user IDs from the users collection.
  Future<Map<String, String>> getMemberDisplayNames(
      List<String> memberIds) async {
    if (memberIds.isEmpty) return {};

    final Map<String, String> names = {};
    // Firestore `whereIn` supports up to 30 items.
    const chunkSize = 30;
    for (var i = 0; i < memberIds.length; i += chunkSize) {
      final chunk = memberIds.sublist(i, min(i + chunkSize, memberIds.length));
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final doc in snapshot.docs) {
        names[doc.id] = (doc.data()['displayName'] as String?) ?? 'Unknown';
      }
    }
    return names;
  }
}
