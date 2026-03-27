import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/exercise_log_model.dart';
import '../models/body_metric_model.dart';
import '../models/workout_model.dart';
import 'database_service.dart';

class FitnessService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  // ── Exercise Logs ──────────────────────────────────────────────────────────

  Future<void> addExerciseLog(ExerciseLogModel log) async {
    final db = await _db.database;
    final map = log.toMap();
    map['id'] ??= _uuid.v4();
    await db.insert('exercise_logs', map);
    _db.notify('exercise_logs');
    await _updateUserWorkoutStreak(log.userId);
    await _incrementUserStat(log.userId, 'totalExercises', 1);
  }

  Stream<List<ExerciseLogModel>> getExerciseLogs(String userId) async* {
    await for (final _ in _db.watchTable('exercise_logs')) {
      yield await _queryExerciseLogs(userId);
    }
  }

  Future<List<ExerciseLogModel>> _queryExerciseLogs(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercise_logs',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'date DESC',
    );
    return rows.map(ExerciseLogModel.fromMap).toList();
  }

  Future<List<ExerciseLogModel>> getExerciseLogsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _db.database;
    final rows = await db.query(
      'exercise_logs',
      where: 'userId = ? AND date >= ? AND date <= ?',
      whereArgs: [
        userId,
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'date DESC',
    );
    return rows.map(ExerciseLogModel.fromMap).toList();
  }

  // ── Body Metrics ───────────────────────────────────────────────────────────

  Future<void> addBodyMetric(BodyMetricModel metric) async {
    final db = await _db.database;
    final map = metric.toMap();
    map['id'] ??= _uuid.v4();
    await db.insert('body_metrics', map);
    _db.notify('body_metrics');
  }

  Stream<List<BodyMetricModel>> getBodyMetrics(
      String userId, String metricType) async* {
    await for (final _ in _db.watchTable('body_metrics')) {
      yield await _queryBodyMetrics(userId, metricType);
    }
  }

  Future<List<BodyMetricModel>> _queryBodyMetrics(
      String userId, String metricType) async {
    final db = await _db.database;
    final rows = await db.query(
      'body_metrics',
      where: 'userId = ? AND metricType = ?',
      whereArgs: [userId, metricType],
      orderBy: 'date ASC',
    );
    return rows.map(BodyMetricModel.fromMap).toList();
  }

  // ── Workouts ───────────────────────────────────────────────────────────────

  Future<String> createWorkout(WorkoutModel workout) async {
    final db = await _db.database;
    final map = workout.toMap();
    final id = map['id'] as String? ?? _uuid.v4();
    map['id'] = id;
    await db.insert('workouts', map);
    _db.notify('workouts');
    return id;
  }

  Future<void> updateWorkout(
      String workoutId, Map<String, dynamic> updates) async {
    final db = await _db.database;
    await db.update(
      'workouts',
      updates,
      where: 'id = ?',
      whereArgs: [workoutId],
    );
    _db.notify('workouts');
  }

  Stream<List<WorkoutModel>> getUserWorkouts(String userId) async* {
    await for (final _ in _db.watchTable('workouts')) {
      yield await _queryUserWorkouts(userId);
    }
  }

  Future<List<WorkoutModel>> _queryUserWorkouts(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'workouts',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
    return rows.map(WorkoutModel.fromMap).toList();
  }

  Future<void> completeWorkout(
    String workoutId,
    int intensityRating,
    int durationMinutes, {
    required String userId,
  }) async {
    final db = await _db.database;
    await db.update(
      'workouts',
      {
        'completedAt': DateTime.now().millisecondsSinceEpoch,
        'intensityRating': intensityRating,
        'durationMinutes': durationMinutes,
      },
      where: 'id = ?',
      whereArgs: [workoutId],
    );
    _db.notify('workouts');
    await _incrementUserStat(userId, 'totalWorkouts', 1);
    await _incrementUserStat(userId, 'totalMinutes', durationMinutes);
  }

  // ── User Workout Streak ────────────────────────────────────────────────────

  Future<void> _updateUserWorkoutStreak(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final data = rows.first;
    final lastWorkoutMs = data['lastWorkoutDate'] as int?;
    final lastWorkoutDate =
        lastWorkoutMs != null
            ? DateTime.fromMillisecondsSinceEpoch(lastWorkoutMs)
            : null;
    final currentStreak = data['currentStreak'] as int? ?? 0;
    final longestStreak = data['longestStreak'] as int? ?? 0;

    final now = DateTime.now();
    int newStreak = currentStreak;

    if (lastWorkoutDate == null) {
      newStreak = 1;
    } else {
      final daysSince = now.difference(lastWorkoutDate).inDays;
      if (daysSince == 1) {
        newStreak = currentStreak + 1;
      } else if (daysSince > 1) {
        newStreak = 1;
      }
    }

    await db.update(
      'users',
      {
        'lastWorkoutDate': now.millisecondsSinceEpoch,
        'currentStreak': newStreak,
        'longestStreak':
            newStreak > longestStreak ? newStreak : longestStreak,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
    _db.notify('users');
  }

  // ── User Stats ─────────────────────────────────────────────────────────────

  Future<void> _incrementUserStat(
      String userId, String field, int amount) async {
    final db = await _db.database;
    final rows = await db.query(
      'user_stats',
      where: 'userId = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) {
      await db.insert('user_stats', {
        'userId': userId,
        field: amount,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
    } else {
      final current = rows.first[field] as int? ?? 0;
      await db.update(
        'user_stats',
        {
          field: current + amount,
          'lastUpdated': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'userId = ?',
        whereArgs: [userId],
      );
    }
    _db.notify('user_stats');
  }

  Stream<Map<String, dynamic>> watchUserStats(String userId) async* {
    await for (final _ in _db.watchTable('user_stats')) {
      yield await getUserStats(userId);
    }
  }

  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final db = await _db.database;
      final rows = await db.query(
        'user_stats',
        where: 'userId = ?',
        whereArgs: [userId],
        limit: 1,
      );
      if (rows.isNotEmpty) {
        final data = rows.first;
        return {
          'totalWorkouts': data['totalWorkouts'] ?? 0,
          'totalExercises': data['totalExercises'] ?? 0,
          'totalMinutes': data['totalMinutes'] ?? 0,
          'currentStreak': data['currentStreak'] ?? 0,
          'longestStreak': data['longestStreak'] ?? 0,
          'weeklyGoal': data['weeklyGoal'] ?? 3,
          'favoriteExercise': data['favoriteExercise'] ?? 'Not set yet',
        };
      }
      // Seed default stats row and return defaults.
      await db.insert('user_stats', {
        'userId': userId,
        'totalWorkouts': 0,
        'totalExercises': 0,
        'totalMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'weeklyGoal': 3,
        'favoriteExercise': 'Not set yet',
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return {
        'totalWorkouts': 0,
        'totalExercises': 0,
        'totalMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'weeklyGoal': 3,
        'favoriteExercise': 'Not set yet',
      };
    } catch (e) {
      debugPrint('❌ Error getting user stats for $userId: $e');
      return {
        'totalWorkouts': 0,
        'totalExercises': 0,
        'totalMinutes': 0,
        'currentStreak': 0,
        'longestStreak': 0,
        'weeklyGoal': 3,
        'favoriteExercise': 'Not set yet',
      };
    }
  }
}
