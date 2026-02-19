import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exercise_log_model.dart';

class ExerciseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addExercise(ExerciseLog exercise) async {
    await _firestore.collection('exercises').doc(exercise.id).set(
          exercise.toMap(),
        );
  }

  Stream<List<ExerciseLog>> getExercises() {
    return _firestore.collection('exercises').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => ExerciseLog.fromMap(doc.data()))
              .toList(),
        );
  }
}
