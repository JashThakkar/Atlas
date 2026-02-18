import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/challenge_service.dart';
import '../models/challenge_model.dart';

final challengeServiceProvider = Provider<ChallengeService>((ref) => ChallengeService());

final activeChallengesProvider = StreamProvider<List<ChallengeModel>>((ref) {
  final challengeService = ref.watch(challengeServiceProvider);
  return challengeService.getActiveChallenges();
});
