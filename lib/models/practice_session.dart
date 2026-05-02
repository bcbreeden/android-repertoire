class PracticeSession {
  final int? id;
  final int pieceId;
  final DateTime timestamp;
  final int? measuresLearned;
  final int? currentBpm;
  final String? notes;
  final int? durationSeconds;

  const PracticeSession({
    this.id,
    required this.pieceId,
    required this.timestamp,
    this.measuresLearned,
    this.currentBpm,
    this.notes,
    this.durationSeconds,
  });

  PracticeSession copyWith({
    int? id,
    int? pieceId,
    DateTime? timestamp,
    int? measuresLearned,
    bool clearMeasuresLearned = false,
    int? currentBpm,
    bool clearCurrentBpm = false,
    String? notes,
    bool clearNotes = false,
    int? durationSeconds,
    bool clearDurationSeconds = false,
  }) =>
      PracticeSession(
        id: id ?? this.id,
        pieceId: pieceId ?? this.pieceId,
        timestamp: timestamp ?? this.timestamp,
        measuresLearned: clearMeasuresLearned ? null : (measuresLearned ?? this.measuresLearned),
        currentBpm: clearCurrentBpm ? null : (currentBpm ?? this.currentBpm),
        notes: clearNotes ? null : (notes ?? this.notes),
        durationSeconds: clearDurationSeconds ? null : (durationSeconds ?? this.durationSeconds),
      );

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'piece_id': pieceId,
    'timestamp': timestamp.toIso8601String(),
    'measures_learned': measuresLearned,
    'current_bpm': currentBpm,
    'notes': notes,
    'duration_seconds': durationSeconds,
  };

  factory PracticeSession.fromMap(Map<String, dynamic> map) => PracticeSession(
    id: map['id'] as int?,
    pieceId: map['piece_id'] as int,
    timestamp: DateTime.parse(map['timestamp'] as String),
    measuresLearned: map['measures_learned'] as int?,
    currentBpm: map['current_bpm'] as int?,
    notes: map['notes'] as String?,
    durationSeconds: map['duration_seconds'] as int?,
  );
}
