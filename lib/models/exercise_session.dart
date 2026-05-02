class ExerciseSession {
  final int? id;
  final int exerciseId;
  final DateTime timestamp;
  final int? bpm;
  final String? notes;
  final int? durationSeconds;

  const ExerciseSession({
    this.id,
    required this.exerciseId,
    required this.timestamp,
    this.bpm,
    this.notes,
    this.durationSeconds,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'exercise_id': exerciseId,
        'timestamp': timestamp.toIso8601String(),
        'bpm': bpm,
        'notes': notes,
        'duration_seconds': durationSeconds,
      };

  factory ExerciseSession.fromMap(Map<String, dynamic> map) => ExerciseSession(
        id: map['id'] as int?,
        exerciseId: map['exercise_id'] as int,
        timestamp: DateTime.parse(map['timestamp'] as String),
        bpm: map['bpm'] as int?,
        notes: map['notes'] as String?,
        durationSeconds: map['duration_seconds'] as int?,
      );
}
