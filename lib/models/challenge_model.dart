import '../services/database_service.dart';

class ChallengeModel {
  final String? id;
  final String title;
  final String description;
  final String type;
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

  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: map['id'] as String?,
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      type: map['type'] as String? ?? '',
      targetValue: map['targetValue'] as int? ?? 0,
      badgeId: map['badgeId'] as String? ?? '',
      startDate: DateTime.fromMillisecondsSinceEpoch(
          map['startDate'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      endDate: DateTime.fromMillisecondsSinceEpoch(
          map['endDate'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      participants: List<String>.from(
          DatabaseService.decodeList(map['participants'] as String?)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'targetValue': targetValue,
      'badgeId': badgeId,
      'startDate': startDate.millisecondsSinceEpoch,
      'endDate': endDate.millisecondsSinceEpoch,
      'participants': DatabaseService.encodeList(participants),
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
      'completed': completed ? 1 : 0,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory UserChallengeProgress.fromMap(Map<String, dynamic> map) {
    return UserChallengeProgress(
      userId: map['userId'] as String? ?? '',
      challengeId: map['challengeId'] as String? ?? '',
      currentValue: map['currentValue'] as int? ?? 0,
      completed: (map['completed'] as int? ?? 0) == 1,
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'] as int)
          : null,
    );
  }
}
