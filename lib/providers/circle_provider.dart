import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/circle_service.dart';
import '../models/circle_model.dart';

final circleServiceProvider =
    Provider<CircleService>((ref) => CircleService());

final userCirclesProvider =
    StreamProvider.autoDispose.family<List<CircleModel>, String>((ref, userId) {
  return ref.watch(circleServiceProvider).getUserCircles(userId);
});

final circleDetailProvider =
    StreamProvider.autoDispose.family<CircleModel?, String>((ref, circleId) {
  return ref.watch(circleServiceProvider).getCircle(circleId);
});
