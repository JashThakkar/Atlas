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
  final bool isAdmin;
  
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
    this.isAdmin = false,
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
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // Fallback to now if missing
      lastWorkoutDate: data['lastWorkoutDate'] != null 
          ? (data['lastWorkoutDate'] as Timestamp).toDate() 
          : null,
      isAdmin: data['isAdmin'] ?? false,
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'displayNameLower': displayName.toLowerCase(),
      'photoUrl': photoUrl,
      'bio': bio,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badges': badges,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastWorkoutDate': lastWorkoutDate != null 
          ? Timestamp.fromDate(lastWorkoutDate!) 
          : null,
      'isAdmin': isAdmin,
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
    bool? isAdmin,
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
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
