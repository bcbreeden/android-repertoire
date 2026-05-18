import '../utils/constants.dart';

class Piece {
  final int? id;
  final String name;
  final String? composer;
  final int? measures;
  final int? measuresLearned;
  final int? currentTempo;
  final int? targetTempo;
  final String? notes;
  final String? book;
  final int? page;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Stage achievement timestamps (set once when first reached)
  final DateTime? learningAt;
  final DateTime? repertoireAt;

  const Piece({
    this.id,
    required this.name,
    this.composer,
    this.measures,
    this.measuresLearned,
    this.currentTempo,
    this.targetTempo,
    this.notes,
    this.book,
    this.page,
    this.status = kStageLearning,
    required this.createdAt,
    required this.updatedAt,
    this.learningAt,
    this.repertoireAt,
  });

  // Computed properties
  double get measuresLearnedPct {
    if (measuresLearned == null || measures == null || measures! == 0) {
      return 0.0;
    }
    return (measuresLearned! / measures! * 100).clamp(0.0, 100.0);
  }

  double get tempoPct {
    if (currentTempo == null || targetTempo == null || targetTempo == 0) {
      return 0.0;
    }
    return (currentTempo! / targetTempo! * 100).clamp(0.0, 100.0);
  }

  int get daysAtStage {
    final stageTimestamp = timestampForStage(status);
    if (stageTimestamp == null) return 0;
    return DateTime.now().difference(stageTimestamp).inDays;
  }

  bool get isRepertoire => status == kStageRepertoire;

  int get stageIndex => kStageOrder.indexOf(status);

  DateTime? timestampForStage(String stage) {
    switch (stage) {
      case kStageLearning:
        return learningAt;
      case kStageRepertoire:
        return repertoireAt;
      default:
        return null;
    }
  }

  Piece copyWith({
    int? id,
    String? name,
    String? composer,
    int? measures,
    int? measuresLearned,
    int? currentTempo,
    int? targetTempo,
    String? notes,
    String? book,
    int? page,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? learningAt,
    DateTime? repertoireAt,
    bool clearComposer = false,
    bool clearMeasuresLearned = false,
    bool clearCurrentTempo = false,
    bool clearTargetTempo = false,
    bool clearNotes = false,
    bool clearBook = false,
    bool clearPage = false,
  }) {
    return Piece(
      id: id ?? this.id,
      name: name ?? this.name,
      composer: clearComposer ? null : (composer ?? this.composer),
      measures: measures ?? this.measures,
      measuresLearned: clearMeasuresLearned
          ? null
          : (measuresLearned ?? this.measuresLearned),
      currentTempo:
          clearCurrentTempo ? null : (currentTempo ?? this.currentTempo),
      targetTempo: clearTargetTempo ? null : (targetTempo ?? this.targetTempo),
      notes: clearNotes ? null : (notes ?? this.notes),
      book: clearBook ? null : (book ?? this.book),
      page: clearPage ? null : (page ?? this.page),
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      learningAt: learningAt ?? this.learningAt,
      repertoireAt: repertoireAt ?? this.repertoireAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'composer': composer,
      'measures': measures,
      'measures_learned': measuresLearned,
      'current_tempo': currentTempo,
      'target_tempo': targetTempo,
      'notes': notes,
      'book': book,
      'page': page,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'learning_at': learningAt?.toIso8601String(),
      'repertoire_at': repertoireAt?.toIso8601String(),
    };
  }

  factory Piece.fromMap(Map<String, dynamic> map) {
    return Piece(
      id: map['id'] as int?,
      name: map['name'] as String,
      composer: map['composer'] as String?,
      measures: map['measures'] as int?,
      measuresLearned: map['measures_learned'] as int?,
      currentTempo: map['current_tempo'] as int?,
      targetTempo: map['target_tempo'] as int?,
      notes: map['notes'] as String?,
      book: map['book'] as String?,
      page: map['page'] as int?,
      status: map['status'] as String? ?? kStageLearning,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      learningAt: map['learning_at'] != null
          ? DateTime.parse(map['learning_at'] as String)
          : null,
      repertoireAt: map['repertoire_at'] != null
          ? DateTime.parse(map['repertoire_at'] as String)
          : null,
    );
  }

  @override
  String toString() => 'Piece(id: $id, name: $name, status: $status)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Piece && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
