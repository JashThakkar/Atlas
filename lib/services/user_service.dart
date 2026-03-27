import 'dart:io';
import '../models/user_model.dart';
import 'database_service.dart';

class UserService {
  final DatabaseService _db = DatabaseService();

  Future<UserModel?> getUserById(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserModel.fromMap(rows.first);
  }

  Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final db = await _db.database;
    await db.update(
      'users',
      userData,
      where: 'id = ?',
      whereArgs: [userId],
    );
    _db.notify('users');
  }

  /// Saves the picked image file path locally as the user's photo URL.
  /// Returns the file path so callers can use it immediately.
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final photoUrl = imageFile.path;
    await updateUserProfile(userId, {'photoUrl': photoUrl});
    return photoUrl;
  }

  Future<bool> checkAdminStatus(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      columns: ['isAdmin'],
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return false;
    return (rows.first['isAdmin'] as int? ?? 0) == 1;
  }

  Future<void> awardBadge(String userId, String badgeId) async {
    final user = await getUserById(userId);
    if (user == null) return;
    if (user.badges.contains(badgeId)) return;
    final updatedBadges = [...user.badges, badgeId];
    await updateUserProfile(
      userId,
      {'badges': DatabaseService.encodeList(updatedBadges)},
    );
  }

  Stream<UserModel?> watchUser(String userId) async* {
    await for (final _ in _db.watchTable('users')) {
      yield await getUserById(userId);
    }
  }

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'displayName LIKE ?',
      whereArgs: ['$query%'],
      limit: 20,
    );
    return rows.toList();
  }
}
