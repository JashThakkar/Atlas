import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final int currentStreak;
  final int longestStreak;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime? lastWorkoutDate;
  
  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    this.bio,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.badges = const [],
    required this.createdAt,
    this.lastWorkoutDate,
  });
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      currentStreak: data['currentStreak'] ?? 0,
      longestStreak: data['longestStreak'] ?? 0,
      badges: List<String>.from(data['badges'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastWorkoutDate: data['lastWorkoutDate'] != null 
          ? (data['lastWorkoutDate'] as Timestamp).toDate() 
          : null,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastWorkoutDate': lastWorkoutDate != null 
          ? Timestamp.fromDate(lastWorkoutDate!) 
          : null,
    };
  }
  
  UserModel copyWith({
    String? displayName,
    String? photoUrl,
    String? bio,
    int? currentStreak,
    int? longestStreak,
    List<String>? badges,
    DateTime? lastWorkoutDate,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      badges: badges ?? this.badges,
      createdAt: createdAt,
      lastWorkoutDate: lastWorkoutDate ?? this.lastWorkoutDate,
    );
  }
}
