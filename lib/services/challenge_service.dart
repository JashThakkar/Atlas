import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/challenge_model.dart';
import '../core/constants.dart';

class ChallengeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get active challenges
  Stream<List<ChallengeModel>> getActiveChallenges() {
    final now = DateTime.now();
    return _firestore
        .collection(AppConstants.challengesCollection)
        .where('endDate', isGreaterThan: Timestamp.fromDate(now))
        .orderBy('endDate', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChallengeModel.fromFirestore(doc))
            .toList());
  }
  
  // Join challenge
  Future<void> joinChallenge(String challengeId, String userId) async {
    await _firestore
        .collection(AppConstants.challengesCollection)
        .doc(challengeId)
        .update({
      'participants': FieldValue.arrayUnion([userId]),
    });
    
    // Create user progress entry
    await _firestore
        .collection('user_challenge_progress')
        .doc('${userId}_$challengeId')
        .set({
      'userId': userId,
      'challengeId': challengeId,
      'currentValue': 0,
      'completed': false,
    });
  }
  
  // Update challenge progress
  Future<void> updateChallengeProgress(
    String userId,
    String challengeId,
    int incrementValue,
  ) async {
    final docRef = _firestore
        .collection('user_challenge_progress')
        .doc('${userId}_$challengeId');
    
    final doc = await docRef.get();
    if (!doc.exists) return;
    
    final currentValue = doc.data()?['currentValue'] ?? 0;
    final newValue = currentValue + incrementValue;
    
    // Get challenge target to check completion
    final challengeDoc = await _firestore
        .collection(AppConstants.challengesCollection)
        .doc(challengeId)
        .get();
    
    if (!challengeDoc.exists) return;
    
    final challenge = ChallengeModel.fromFirestore(challengeDoc);
    final completed = newValue >= challenge.targetValue;
    
    await docRef.update({
      'currentValue': newValue,
      'completed': completed,
      'completedAt': completed ? Timestamp.now() : null,
    });
    
    // Award badge if completed
    if (completed) {
      await _awardBadge(userId, challenge.badgeId);
    }
  }
  
  // Get user's challenge progress
  Future<UserChallengeProgress?> getUserChallengeProgress(
    String userId,
    String challengeId,
  ) async {
    final doc = await _firestore
        .collection('user_challenge_progress')
        .doc('${userId}_$challengeId')
        .get();
    
    if (!doc.exists) return null;
    
    return UserChallengeProgress.fromMap(doc.data()!);
  }
  
  // Award badge to user
  Future<void> _awardBadge(String userId, String badgeId) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }
  
  // Get user's completed challenges
  Future<List<UserChallengeProgress>> getUserCompletedChallenges(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('user_challenge_progress')
        .where('userId', isEqualTo: userId)
        .where('completed', isEqualTo: true)
        .get();
    
    return snapshot.docs
        .map((doc) => UserChallengeProgress.fromMap(doc.data()))
        .toList();
  }
}
