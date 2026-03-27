import 'package:uuid/uuid.dart';
import '../models/exercise_log_simple.dart';
import 'database_service.dart';

class ExerciseService {
  final DatabaseService _db = DatabaseService();
  final _uuid = const Uuid();

  Future<void> addExercise(ExerciseLog exercise) async {
    final db = await _db.database;
    final map = exercise.toMap();
    if ((map['id'] as String?)?.isEmpty ?? true) {
      map['id'] = _uuid.v4();
    }
    await db.insert('exercises', map);
    _db.notify('exercises');
  }

  Stream<List<ExerciseLog>> getExercises() async* {
    await for (final _ in _db.watchTable('exercises')) {
      final db = await _db.database;
      final rows = await db.query('exercises', orderBy: 'date DESC');
      yield rows.map(ExerciseLog.fromMap).toList();
    }
  }
}