class PracticeSession {
  final int? id;
  final int pieceId;
  final DateTime timestamp;
  final int? measuresLearned;
  final int? currentBpm;
  final String? notes;

  const PracticeSession({
    this.id,
    required this.pieceId,
    required this.timestamp,
    this.measuresLearned,
    this.currentBpm,
    this.notes,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'piece_id': pieceId,
    'timestamp': timestamp.toIso8601String(),
    'measures_learned': measuresLearned,
    'current_bpm': currentBpm,
    'notes': notes,
  };

  factory PracticeSession.fromMap(Map<String, dynamic> map) => PracticeSession(
    id: map['id'] as int?,
    pieceId: map['piece_id'] as int,
    timestamp: DateTime.parse(map['timestamp'] as String),
    measuresLearned: map['measures_learned'] as int?,
    currentBpm: map['current_bpm'] as int?,
    notes: map['notes'] as String?,
  );
}
