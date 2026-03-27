import '../services/database_service.dart';

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

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['id'] as String,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      badges: List<String>.from(
          DatabaseService.decodeList(map['badges'] as String?)),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
      lastWorkoutDate: map['lastWorkoutDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastWorkoutDate'] as int)
          : null,
      isAdmin: (map['isAdmin'] as int? ?? 0) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'badges': DatabaseService.encodeList(badges),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastWorkoutDate': lastWorkoutDate?.millisecondsSinceEpoch,
      'isAdmin': isAdmin ? 1 : 0,
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
