class ExerciseLog {
  final String id;
  final String exerciseName;
  final int duration;
  final DateTime date;

  ExerciseLog({
    required this.id,
    required this.exerciseName,
    required this.duration,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'exerciseName': exerciseName,
      'duration': duration,
      'date': date.toIso8601String(),
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'],
      exerciseName: map['exerciseName'],
      duration: map['duration'],
      date: DateTime.parse(map['date']),
    );
  }
}
