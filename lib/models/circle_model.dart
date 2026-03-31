import 'package:cloud_firestore/cloud_firestore.dart';

class CircleMember {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int activityScore;
  final int rank;

  CircleMember({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    this.activityScore = 0,
    this.rank = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'activityScore': activityScore,
    };
  }

  factory CircleMember.fromMap(Map<String, dynamic> map) {
    return CircleMember(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? '',
      photoUrl: map['photoUrl'],
      activityScore: map['activityScore'] ?? 0,
    );
  }
}

class CircleModel {
  final String? id;
  final String name;
  final String description;
  final String creatorId;
  final String inviteCode;
  final List<String> memberIds;
  final Map<String, int> activityScores;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CircleModel({
    this.id,
    required this.name,
    required this.description,
    required this.creatorId,
    required this.inviteCode,
    required this.memberIds,
    this.activityScores = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory CircleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CircleModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      creatorId: data['creatorId'] ?? '',
      inviteCode: data['inviteCode'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      activityScores: Map<String, int>.from(
        (data['activityScores'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, (v as num).toInt()),
            ) ??
            {},
      ),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'creatorId': creatorId,
      'inviteCode': inviteCode,
      'memberIds': memberIds,
      'activityScores': activityScores,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  List<CircleMember> get rankedMembers {
    final members = memberIds.map((uid) {
      return CircleMember(
        userId: uid,
        displayName: uid,
        activityScore: activityScores[uid] ?? 0,
      );
    }).toList();

    members.sort((a, b) => b.activityScore.compareTo(a.activityScore));

    return members
        .asMap()
        .entries
        .map((e) => CircleMember(
              userId: e.value.userId,
              displayName: e.value.displayName,
              photoUrl: e.value.photoUrl,
              activityScore: e.value.activityScore,
              rank: e.key + 1,
            ))
        .toList();
  }

  CircleModel copyWith({
    String? name,
    String? description,
    List<String>? memberIds,
    Map<String, int>? activityScores,
    DateTime? updatedAt,
  }) {
    return CircleModel(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      creatorId: creatorId,
      inviteCode: inviteCode,
      memberIds: memberIds ?? this.memberIds,
      activityScores: activityScores ?? this.activityScores,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
