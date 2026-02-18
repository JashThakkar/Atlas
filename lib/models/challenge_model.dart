import 'package:cloud_firestore/cloud_firestore.dart';

class ChallengeModel {
  final String? id;
  final String title;
  final String description;
  final String type; // Total Workouts, Total Minutes, etc.
  final int targetValue;
  final String badgeId;
  final DateTime startDate;
  final DateTime endDate;
  final List<String> participants;
  
  ChallengeModel({
    this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.badgeId,
    required this.startDate,
    required this.endDate,
    this.participants = const [],
  });
  
  factory ChallengeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChallengeModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      type: data['type'] ?? '',
      targetValue: data['targetValue'] ?? 0,
      badgeId: data['badgeId'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      participants: List<String>.from(data['participants'] ?? []),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'badgeId': badgeId,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'participants': participants,
    };
  }
  
  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }
}

class UserChallengeProgress {
  final String userId;
  final String challengeId;
  final int currentValue;
  final bool completed;
  final DateTime? completedAt;
  
  UserChallengeProgress({
    required this.userId,
    required this.challengeId,
    required this.currentValue,
    this.completed = false,
    this.completedAt,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'challengeId': challengeId,
      'currentValue': currentValue,
      'completed': completed,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }
  
  factory UserChallengeProgress.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgress(
      userId: map['userId'] ?? '',
      challengeId: map['challengeId'] ?? '',
      currentValue: map['currentValue'] ?? 0,
      completed: map['completed'] ?? false,
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
