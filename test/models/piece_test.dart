import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/models/piece.dart';
import 'package:repertoire/utils/constants.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Piece _piece({
  int? id,
  String name = 'Test Piece',
  String? composer,
  int measures = 100,
  int? measuresLearned,
  int? currentTempo,
  int? targetTempo,
  String? notes,
  String status = kStagelearning,
  DateTime? learningAt,
  DateTime? notePerfectionAt,
  DateTime? dynamicsPerfectionAt,
  DateTime? tempoPerfectionAt,
  DateTime? repertoireAt,
}) {
  final now = DateTime(2024, 6, 15, 12, 0);
  return Piece(
    id: id,
    name: name,
    composer: composer,
    measures: measures,
    measuresLearned: measuresLearned,
    currentTempo: currentTempo,
    targetTempo: targetTempo,
    notes: notes,
    status: status,
    createdAt: now,
    updatedAt: now,
    learningAt: learningAt,
    notePerfectionAt: notePerfectionAt,
    dynamicsPerfectionAt: dynamicsPerfectionAt,
    tempoPerfectionAt: tempoPerfectionAt,
    repertoireAt: repertoireAt,
  );
}

void main() {
  // ── measuresLearnedPct ─────────────────────────────────────────────────────

  group('Piece.measuresLearnedPct', () {
    test('returns 0 when measuresLearned is null', () {
      final p = _piece(measures: 100, measuresLearned: null);
      expect(p.measuresLearnedPct, 0.0);
    });

    test('returns 0 when measures is 0', () {
      final p = _piece(measures: 0, measuresLearned: 0);
      expect(p.measuresLearnedPct, 0.0);
    });

    test('returns 0 when 0 measures learned', () {
      final p = _piece(measures: 100, measuresLearned: 0);
      expect(p.measuresLearnedPct, 0.0);
    });

    test('returns correct percentage for normal case', () {
      final p = _piece(measures: 200, measuresLearned: 50);
      expect(p.measuresLearnedPct, 25.0);
    });

    test('returns 100 when measuresLearned equals measures', () {
      final p = _piece(measures: 80, measuresLearned: 80);
      expect(p.measuresLearnedPct, 100.0);
    });

    test('clamps to 100 when measuresLearned exceeds measures', () {
      final p = _piece(measures: 50, measuresLearned: 75);
      expect(p.measuresLearnedPct, 100.0);
    });

    test('returns fractional percentage correctly', () {
      final p = _piece(measures: 3, measuresLearned: 1);
      expect(p.measuresLearnedPct, closeTo(33.33, 0.01));
    });
  });

  // ── tempoPct ───────────────────────────────────────────────────────────────

  group('Piece.tempoPct', () {
    test('returns 0 when currentTempo is null', () {
      final p = _piece(currentTempo: null, targetTempo: 120);
      expect(p.tempoPct, 0.0);
    });

    test('returns 0 when targetTempo is null', () {
      final p = _piece(currentTempo: 96, targetTempo: null);
      expect(p.tempoPct, 0.0);
    });

    test('returns 0 when targetTempo is 0', () {
      final p = _piece(currentTempo: 96, targetTempo: 0);
      expect(p.tempoPct, 0.0);
    });

    test('returns correct percentage for normal case', () {
      final p = _piece(currentTempo: 96, targetTempo: 120);
      expect(p.tempoPct, 80.0);
    });

    test('returns 100 when currentTempo equals targetTempo', () {
      final p = _piece(currentTempo: 120, targetTempo: 120);
      expect(p.tempoPct, 100.0);
    });

    test('clamps to 100 when currentTempo exceeds targetTempo', () {
      final p = _piece(currentTempo: 150, targetTempo: 120);
      expect(p.tempoPct, 100.0);
    });

    test('returns fractional percentage correctly', () {
      final p = _piece(currentTempo: 60, targetTempo: 90);
      expect(p.tempoPct, closeTo(66.67, 0.01));
    });
  });

  // ── daysAtStage ───────────────────────────────────────────────────────────

  group('Piece.daysAtStage', () {
    test('returns 0 when no timestamp is set for current status', () {
      final p = _piece(status: kStagelearning, learningAt: null);
      expect(p.daysAtStage, 0);
    });

    test('returns 0 when timestamp is today', () {
      final today = DateTime.now();
      final p = _piece(status: kStagelearning, learningAt: today);
      expect(p.daysAtStage, 0);
    });

    test('returns correct days for a past timestamp', () {
      final fiveDaysAgo = DateTime.now().subtract(const Duration(days: 5));
      final p = _piece(status: kStagelearning, learningAt: fiveDaysAgo);
      expect(p.daysAtStage, 5);
    });

    test('uses timestamp for the correct current stage', () {
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final p = _piece(
        status: kStageNotePerfection,
        learningAt: DateTime.now().subtract(const Duration(days: 30)),
        notePerfectionAt: threeDaysAgo,
      );
      expect(p.daysAtStage, 3);
    });
  });

  // ── isRepertoire ──────────────────────────────────────────────────────────

  group('Piece.isRepertoire', () {
    test('true when status is repertoire', () {
      final p = _piece(status: kStageRepertoire);
      expect(p.isRepertoire, isTrue);
    });

    test('false when status is learning', () {
      final p = _piece(status: kStagelearning);
      expect(p.isRepertoire, isFalse);
    });

    test('false when status is note_perfection', () {
      final p = _piece(status: kStageNotePerfection);
      expect(p.isRepertoire, isFalse);
    });
  });

  // ── stageIndex ────────────────────────────────────────────────────────────

  group('Piece.stageIndex', () {
    test('returns 0 for learning', () {
      expect(_piece(status: kStagelearning).stageIndex, 0);
    });

    test('returns 1 for note_perfection', () {
      expect(_piece(status: kStageNotePerfection).stageIndex, 1);
    });

    test('returns 2 for dynamics_perfection', () {
      expect(_piece(status: kStageDynamicsPerfection).stageIndex, 2);
    });

    test('returns 3 for tempo_perfection', () {
      expect(_piece(status: kStageTempoPerfection).stageIndex, 3);
    });

    test('returns 4 for repertoire', () {
      expect(_piece(status: kStageRepertoire).stageIndex, 4);
    });

    test('returns -1 for an unrecognised status', () {
      expect(_piece(status: 'invalid_stage').stageIndex, -1);
    });
  });

  // ── timestampForStage ─────────────────────────────────────────────────────

  group('Piece.timestampForStage', () {
    final ts = DateTime(2024, 1, 10);

    test('returns learningAt for learning', () {
      final p = _piece(learningAt: ts);
      expect(p.timestampForStage(kStagelearning), ts);
    });

    test('returns notePerfectionAt for note_perfection', () {
      final p = _piece(notePerfectionAt: ts);
      expect(p.timestampForStage(kStageNotePerfection), ts);
    });

    test('returns dynamicsPerfectionAt for dynamics_perfection', () {
      final p = _piece(dynamicsPerfectionAt: ts);
      expect(p.timestampForStage(kStageDynamicsPerfection), ts);
    });

    test('returns tempoPerfectionAt for tempo_perfection', () {
      final p = _piece(tempoPerfectionAt: ts);
      expect(p.timestampForStage(kStageTempoPerfection), ts);
    });

    test('returns repertoireAt for repertoire', () {
      final p = _piece(repertoireAt: ts);
      expect(p.timestampForStage(kStageRepertoire), ts);
    });

    test('returns null when timestamp for stage is not set', () {
      final p = _piece(notePerfectionAt: null);
      expect(p.timestampForStage(kStageNotePerfection), isNull);
    });

    test('returns null for an unrecognised stage', () {
      final p = _piece(learningAt: ts);
      expect(p.timestampForStage('unknown'), isNull);
    });
  });

  // ── copyWith ──────────────────────────────────────────────────────────────

  group('Piece.copyWith', () {
    test('returns identical piece when called with no arguments', () {
      final p = _piece(name: 'Original', measures: 64, id: 1);
      final copy = p.copyWith();
      expect(copy.name, 'Original');
      expect(copy.measures, 64);
      expect(copy.id, 1);
    });

    test('updates name', () {
      final p = _piece(name: 'Original');
      expect(p.copyWith(name: 'New Name').name, 'New Name');
    });

    test('updates measures', () {
      final p = _piece(measures: 50);
      expect(p.copyWith(measures: 99).measures, 99);
    });

    test('clearComposer sets composer to null even when composer is provided', () {
      final p = _piece(composer: 'Bach');
      final copy = p.copyWith(composer: 'Beethoven', clearComposer: true);
      expect(copy.composer, isNull);
    });

    test('clearMeasuresLearned sets measuresLearned to null', () {
      final p = _piece(measuresLearned: 40);
      expect(p.copyWith(clearMeasuresLearned: true).measuresLearned, isNull);
    });

    test('clearCurrentTempo sets currentTempo to null', () {
      final p = _piece(currentTempo: 96);
      expect(p.copyWith(clearCurrentTempo: true).currentTempo, isNull);
    });

    test('clearTargetTempo sets targetTempo to null', () {
      final p = _piece(targetTempo: 120);
      expect(p.copyWith(clearTargetTempo: true).targetTempo, isNull);
    });

    test('clearNotes sets notes to null', () {
      final p = _piece(notes: 'some notes');
      expect(p.copyWith(clearNotes: true).notes, isNull);
    });

    test('new optional value wins when clear flag is false', () {
      final p = _piece(composer: 'Bach');
      expect(p.copyWith(composer: 'Chopin').composer, 'Chopin');
    });
  });

  // ── toMap / fromMap round-trip ────────────────────────────────────────────

  group('Piece.toMap', () {
    test('omits id when id is null', () {
      final p = _piece(id: null);
      expect(p.toMap().containsKey('id'), isFalse);
    });

    test('includes id when id is set', () {
      final p = _piece(id: 42);
      expect(p.toMap()['id'], 42);
    });

    test('serialises createdAt and updatedAt to ISO-8601 strings', () {
      final dt = DateTime(2024, 3, 15, 10, 30);
      final p = Piece(
        name: 'Test',
        measures: 50,
        createdAt: dt,
        updatedAt: dt,
      );
      final map = p.toMap();
      expect(map['created_at'], dt.toIso8601String());
      expect(map['updated_at'], dt.toIso8601String());
    });

    test('nullable stage timestamps serialise to null when unset', () {
      final p = _piece();
      final map = p.toMap();
      expect(map['note_perfection_at'], isNull);
      expect(map['dynamics_perfection_at'], isNull);
      expect(map['tempo_perfection_at'], isNull);
      expect(map['repertoire_at'], isNull);
    });

    test('nullable stage timestamps serialise to ISO-8601 when set', () {
      final ts = DateTime(2024, 2, 20);
      final p = _piece(notePerfectionAt: ts);
      expect(p.toMap()['note_perfection_at'], ts.toIso8601String());
    });
  });

  group('Piece.fromMap', () {
    Piece _roundTrip(Piece p) => Piece.fromMap(p.toMap()..['id'] = p.id);

    test('preserves name through round-trip', () {
      expect(_roundTrip(_piece(name: 'Moonlight Sonata')).name, 'Moonlight Sonata');
    });

    test('preserves all nullable fields through round-trip', () {
      final ts = DateTime(2024, 5, 1, 8, 0);
      final p = _piece(
        id: 7,
        composer: 'Debussy',
        measuresLearned: 30,
        currentTempo: 72,
        targetTempo: 96,
        notes: 'Watch dynamics',
        notePerfectionAt: ts,
      );
      final result = _roundTrip(p);
      expect(result.composer, 'Debussy');
      expect(result.measuresLearned, 30);
      expect(result.currentTempo, 72);
      expect(result.targetTempo, 96);
      expect(result.notes, 'Watch dynamics');
      expect(result.notePerfectionAt, ts);
    });

    test('null optional fields remain null through round-trip', () {
      final p = _piece(composer: null, measuresLearned: null, currentTempo: null);
      final result = _roundTrip(p);
      expect(result.composer, isNull);
      expect(result.measuresLearned, isNull);
      expect(result.currentTempo, isNull);
    });

    test('defaults status to learning when key is absent from map', () {
      final map = {
        'name': 'Test',
        'measures': 50,
        'created_at': DateTime(2024, 1, 1).toIso8601String(),
        'updated_at': DateTime(2024, 1, 1).toIso8601String(),
      };
      final p = Piece.fromMap(map);
      expect(p.status, kStagelearning);
    });

    test('parses date strings from ISO-8601', () {
      final dt = DateTime(2024, 7, 4, 14, 30, 0);
      final map = {
        'name': 'Test',
        'measures': 50,
        'created_at': dt.toIso8601String(),
        'updated_at': dt.toIso8601String(),
      };
      final p = Piece.fromMap(map);
      expect(p.createdAt, dt);
    });
  });

  // ── Equality ──────────────────────────────────────────────────────────────

  group('Piece equality', () {
    test('two pieces with the same id are equal', () {
      final a = _piece(id: 5, name: 'A');
      final b = _piece(id: 5, name: 'B');
      expect(a, equals(b));
    });

    test('two pieces with different ids are not equal', () {
      final a = _piece(id: 1);
      final b = _piece(id: 2);
      expect(a, isNot(equals(b)));
    });

    test('piece with null id is not equal to piece with non-null id', () {
      final a = _piece(id: null);
      final b = _piece(id: 1);
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent with equality', () {
      final a = _piece(id: 10, name: 'A');
      final b = _piece(id: 10, name: 'B');
      expect(a.hashCode, b.hashCode);
    });
  });
}
