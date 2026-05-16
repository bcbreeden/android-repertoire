import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/database/database_helper.dart';
import 'package:repertoire/models/piece.dart';
import 'package:repertoire/models/practice_session.dart';
import 'package:repertoire/utils/constants.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Piece _piece({
  String name = 'Test Piece',
  String? composer,
  int measures = 100,
  String status = kStageLearning,
  int? measuresLearned,
  int? currentTempo,
  int? targetTempo,
  DateTime? learningAt,
  DateTime? repertoireAt,
}) {
  final now = DateTime(2024, 6, 1, 12, 0);
  return Piece(
    name: name,
    composer: composer,
    measures: measures,
    status: status,
    measuresLearned: measuresLearned,
    currentTempo: currentTempo,
    targetTempo: targetTempo,
    createdAt: now,
    updatedAt: now,
    learningAt: learningAt ?? now,
    repertoireAt: repertoireAt,
  );
}

PracticeSession _session(int pieceId, {DateTime? timestamp, int? measuresLearned, int? bpm}) =>
    PracticeSession(
      pieceId: pieceId,
      timestamp: timestamp ?? DateTime.now(),
      measuresLearned: measuresLearned,
      currentBpm: bpm,
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Wipe all tables so each test begins with a clean slate.
    final db = await DatabaseHelper.instance.database;
    await db.delete('practice_sessions');
    await db.delete('pieces');
    await db.delete('app_opens');
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  // ── insertPiece / getPieceById ────────────────────────────────────────────

  group('insertPiece / getPieceById', () {
    test('inserted piece can be retrieved by id', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(name: 'Für Elise'));
      final result = await DatabaseHelper.instance.getPieceById(id);
      expect(result, isNotNull);
      expect(result!.name, 'Für Elise');
      expect(result.id, id);
    });

    test('getPieceById returns null for a non-existent id', () async {
      final result = await DatabaseHelper.instance.getPieceById(999999);
      expect(result, isNull);
    });

    test('inserted piece preserves all fields', () async {
      final ts = DateTime(2024, 4, 10, 8, 0);
      final original = Piece(
        name: 'Clair de Lune',
        composer: 'Debussy',
        measures: 144,
        measuresLearned: 30,
        currentTempo: 54,
        targetTempo: 108,
        notes: 'Watch the rubato',
        status: kStageLearning,
        createdAt: ts,
        updatedAt: ts,
        learningAt: ts,
      );
      final id = await DatabaseHelper.instance.insertPiece(original);
      final result = await DatabaseHelper.instance.getPieceById(id);
      expect(result!.composer, 'Debussy');
      expect(result.measures, 144);
      expect(result.measuresLearned, 30);
      expect(result.currentTempo, 54);
      expect(result.targetTempo, 108);
      expect(result.notes, 'Watch the rubato');
      expect(result.status, kStageLearning);
    });
  });

  // ── getAllPieces ──────────────────────────────────────────────────────────

  group('getAllPieces', () {
    test('returns empty list when no pieces exist', () async {
      final pieces = await DatabaseHelper.instance.getAllPieces();
      expect(pieces, isEmpty);
    });

    test('returns all inserted pieces', () async {
      await DatabaseHelper.instance.insertPiece(_piece(name: 'A'));
      await DatabaseHelper.instance.insertPiece(_piece(name: 'B'));
      await DatabaseHelper.instance.insertPiece(_piece(name: 'C'));
      final pieces = await DatabaseHelper.instance.getAllPieces();
      expect(pieces.length, 3);
    });

    test('pieces are ordered by updated_at descending', () async {
      final early = DateTime(2024, 1, 1);
      final late_ = DateTime(2024, 6, 1);
      await DatabaseHelper.instance.insertPiece(
        Piece(name: 'Older', measures: 50, createdAt: early, updatedAt: early),
      );
      await DatabaseHelper.instance.insertPiece(
        Piece(name: 'Newer', measures: 50, createdAt: late_, updatedAt: late_),
      );
      final pieces = await DatabaseHelper.instance.getAllPieces();
      expect(pieces.first.name, 'Newer');
      expect(pieces.last.name, 'Older');
    });
  });

  // ── getPiecesByStatus ─────────────────────────────────────────────────────

  group('getPiecesByStatus', () {
    test('returns only pieces matching the given status', () async {
      await DatabaseHelper.instance.insertPiece(_piece(name: 'L1', status: kStageLearning));
      await DatabaseHelper.instance.insertPiece(_piece(name: 'L2', status: kStageLearning));
      await DatabaseHelper.instance.insertPiece(_piece(name: 'R1', status: kStageRepertoire));
      final results = await DatabaseHelper.instance.getPiecesByStatus(kStageLearning);
      expect(results.length, 2);
      expect(results.every((p) => p.status == kStageLearning), isTrue);
    });

    test('returns empty list when no pieces match the status', () async {
      await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final results = await DatabaseHelper.instance.getPiecesByStatus(kStageRepertoire);
      expect(results, isEmpty);
    });
  });

  // ── updatePiece ───────────────────────────────────────────────────────────

  group('updatePiece', () {
    test('updates the name and reads back the new value', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(name: 'Old Name'));
      final original = await DatabaseHelper.instance.getPieceById(id);
      await DatabaseHelper.instance.updatePiece(original!.copyWith(name: 'New Name'));
      final updated = await DatabaseHelper.instance.getPieceById(id);
      expect(updated!.name, 'New Name');
    });

    test('updating a piece does not affect other pieces', () async {
      final id1 = await DatabaseHelper.instance.insertPiece(_piece(name: 'Piece A'));
      final id2 = await DatabaseHelper.instance.insertPiece(_piece(name: 'Piece B'));
      final a = await DatabaseHelper.instance.getPieceById(id1);
      await DatabaseHelper.instance.updatePiece(a!.copyWith(name: 'Piece A Updated'));
      final b = await DatabaseHelper.instance.getPieceById(id2);
      expect(b!.name, 'Piece B');
    });
  });

  // ── deletePiece ───────────────────────────────────────────────────────────

  group('deletePiece', () {
    test('piece is gone after deletion', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      await DatabaseHelper.instance.deletePiece(id);
      final result = await DatabaseHelper.instance.getPieceById(id);
      expect(result, isNull);
    });

    test('deleting one piece does not remove others', () async {
      final id1 = await DatabaseHelper.instance.insertPiece(_piece(name: 'Keep'));
      final id2 = await DatabaseHelper.instance.insertPiece(_piece(name: 'Delete'));
      await DatabaseHelper.instance.deletePiece(id2);
      final kept = await DatabaseHelper.instance.getPieceById(id1);
      expect(kept, isNotNull);
      expect(kept!.name, 'Keep');
    });

    test('deleting a non-existent id does not throw', () async {
      expect(() => DatabaseHelper.instance.deletePiece(999999), returnsNormally);
    });

    test('cascade deletes practice sessions for the piece', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      await DatabaseHelper.instance.insertPracticeSession(_session(id));
      await DatabaseHelper.instance.insertPracticeSession(_session(id));
      await DatabaseHelper.instance.deletePiece(id);
      final sessions = await DatabaseHelper.instance.getAllPracticeSessions();
      expect(sessions.where((s) => s.pieceId == id), isEmpty);
    });
  });

  // ── advancePieceStage ─────────────────────────────────────────────────────

  group('advancePieceStage', () {
    test('advances learning piece to repertoire', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.advancePieceStage(p!);
      expect(result!.status, kStageRepertoire);
    });

    test('sets repertoireAt timestamp on first advance to repertoire', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.advancePieceStage(p!);
      expect(result!.repertoireAt, isNotNull);
    });

    test('preserves existing repertoireAt timestamp on re-advance', () async {
      final existingTs = DateTime(2023, 12, 1);
      final id = await DatabaseHelper.instance.insertPiece(
        _piece(status: kStageLearning, repertoireAt: existingTs),
      );
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.advancePieceStage(p!);
      expect(result!.repertoireAt, existingTs);
    });

    test('returns piece unchanged when already at repertoire (last stage)', () async {
      final id = await DatabaseHelper.instance.insertPiece(
        _piece(status: kStageRepertoire, repertoireAt: DateTime(2024, 1, 1)),
      );
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.advancePieceStage(p!);
      expect(result!.status, kStageRepertoire);
    });

    test('persists the advanced stage to the database', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final p = await DatabaseHelper.instance.getPieceById(id);
      await DatabaseHelper.instance.advancePieceStage(p!);
      final fromDb = await DatabaseHelper.instance.getPieceById(id);
      expect(fromDb!.status, kStageRepertoire);
    });
  });

  // ── setPieceStage ─────────────────────────────────────────────────────────

  group('setPieceStage', () {
    test('sets piece to an arbitrary stage', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.setPieceStage(p!, kStageRepertoire);
      expect(result!.status, kStageRepertoire);
    });

    test('returns piece unchanged when new status equals current status', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.setPieceStage(p!, kStageLearning);
      expect(result!.status, kStageLearning);
    });

    test('can set stage backwards (e.g. repertoire → learning)', () async {
      final id = await DatabaseHelper.instance.insertPiece(
        _piece(status: kStageRepertoire, repertoireAt: DateTime(2024, 1, 1)),
      );
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.setPieceStage(p!, kStageLearning);
      expect(result!.status, kStageLearning);
    });

    test('preserves existing timestamp when setting a stage that was already reached', () async {
      final existingTs = DateTime(2023, 11, 15);
      final id = await DatabaseHelper.instance.insertPiece(
        _piece(status: kStageLearning, repertoireAt: existingTs),
      );
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.setPieceStage(p!, kStageRepertoire);
      expect(result!.repertoireAt, existingTs);
    });

    test('sets timestamp for a stage being reached for the first time', () async {
      final id = await DatabaseHelper.instance.insertPiece(
        _piece(status: kStageLearning, repertoireAt: null),
      );
      final p = await DatabaseHelper.instance.getPieceById(id);
      final result = await DatabaseHelper.instance.setPieceStage(p!, kStageRepertoire);
      expect(result!.repertoireAt, isNotNull);
    });

    test('persists the new stage to the database', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      final p = await DatabaseHelper.instance.getPieceById(id);
      await DatabaseHelper.instance.setPieceStage(p!, kStageRepertoire);
      final fromDb = await DatabaseHelper.instance.getPieceById(id);
      expect(fromDb!.status, kStageRepertoire);
    });
  });

  // ── recordAppOpen / getStreak ─────────────────────────────────────────────

  group('recordAppOpen', () {
    test('calling twice on the same day does not throw or duplicate', () async {
      await DatabaseHelper.instance.recordAppOpen();
      await DatabaseHelper.instance.recordAppOpen();
      final streak = await DatabaseHelper.instance.getStreak();
      expect(streak, 1);
    });
  });

  group('getStreak', () {
    test('returns 0 when no app_opens records exist', () async {
      final streak = await DatabaseHelper.instance.getStreak();
      expect(streak, 0);
    });

    test('returns 1 when only today is recorded', () async {
      await DatabaseHelper.instance.recordAppOpen();
      final streak = await DatabaseHelper.instance.getStreak();
      expect(streak, 1);
    });

    test('returns 0 when only yesterday is recorded (today missing)', () async {
      final db = await DatabaseHelper.instance.database;
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await db.insert('app_opens', {'date': dateStr});
      final streak = await DatabaseHelper.instance.getStreak();
      expect(streak, 0);
    });

    test('returns 2 for today and yesterday', () async {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.recordAppOpen(); // today
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final dateStr =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await db.insert('app_opens', {'date': dateStr});
      final streak = await DatabaseHelper.instance.getStreak();
      expect(streak, 2);
    });

    test('stops counting at a gap in consecutive days', () async {
      final db = await DatabaseHelper.instance.database;
      await DatabaseHelper.instance.recordAppOpen(); // today
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      final dateStr =
          '${twoDaysAgo.year}-${twoDaysAgo.month.toString().padLeft(2, '0')}-${twoDaysAgo.day.toString().padLeft(2, '0')}';
      await db.insert('app_opens', {'date': dateStr});
      final streak = await DatabaseHelper.instance.getStreak();
      expect(streak, 1);
    });
  });

  // ── practice sessions ─────────────────────────────────────────────────────

  group('insertPracticeSession / getAllPracticeSessions', () {
    test('returns empty list when no sessions exist', () async {
      final sessions = await DatabaseHelper.instance.getAllPracticeSessions();
      expect(sessions, isEmpty);
    });

    test('inserted session is returned by getAllPracticeSessions', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      await DatabaseHelper.instance.insertPracticeSession(
        _session(id, bpm: 88, measuresLearned: 10),
      );
      final sessions = await DatabaseHelper.instance.getAllPracticeSessions();
      expect(sessions.length, 1);
      expect(sessions.first.pieceId, id);
      expect(sessions.first.currentBpm, 88);
    });

    test('sessions are ordered by timestamp descending', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      final early = DateTime(2024, 1, 1);
      final late_ = DateTime(2024, 6, 1);
      await DatabaseHelper.instance.insertPracticeSession(_session(id, timestamp: early));
      await DatabaseHelper.instance.insertPracticeSession(_session(id, timestamp: late_));
      final sessions = await DatabaseHelper.instance.getAllPracticeSessions();
      expect(sessions.first.timestamp, late_);
      expect(sessions.last.timestamp, early);
    });
  });

  group('getLastSessionDateForPiece', () {
    test('returns null when piece has no sessions', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      final date = await DatabaseHelper.instance.getLastSessionDateForPiece(id);
      expect(date, isNull);
    });

    test('returns the most recent session timestamp', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      final early = DateTime(2024, 1, 1);
      final late_ = DateTime(2024, 8, 1);
      await DatabaseHelper.instance.insertPracticeSession(_session(id, timestamp: early));
      await DatabaseHelper.instance.insertPracticeSession(_session(id, timestamp: late_));
      final date = await DatabaseHelper.instance.getLastSessionDateForPiece(id);
      expect(date, late_);
    });
  });

  group('getAllLastSessionDates', () {
    test('returns empty map when no sessions exist', () async {
      final map = await DatabaseHelper.instance.getAllLastSessionDates();
      expect(map, isEmpty);
    });

    test('maps each piece id to its most recent session date', () async {
      final idA = await DatabaseHelper.instance.insertPiece(_piece(name: 'A'));
      final idB = await DatabaseHelper.instance.insertPiece(_piece(name: 'B'));
      final tsA = DateTime(2024, 3, 10);
      final tsB = DateTime(2024, 5, 20);
      await DatabaseHelper.instance.insertPracticeSession(_session(idA, timestamp: tsA));
      await DatabaseHelper.instance.insertPracticeSession(_session(idB, timestamp: tsB));
      final map = await DatabaseHelper.instance.getAllLastSessionDates();
      expect(map[idA], tsA);
      expect(map[idB], tsB);
    });

    test('returns latest timestamp when a piece has multiple sessions', () async {
      final id = await DatabaseHelper.instance.insertPiece(_piece());
      final old = DateTime(2024, 1, 1);
      final recent = DateTime(2024, 9, 1);
      await DatabaseHelper.instance.insertPracticeSession(_session(id, timestamp: old));
      await DatabaseHelper.instance.insertPracticeSession(_session(id, timestamp: recent));
      final map = await DatabaseHelper.instance.getAllLastSessionDates();
      expect(map[id], recent);
    });
  });

  // ── getRecentMilestones ───────────────────────────────────────────────────

  group('getRecentMilestones', () {
    test('returns empty list when no pieces have stage timestamps', () async {
      final now = DateTime(2024, 1, 1);
      await DatabaseHelper.instance.insertPiece(
        Piece(
          name: 'No Timestamps',
          measures: 50,
          createdAt: now,
          updatedAt: now,
        ),
      );
      final milestones = await DatabaseHelper.instance.getRecentMilestones();
      expect(milestones, isEmpty);
    });

    test('returns one milestone per stage timestamp set on a piece', () async {
      final now = DateTime(2024, 5, 1);
      final id = await DatabaseHelper.instance.insertPiece(
        Piece(
          name: 'Multi-stage',
          measures: 80,
          status: kStageRepertoire,
          createdAt: now,
          updatedAt: now,
          learningAt: now.subtract(const Duration(days: 30)),
          repertoireAt: now.subtract(const Duration(days: 5)),
        ),
      );
      expect(id, isPositive);
      final milestones = await DatabaseHelper.instance.getRecentMilestones(limit: 10);
      expect(milestones.length, 2);
    });

    test('respects the limit parameter', () async {
      final now = DateTime(2024, 5, 1);
      await DatabaseHelper.instance.insertPiece(
        Piece(
          name: 'Full Journey',
          measures: 100,
          status: kStageRepertoire,
          createdAt: now,
          updatedAt: now,
          learningAt: now.subtract(const Duration(days: 30)),
          repertoireAt: now.subtract(const Duration(days: 5)),
        ),
      );
      final milestones = await DatabaseHelper.instance.getRecentMilestones(limit: 1);
      expect(milestones.length, 1);
    });

    test('results are sorted by timestamp descending (most recent first)', () async {
      final now = DateTime(2024, 6, 1);
      await DatabaseHelper.instance.insertPiece(
        Piece(
          name: 'Piece',
          measures: 60,
          status: kStageRepertoire,
          createdAt: now,
          updatedAt: now,
          learningAt: now.subtract(const Duration(days: 10)),
          repertoireAt: now.subtract(const Duration(days: 2)),
        ),
      );
      final milestones = await DatabaseHelper.instance.getRecentMilestones(limit: 10);
      final timestamps = milestones
          .map((m) => m['timestamp'] as DateTime)
          .toList();
      for (var i = 0; i < timestamps.length - 1; i++) {
        expect(timestamps[i].isAfter(timestamps[i + 1]), isTrue);
      }
    });
  });

  // ── getStageCountMap ──────────────────────────────────────────────────────

  group('getStageCountMap', () {
    test('returns empty map when no pieces exist', () async {
      final map = await DatabaseHelper.instance.getStageCountMap();
      expect(map, isEmpty);
    });

    test('counts pieces correctly per stage', () async {
      await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      await DatabaseHelper.instance.insertPiece(_piece(status: kStageLearning));
      await DatabaseHelper.instance.insertPiece(_piece(status: kStageRepertoire));
      final map = await DatabaseHelper.instance.getStageCountMap();
      expect(map[kStageLearning], 2);
      expect(map[kStageRepertoire], 1);
    });
  });

  // ── exportAllData / importAllData ─────────────────────────────────────────

  group('exportAllData', () {
    setUp(() async => DatabaseHelper.instance.resetForTesting());

    test('returns a map with all required keys', () async {
      final data = await DatabaseHelper.instance.exportAllData();
      expect(data['version'], 1);
      expect(data['exported_at'], isA<String>());
      expect(data['pieces'], isA<List>());
      expect(data['practice_sessions'], isA<List>());
      expect(data['exercises'], isA<List>());
      expect(data['exercise_sessions'], isA<List>());
    });

    test('includes inserted pieces and sessions', () async {
      final pieceId = await DatabaseHelper.instance.insertPiece(_piece(name: 'Nocturne'));
      await DatabaseHelper.instance.insertPracticeSession(
        PracticeSession(pieceId: pieceId, timestamp: DateTime(2024, 1, 1)),
      );

      final data = await DatabaseHelper.instance.exportAllData();
      final pieces = data['pieces'] as List;
      final sessions = data['practice_sessions'] as List;
      expect(pieces.length, 1);
      expect(pieces.first['name'], 'Nocturne');
      expect(sessions.length, 1);
    });

    test('empty database exports empty lists', () async {
      final data = await DatabaseHelper.instance.exportAllData();
      expect((data['pieces'] as List), isEmpty);
      expect((data['practice_sessions'] as List), isEmpty);
      expect((data['exercises'] as List), isEmpty);
      expect((data['exercise_sessions'] as List), isEmpty);
    });
  });

  group('importAllData', () {
    setUp(() async => DatabaseHelper.instance.resetForTesting());

    test('replaces existing data with imported data', () async {
      // Seed initial data
      await DatabaseHelper.instance.insertPiece(_piece(name: 'Original'));
      expect((await DatabaseHelper.instance.getAllPieces()).length, 1);

      // Build an export-shaped map with different data
      final importData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'pieces': [
          {
            'id': 10,
            'name': 'Imported Piece',
            'composer': null,
            'measures': 64,
            'measures_learned': null,
            'current_tempo': null,
            'target_tempo': null,
            'notes': null,
            'status': kStageLearning,
            'created_at': DateTime(2024, 1, 1).toIso8601String(),
            'updated_at': DateTime(2024, 1, 1).toIso8601String(),
            'learning_at': DateTime(2024, 1, 1).toIso8601String(),
            'repertoire_at': null,
            'backlog_at': null,
          }
        ],
        'practice_sessions': [],
        'exercises': [],
        'exercise_sessions': [],
      };

      await DatabaseHelper.instance.importAllData(importData);

      final pieces = await DatabaseHelper.instance.getAllPieces();
      expect(pieces.length, 1);
      expect(pieces.first.name, 'Imported Piece');
      expect(pieces.first.id, 10);
    });

    test('import round-trip: export then reimport restores same data', () async {
      final pieceId = await DatabaseHelper.instance.insertPiece(
        _piece(name: 'Ballade', measures: 200, status: kStageRepertoire),
      );
      await DatabaseHelper.instance.insertPracticeSession(
        PracticeSession(
          pieceId: pieceId,
          timestamp: DateTime(2024, 6, 1),
          measuresLearned: 100,
        ),
      );

      final exported = await DatabaseHelper.instance.exportAllData();
      await DatabaseHelper.instance.resetForTesting();
      expect((await DatabaseHelper.instance.getAllPieces()), isEmpty);

      await DatabaseHelper.instance.importAllData(exported);

      final pieces = await DatabaseHelper.instance.getAllPieces();
      expect(pieces.length, 1);
      expect(pieces.first.name, 'Ballade');
      expect(pieces.first.status, kStageRepertoire);
      expect(pieces.first.measures, 200);

      final allSessions = await DatabaseHelper.instance.getAllPracticeSessions();
      final sessions = allSessions.where((s) => s.pieceId == pieces.first.id).toList();
      expect(sessions.length, 1);
      expect(sessions.first.measuresLearned, 100);
    });

    test('import clears existing data before inserting', () async {
      await DatabaseHelper.instance.insertPiece(_piece(name: 'To Be Replaced'));
      final importData = {
        'version': 1,
        'exported_at': DateTime.now().toIso8601String(),
        'pieces': [],
        'practice_sessions': [],
        'exercises': [],
        'exercise_sessions': [],
      };
      await DatabaseHelper.instance.importAllData(importData);
      expect((await DatabaseHelper.instance.getAllPieces()), isEmpty);
    });
  });
}
