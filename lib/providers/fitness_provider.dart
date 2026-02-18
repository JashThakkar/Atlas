import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/fitness_service.dart';
import '../services/exercise_api_service.dart';
import '../models/exercise_log_model.dart';
import '../models/body_metric_model.dart';
import '../models/workout_model.dart';

final fitnessServiceProvider = Provider<FitnessService>((ref) => FitnessService());
final exerciseAPIServiceProvider = Provider<ExerciseAPIService>((ref) => ExerciseAPIService());

final exerciseLogsProvider = StreamProvider.family<List<ExerciseLogModel>, String>((ref, userId) {
  final fitnessService = ref.watch(fitnessServiceProvider);
  return fitnessService.getExerciseLogs(userId);
});

final bodyMetricsProvider = StreamProvider.family<List<BodyMetricModel>, ({String userId, String metricType})>((ref, params) {
  final fitnessService = ref.watch(fitnessServiceProvider);
  return fitnessService.getBodyMetrics(params.userId, params.metricType);
});

final userWorkoutsProvider = StreamProvider.family<List<WorkoutModel>, String>((ref, userId) {
  final fitnessService = ref.watch(fitnessServiceProvider);
  return fitnessService.getUserWorkouts(userId);
});

final userStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, userId) {
  final fitnessService = ref.watch(fitnessServiceProvider);
  return fitnessService.getUserStats(userId);
});
