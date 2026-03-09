import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_log_model.dart';
import '../models/body_metric_model.dart';
import '../models/workout_model.dart';
import '../core/constants.dart';

class FitnessService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Exercise Logs
  Future<void> addExerciseLog(ExerciseLogModel log) async {
    await _firestore
        .collection(AppConstants.exerciseLogsCollection)
        .add(log.toFirestore());
    
    // Update user's last workout date and streak
    await _updateUserWorkoutStreak(log.userId);

    // Increment totalExercises in user_stats document
    await _firestore
        .collection(AppConstants.userStatsCollection)
        .doc(log.userId)
        .set({
      'totalExercises': FieldValue.increment(1),
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
  
  Stream<List<ExerciseLogModel>> getExerciseLogs(String userId) {
    return _firestore
        .collection(AppConstants.exerciseLogsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExerciseLogModel.fromFirestore(doc))
            .toList());
  }
  
  Future<List<ExerciseLogModel>> getExerciseLogsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final snapshot = await _firestore
        .collection(AppConstants.exerciseLogsCollection)
        .where('userId', isEqualTo: userId)
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .orderBy('date', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => ExerciseLogModel.fromFirestore(doc))
        .toList();
  }
  
  // Body Metrics
  Future<void> addBodyMetric(BodyMetricModel metric) async {
    await _firestore
        .collection(AppConstants.bodyMetricsCollection)
        .add(metric.toFirestore());
  }
  
  Stream<List<BodyMetricModel>> getBodyMetrics(String userId, String metricType) {
    return _firestore
        .collection(AppConstants.bodyMetricsCollection)
        .where('userId', isEqualTo: userId)
        .where('metricType', isEqualTo: metricType)
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BodyMetricModel.fromFirestore(doc))
            .toList());
  }
  
  // Workouts
  Future<String> createWorkout(WorkoutModel workout) async {
    final docRef = await _firestore
        .collection(AppConstants.workoutsCollection)
        .add(workout.toFirestore());
    return docRef.id;
  }
  
  Future<void> updateWorkout(String workoutId, Map<String, dynamic> updates) async {
    await _firestore
        .collection(AppConstants.workoutsCollection)
        .doc(workoutId)
        .update(updates);
  }
  
  Stream<List<WorkoutModel>> getUserWorkouts(String userId) {
    return _firestore
        .collection(AppConstants.workoutsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WorkoutModel.fromFirestore(doc))
            .toList());
  }
  
  // Complete workout and provide intensity rating
  Future<void> completeWorkout(
    String workoutId,
    int intensityRating,
    int durationMinutes, {
    required String userId,
  }) async {
    final batch = _firestore.batch();

    final workoutRef = _firestore
        .collection(AppConstants.workoutsCollection)
        .doc(workoutId);
    batch.update(workoutRef, {
      'completedAt': Timestamp.now(),
      'intensityRating': intensityRating,
      'durationMinutes': durationMinutes,
    });

    // Keep user_stats in sync so the dashboard counters reflect the new workout.
    final statsRef = _firestore
        .collection(AppConstants.userStatsCollection)
        .doc(userId);
    batch.set(
      statsRef,
      {
        'totalWorkouts': FieldValue.increment(1),
        'totalMinutes': FieldValue.increment(durationMinutes),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }
  
  // Update user workout streak
  Future<void> _updateUserWorkoutStreak(String userId) async {
    final userDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .get();
    
    if (!userDoc.exists) return;
    
    final data = userDoc.data()!;
    final lastWorkoutDate = data['lastWorkoutDate'] != null
        ? (data['lastWorkoutDate'] as Timestamp).toDate()
        : null;
    final currentStreak = data['currentStreak'] ?? 0;
    final longestStreak = data['longestStreak'] ?? 0;
    
    final now = DateTime.now();
    int newStreak = currentStreak;
    
    if (lastWorkoutDate == null) {
      // First workout
      newStreak = 1;
    } else {
      final daysSinceLastWorkout = now.difference(lastWorkoutDate).inDays;
      
      if (daysSinceLastWorkout == 1) {
        // Continue streak
        newStreak = currentStreak + 1;
      } else if (daysSinceLastWorkout > 1) {
        // Streak broken
        newStreak = 1;
      }
      // If same day, don't change streak
    }
    
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .update({
      'lastWorkoutDate': Timestamp.now(),
      'currentStreak': newStreak,
      'longestStreak': newStreak > longestStreak ? newStreak : longestStreak,
    });
  }
  
  // Watch user statistics as a real-time stream
  Stream<Map<String, dynamic>> watchUserStats(String userId) {
    return _firestore
        .collection(AppConstants.userStatsCollection)
        .doc(userId)
        .snapshots()
        .asyncMap((doc) async {
      if (doc.exists) {
        final data = doc.data()!;
        final totalWorkouts = data['totalWorkouts'] ?? 0;
        final totalMinutes = data['totalMinutes'] ?? 0;

        // Backfill totalMinutes for users who completed workouts before the
        // counter was added. Fire-and-forget: the resulting Firestore write will
        // trigger a new snapshot automatically.
        if (totalMinutes == 0 && totalWorkouts > 0) {
          _backfillTotalMinutes(userId);
        }

        return {
          'totalWorkouts': totalWorkouts,
          'totalExercises': data['totalExercises'] ?? 0,
          'totalMinutes': totalMinutes,
          'currentStreak': data['currentStreak'] ?? 0,
          'longestStreak': data['longestStreak'] ?? 0,
          'weeklyGoal': data['weeklyGoal'] ?? 3,
          'favoriteExercise': data['favoriteExercise'] ?? 'Not set yet',
        };
      }
      // No stats document yet — getUserStats will calculate and seed it,
      // causing a second snapshot where the document will exist.
      // This fallback path runs at most once per user.
      return getUserStats(userId);
    });
  }

  /// Recalculates [totalMinutes] from completed workouts and writes the result
  /// back to [AppConstants.userStatsCollection]. Called when the stat doc
  /// exists but [totalMinutes] is still 0 (backfill for pre-fix users).
  Future<void> _backfillTotalMinutes(String userId) async {
    try {
      // Query workouts that have a recorded duration (set on completion).
      final snapshot = await _firestore
          .collection(AppConstants.workoutsCollection)
          .where('userId', isEqualTo: userId)
          .where('durationMinutes', isGreaterThan: 0)
          .get();

      int total = 0;
      for (final doc in snapshot.docs) {
        total += (doc.data()['durationMinutes'] as int? ?? 0);
      }

      if (total > 0) {
        await _firestore
            .collection(AppConstants.userStatsCollection)
            .doc(userId)
            .update({'totalMinutes': total});
        debugPrint('✅ Backfilled totalMinutes=$total for $userId');
      }
    } catch (e) {
      debugPrint('❌ Error backfilling totalMinutes: $e');
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // First try to get from user_stats document (faster and includes default data)
      final statsDoc = await _firestore
          .collection(AppConstants.userStatsCollection)
          .doc(userId)
          .get();
      
      if (statsDoc.exists) {
        final data = statsDoc.data()!;
        return {
          'totalWorkouts': data['totalWorkouts'] ?? 0,
          'totalMinutes': data['totalMinutes'] ?? 0,
          'currentStreak': data['currentStreak'] ?? 0,
          'longestStreak': data['longestStreak'] ?? 0,
          'weeklyGoal': data['weeklyGoal'] ?? 3,
          'favoriteExercise': data['favoriteExercise'] ?? 'Not set yet',
          'totalExercises': data['totalExercises'] ?? 0, // Add this for compatibility
        };
      }
      
      // Fall back to calculating from individual documents if no stats document exists
      debugPrint('📊 No user_stats found for $userId, calculating from workouts...');
      
      // Use durationMinutes > 0 as the proxy for "completed" because
      // Firestore does not support isNull: false queries.
      final workoutsSnapshot = await _firestore
          .collection(AppConstants.workoutsCollection)
          .where('userId', isEqualTo: userId)
          .where('durationMinutes', isGreaterThan: 0)
          .get();
      
      final exerciseLogsSnapshot = await _firestore
          .collection(AppConstants.exerciseLogsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      
      final totalWorkouts = workoutsSnapshot.docs.length;
      final totalExercises = exerciseLogsSnapshot.docs.length;
      
      int totalMinutes = 0;
      for (var doc in workoutsSnapshot.docs) {
        final workout = WorkoutModel.fromFirestore(doc);
        totalMinutes += workout.durationMinutes ?? 0;
      }
      
      final calculatedStats = {
        'totalWorkouts': totalWorkouts,
        'totalExercises': totalExercises,
        'totalMinutes': totalMinutes,
        'currentStreak': 0, // Would need more complex calculation
        'longestStreak': 0, // Would need more complex calculation
        'weeklyGoal': 3, // Default goal
        'favoriteExercise': 'Not set yet',
      };
      
      // Save calculated stats to user_stats document for future use
      await _firestore
          .collection(AppConstants.userStatsCollection)
          .doc(userId)
          .set({
        ...calculatedStats,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      return calculatedStats;
      
    } catch (e) {
      debugPrint('❌ Error getting user stats: $e');
      
      // If it's a network/availability issue, return default stats instead of failing
      if (e.toString().contains('unavailable') || 
          e.toString().contains('deadline-exceeded')) {
        debugPrint('🌐 Network issue detected, returning default stats for offline use');
      }
      
      // Return default stats if everything fails
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
