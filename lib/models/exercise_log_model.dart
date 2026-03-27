import 'dart:convert';

class ExerciseSet {
  final int setNumber;
  final int reps;
  final double? weight;

  ExerciseSet({
    required this.setNumber,
    required this.reps,
    this.weight,
  });

  Map<String, dynamic> toMap() {
    return {
      'setNumber': setNumber,
      'reps': reps,
      'weight': weight,
    };
  }

  factory ExerciseSet.fromMap(Map<String, dynamic> map) {
    return ExerciseSet(
      setNumber: map['setNumber'] as int? ?? 0,
      reps: map['reps'] as int? ?? 0,
      weight: (map['weight'] as num?)?.toDouble(),
    );
  }
}

class ExerciseLogModel {
  final String? id;
  final String userId;
  final String exerciseName;
  final String? category;
  final List<ExerciseSet> sets;
  final String? notes;
  final DateTime date;

  ExerciseLogModel({
    this.id,
    required this.userId,
    required this.exerciseName,
    this.category,
    required this.sets,
    this.notes,
    required this.date,
  });

  factory ExerciseLogModel.fromMap(Map<String, dynamic> map) {
    List<ExerciseSet> parseSets(dynamic raw) {
      if (raw == null) return [];
      final List<dynamic> list;
      if (raw is String) {
        list = jsonDecode(raw) as List<dynamic>;
      } else if (raw is List) {
        list = raw;
      } else {
        return [];
      }
      return list
          .map((s) => ExerciseSet.fromMap(s as Map<String, dynamic>))
          .toList();
    }

    return ExerciseLogModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      exerciseName: map['exerciseName'] as String? ?? '',
      category: map['category'] as String?,
      sets: parseSets(map['sets']),
      notes: map['notes'] as String?,
      date: DateTime.fromMillisecondsSinceEpoch(
          map['date'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'exerciseName': exerciseName,
      'category': category,
      'sets': jsonEncode(sets.map((s) => s.toMap()).toList()),
      'notes': notes,
      'date': date.millisecondsSinceEpoch,
    };
  }

  int get totalVolume {
    return sets.fold(
        0, (sum, set) => sum + (set.reps * (set.weight ?? 0)).toInt());
  }

  int get totalReps {
    return sets.fold(0, (sum, set) => sum + set.reps);
  }
}
