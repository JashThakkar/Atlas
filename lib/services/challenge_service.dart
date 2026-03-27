import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/challenge_model.dart';
import 'database_service.dart';
import 'user_service.dart';

class ChallengeService {
  final DatabaseService _db = DatabaseService();
  final UserService _userService = UserService();
  final _uuid = const Uuid();

  Stream<List<ChallengeModel>> getActiveChallenges() async* {
    await for (final _ in _db.watchTable('challenges')) {
      yield await _queryActiveChallenges();
    }
  }

  Future<List<ChallengeModel>> _queryActiveChallenges() async {
    final db = await _db.database;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rows = await db.query(
      'challenges',
      where: 'endDate > ?',
      whereArgs: [now],
      orderBy: 'endDate ASC',
    );
    return rows.map(ChallengeModel.fromMap).toList();
  }

  Future<String> createChallenge(ChallengeModel challenge) async {
    final db = await _db.database;
    final map = challenge.toMap();
    final id = map['id'] as String? ?? _uuid.v4();
    map['id'] = id;
    await db.insert('challenges', map);
    _db.notify('challenges');
    return id;
  }

  Future<void> deleteChallenge(String challengeId) async {
    final db = await _db.database;
    await db.delete('challenges', where: 'id = ?', whereArgs: [challengeId]);
    _db.notify('challenges');
  }

  Future<void> joinChallenge(String challengeId, String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'challenges',
      where: 'id = ?',
      whereArgs: [challengeId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final challenge = ChallengeModel.fromMap(rows.first);
    if (challenge.participants.contains(userId)) return;
    final updated = [...challenge.participants, userId];
    await db.update(
      'challenges',
      {'participants': DatabaseService.encodeList(updated)},
      where: 'id = ?',
      whereArgs: [challengeId],
    );
    // Upsert user progress entry
    await db.insert(
      'user_challenge_progress',
      {
        'id': _uuid.v4(),
        'userId': userId,
        'challengeId': challengeId,
        'currentValue': 0,
        'completed': 0,
        'completedAt': null,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
    _db.notify('challenges');
    _db.notify('user_challenge_progress');
  }

  Future<void> updateChallengeProgress(
    String userId,
    String challengeId,
    int incrementValue,
  ) async {
    final db = await _db.database;
    final progressRows = await db.query(
      'user_challenge_progress',
      where: 'userId = ? AND challengeId = ?',
      whereArgs: [userId, challengeId],
      limit: 1,
    );
    if (progressRows.isEmpty) return;

    final progress = UserChallengeProgress.fromMap(progressRows.first);
    final newValue = progress.currentValue + incrementValue;

    final challengeRows = await db.query(
      'challenges',
      where: 'id = ?',
      whereArgs: [challengeId],
      limit: 1,
    );
    if (challengeRows.isEmpty) return;

    final challenge = ChallengeModel.fromMap(challengeRows.first);
    final completed = newValue >= challenge.targetValue;

    await db.update(
      'user_challenge_progress',
      {
        'currentValue': newValue,
        'completed': completed ? 1 : 0,
        'completedAt':
            completed ? DateTime.now().millisecondsSinceEpoch : null,
      },
      where: 'userId = ? AND challengeId = ?',
      whereArgs: [userId, challengeId],
    );
    _db.notify('user_challenge_progress');

    if (completed) {
      await _userService.awardBadge(userId, challenge.badgeId);
    }
  }

  Future<UserChallengeProgress?> getUserChallengeProgress(
    String userId,
    String challengeId,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'user_challenge_progress',
      where: 'userId = ? AND challengeId = ?',
      whereArgs: [userId, challengeId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UserChallengeProgress.fromMap(rows.first);
  }

  Future<List<UserChallengeProgress>> getUserCompletedChallenges(
      String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'user_challenge_progress',
      where: 'userId = ? AND completed = 1',
      whereArgs: [userId],
    );
    return rows.map(UserChallengeProgress.fromMap).toList();
  }
}
