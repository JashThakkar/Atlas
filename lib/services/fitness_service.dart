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
    int durationMinutes,
  ) async {
    await _firestore
        .collection(AppConstants.workoutsCollection)
        .doc(workoutId)
        .update({
      'completedAt': Timestamp.now(),
      'intensityRating': intensityRating,
      'durationMinutes': durationMinutes,
    });
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
  
  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final workoutsSnapshot = await _firestore
        .collection(AppConstants.workoutsCollection)
        .where('userId', isEqualTo: userId)
        .where('completedAt', isNull: false)
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
    
    return {
      'totalWorkouts': totalWorkouts,
      'totalExercises': totalExercises,
      'totalMinutes': totalMinutes,
    };
  }
}
