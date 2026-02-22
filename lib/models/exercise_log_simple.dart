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
      'date': date.millisecondsSinceEpoch,
    };
  }
  
  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      id: map['id'] ?? '',
      exerciseName: map['exerciseName'] ?? '',
      duration: map['duration'] ?? 0,
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] ?? 0),
    );
  }
}