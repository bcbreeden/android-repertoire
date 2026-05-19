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

  ExerciseSession copyWith({
    int? id,
    int? exerciseId,
    DateTime? timestamp,
    int? bpm,
    bool clearBpm = false,
    String? notes,
    bool clearNotes = false,
    int? durationSeconds,
    bool clearDurationSeconds = false,
  }) =>
      ExerciseSession(
        id: id ?? this.id,
        exerciseId: exerciseId ?? this.exerciseId,
        timestamp: timestamp ?? this.timestamp,
        bpm: clearBpm ? null : (bpm ?? this.bpm),
        notes: clearNotes ? null : (notes ?? this.notes),
        durationSeconds: clearDurationSeconds ? null : (durationSeconds ?? this.durationSeconds),
      );

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
