import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/database/database_helper.dart';
import 'package:repertoire/models/piece.dart';
import 'package:repertoire/providers/piece_provider.dart';
import 'package:repertoire/utils/constants.dart';

// ── Helper ────────────────────────────────────────────────────────────────────

Piece _piece({
  String name = 'Test Piece',
  int measures = 100,
  String status = kStageBacklog,
}) {
  final now = DateTime(2024, 1, 1, 12, 0);
  return Piece(
    name: name,
    measures: measures,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late PieceProvider provider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseHelper.instance.database;
    await db.delete('practice_sessions');
    await db.delete('pieces');
    await db.delete('app_opens');
    provider = PieceProvider();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  // ── Initial state ─────────────────────────────────────────────────────────

  group('initial state', () {
    test('pieces list is empty before any pieces are added', () {
      expect(provider.pieces, isEmpty);
    });

    test('activeFilter defaults to "all"', () {
      expect(provider.activeFilter, 'all');
    });

    test('isLoading is false initially', () {
      expect(provider.isLoading, isFalse);
    });

    test('error is null initially', () {
      expect(provider.error, isNull);
    });

    test('totalCount is 0 initially', () {
      expect(provider.totalCount, 0);
    });

    test('overallProgressPct is 0 initially', () {
      expect(provider.overallProgressPct, 0.0);
    });
  });

  // ── filteredPieces ────────────────────────────────────────────────────────

  group('filteredPieces', () {
    test('returns all pieces when filter is "all"', () async {
      await provider.addPiece(_piece(name: 'A', status: kStageBacklog));
      await provider.addPiece(_piece(name: 'B', status: kStageLearning));
      expect(provider.filteredPieces.length, 2);
    });

    test('returns only pieces matching the active filter', () async {
      await provider.addPiece(_piece(name: 'Backlog', status: kStageBacklog));
      await provider.addPiece(_piece(name: 'Learning', status: kStageLearning));
      provider.setFilter(kStageBacklog);
      expect(provider.filteredPieces.length, 1);
      expect(provider.filteredPieces.first.name, 'Backlog');
    });

    test('returns empty list when filter matches no pieces', () async {
      await provider.addPiece(_piece(status: kStageBacklog));
      provider.setFilter(kStageRepertoire);
      expect(provider.filteredPieces, isEmpty);
    });

    test('returns a copy, not the internal list (mutation safe)', () async {
      await provider.addPiece(_piece());
      final list = provider.filteredPieces;
      list.clear();
      expect(provider.filteredPieces.length, 1);
    });
  });

  // ── setFilter ─────────────────────────────────────────────────────────────

  group('setFilter', () {
    test('changes the active filter', () {
      provider.setFilter(kStageLearning);
      expect(provider.activeFilter, kStageLearning);
    });

    test('calling setFilter with the same value is a no-op (does not double notify)', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setFilter('all'); // same as default
      expect(notifyCount, 0);
    });

    test('calling setFilter with a new value notifies listeners', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.setFilter(kStageBacklog);
      expect(notifyCount, 1);
    });
  });

  // ── addPiece ──────────────────────────────────────────────────────────────

  group('addPiece', () {
    test('adds piece to the in-memory list', () async {
      await provider.addPiece(_piece(name: 'New Piece'));
      expect(provider.pieces.length, 1);
      expect(provider.pieces.first.name, 'New Piece');
    });

    test('returned piece has a non-null id', () async {
      final result = await provider.addPiece(_piece());
      expect(result, isNotNull);
      expect(result!.id, isNotNull);
    });

    test('sets backlogAt on the created piece regardless of input', () async {
      final pieceWithoutTimestamp = Piece(
        name: 'Test',
        measures: 50,
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
        backlogAt: null,
      );
      final result = await provider.addPiece(pieceWithoutTimestamp);
      expect(result!.backlogAt, isNotNull);
    });

    test('multiple pieces accumulate in the list', () async {
      await provider.addPiece(_piece(name: 'A'));
      await provider.addPiece(_piece(name: 'B'));
      await provider.addPiece(_piece(name: 'C'));
      expect(provider.pieces.length, 3);
    });
  });

  // ── updatePiece ───────────────────────────────────────────────────────────

  group('updatePiece', () {
    test('updates the piece in the in-memory list', () async {
      final added = await provider.addPiece(_piece(name: 'Original'));
      await provider.updatePiece(added!.copyWith(name: 'Updated'));
      expect(provider.pieces.first.name, 'Updated');
    });

    test('updates updatedAt to now', () async {
      final past = DateTime(2020, 1, 1);
      final added = await provider.addPiece(_piece());
      final result = await provider.updatePiece(
        added!.copyWith(updatedAt: past),
      );
      expect(result!.updatedAt.isAfter(past), isTrue);
    });

    test('does not change the total number of pieces', () async {
      final added = await provider.addPiece(_piece());
      await provider.updatePiece(added!.copyWith(name: 'Changed'));
      expect(provider.pieces.length, 1);
    });
  });

  // ── deletePiece ───────────────────────────────────────────────────────────

  group('deletePiece', () {
    test('removes the piece from the in-memory list', () async {
      final added = await provider.addPiece(_piece());
      await provider.deletePiece(added!.id!);
      expect(provider.pieces, isEmpty);
    });

    test('returns true on success', () async {
      final added = await provider.addPiece(_piece());
      final result = await provider.deletePiece(added!.id!);
      expect(result, isTrue);
    });

    test('only removes the targeted piece', () async {
      final a = await provider.addPiece(_piece(name: 'Keep'));
      final b = await provider.addPiece(_piece(name: 'Delete'));
      await provider.deletePiece(b!.id!);
      expect(provider.pieces.length, 1);
      expect(provider.pieces.first.name, 'Keep');
    });
  });

  // ── getPieceById ──────────────────────────────────────────────────────────

  group('getPieceById', () {
    test('returns the correct piece when it exists', () async {
      final added = await provider.addPiece(_piece(name: 'Target'));
      final found = provider.getPieceById(added!.id!);
      expect(found, isNotNull);
      expect(found!.name, 'Target');
    });

    test('returns null for a non-existent id', () {
      expect(provider.getPieceById(999999), isNull);
    });
  });

  // ── totalCount / repertoireCount ──────────────────────────────────────────

  group('counts', () {
    test('totalCount reflects all pieces regardless of stage', () async {
      await provider.addPiece(_piece(status: kStageBacklog));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.totalCount, 2);
    });

    test('repertoireCount counts only repertoire-stage pieces', () async {
      await provider.addPiece(_piece(status: kStageBacklog));
      await provider.addPiece(_piece(status: kStageRepertoire));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.repertoireCount, 2);
    });

    test('repertoireCount is 0 when no pieces are in repertoire', () async {
      await provider.addPiece(_piece(status: kStageBacklog));
      expect(provider.repertoireCount, 0);
    });
  });

  // ── overallProgressPct ────────────────────────────────────────────────────

  group('overallProgressPct', () {
    test('returns 0 when there are no pieces', () {
      expect(provider.overallProgressPct, 0.0);
    });

    test('returns 0 when all pieces are in backlog stage', () async {
      await provider.addPiece(_piece(status: kStageBacklog));
      await provider.addPiece(_piece(status: kStageBacklog));
      expect(provider.overallProgressPct, 0.0);
    });

    test('returns 100 when all pieces are in repertoire stage', () async {
      await provider.addPiece(_piece(status: kStageRepertoire));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.overallProgressPct, 100.0);
    });

    test('returns 50 for one backlog and one repertoire piece', () async {
      // backlog stageIndex=0, repertoire stageIndex=2
      // total = 2, maxPossible = 2*2 = 4 → 2/4*100 = 50
      await provider.addPiece(_piece(status: kStageBacklog));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.overallProgressPct, 50.0);
    });

    test('clamps at 100.0', () async {
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.overallProgressPct, lessThanOrEqualTo(100.0));
    });
  });

  // ── stageCounts ───────────────────────────────────────────────────────────

  group('stageCounts', () {
    test('all stages present in map even with 0 counts', () {
      final counts = provider.stageCounts;
      for (final stage in kStageOrder) {
        expect(counts.containsKey(stage), isTrue,
            reason: 'stageCounts is missing key "$stage"');
      }
    });

    test('counts correct number of pieces per stage', () async {
      await provider.addPiece(_piece(status: kStageBacklog));
      await provider.addPiece(_piece(status: kStageBacklog));
      await provider.addPiece(_piece(status: kStageLearning));
      final counts = provider.stageCounts;
      expect(counts[kStageBacklog], 2);
      expect(counts[kStageLearning], 1);
      expect(counts[kStageRepertoire], 0);
    });
  });

  // ── canAddPiece ───────────────────────────────────────────────────────────

  group('canAddPiece', () {
    test('true when piece count is below 3 (free tier)', () async {
      await provider.addPiece(_piece());
      await provider.addPiece(_piece());
      expect(provider.canAddPiece, isTrue);
    });

    test('false when piece count reaches 3 and user is not premium', () async {
      await provider.addPiece(_piece());
      await provider.addPiece(_piece());
      await provider.addPiece(_piece());
      expect(provider.canAddPiece, isFalse);
    });

    test('true when premium and piece count is 3 or more', () async {
      await provider.setPremium(true);
      await provider.addPiece(_piece());
      await provider.addPiece(_piece());
      await provider.addPiece(_piece());
      expect(provider.canAddPiece, isTrue);
    });
  });

  // ── clearError ────────────────────────────────────────────────────────────

  group('clearError', () {
    test('clears error and notifies', () {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      provider.clearError();
      expect(provider.error, isNull);
      expect(notifyCount, 1);
    });
  });

  // ── advanceStage ──────────────────────────────────────────────────────────

  group('advanceStage', () {
    test('advances piece to next stage', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      final result = await provider.advanceStage(added!);
      expect(result, isNotNull);
      expect(result!.status, kStageLearning);
    });

    test('updates piece in the in-memory list', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      await provider.advanceStage(added!);
      expect(provider.pieces.first.status, kStageLearning);
    });

    test('notifies listeners after advancing', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.advanceStage(added!);
      expect(notifyCount, greaterThan(0));
    });

    test('piece stays at repertoire when already at last stage', () async {
      final added = await provider.addPiece(_piece(status: kStageRepertoire));
      await provider.advanceStage(added!);
      expect(provider.pieces.first.status, kStageRepertoire);
    });

    test('sets timestamp for the new stage', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      final result = await provider.advanceStage(added!);
      expect(result!.timestampForStage(kStageLearning), isNotNull);
    });
  });

  // ── setStage ──────────────────────────────────────────────────────────────

  group('setStage', () {
    test('sets piece to the specified stage', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      final result = await provider.setStage(added!, kStageRepertoire);
      expect(result!.status, kStageRepertoire);
    });

    test('updates piece in the in-memory list', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      await provider.setStage(added!, kStageRepertoire);
      expect(provider.pieces.first.status, kStageRepertoire);
    });

    test('notifies listeners', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.setStage(added!, kStageLearning);
      expect(notifyCount, greaterThan(0));
    });

    test('can jump multiple stages forward', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      await provider.setStage(added!, kStageRepertoire);
      expect(provider.pieces.first.status, kStageRepertoire);
    });

    test('preserves first achievement timestamp on re-entry', () async {
      final added = await provider.addPiece(_piece(status: kStageBacklog));
      // First time reaching learning — timestamp is set
      await provider.setStage(added!, kStageLearning);
      final first = provider.pieces.first.timestampForStage(kStageLearning);
      expect(first, isNotNull);

      // Go back to backlog, then return to learning
      await provider.setStage(provider.pieces.first, kStageBacklog);
      await provider.setStage(provider.pieces.first, kStageLearning);
      final second = provider.pieces.first.timestampForStage(kStageLearning);
      // Timestamp must be the original (write-once)
      expect(second, first);
    });
  });

  // ── logPractice ───────────────────────────────────────────────────────────

  group('logPractice', () {
    test('creates a practice session', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      expect(provider.practiceSessions.length, 1);
      expect(provider.practiceSessions.first.pieceId, added.id);
    });

    test('multiple sessions accumulate', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      await provider.logPractice(added.id!);
      expect(provider.practiceSessions.length, 2);
    });

    test('updates measuresLearned on the piece when provided', () async {
      final added = await provider.addPiece(_piece(measures: 100));
      await provider.logPractice(added!.id!, measuresLearned: 50);
      expect(provider.pieces.first.measuresLearned, 50);
    });

    test('updates currentTempo on the piece when bpm is provided', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!, currentBpm: 88);
      expect(provider.pieces.first.currentTempo, 88);
    });

    test('does not change piece data when measures and bpm are both null', () async {
      final added = await provider.addPiece(_piece(measures: 100));
      final originalUpdatedAt = provider.pieces.first.updatedAt;
      await provider.logPractice(added!.id!);
      expect(provider.pieces.first.updatedAt, originalUpdatedAt);
    });

    test('stores notes in the session', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!, notes: 'Felt great');
      expect(provider.practiceSessions.first.notes, 'Felt great');
    });

    test('stores durationSeconds in the session', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!, durationSeconds: 300);
      expect(provider.practiceSessions.first.durationSeconds, 300);
    });

    test('updates lastPracticeDates after logging', () async {
      final added = await provider.addPiece(_piece());
      expect(provider.lastPracticeDateForPiece(added!.id!), isNull);
      await provider.logPractice(added.id!);
      expect(provider.lastPracticeDateForPiece(added.id!), isNotNull);
    });

    test('notifies listeners after logging', () async {
      final added = await provider.addPiece(_piece());
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.logPractice(added!.id!);
      expect(notifyCount, greaterThan(0));
    });
  });

  // ── updatePracticeSession ─────────────────────────────────────────────────

  group('updatePracticeSession', () {
    test('updated fields are reflected in practiceSessions list', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!, notes: 'Before');
      final session = provider.practiceSessions.first;
      await provider.updatePracticeSession(session.copyWith(notes: 'After'));
      expect(provider.practiceSessions.first.notes, 'After');
    });

    test('returns true on success', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      final session = provider.practiceSessions.first;
      final result = await provider.updatePracticeSession(
          session.copyWith(currentBpm: 120));
      expect(result, isTrue);
    });

    test('does not change the number of sessions', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      await provider.logPractice(added.id!);
      final session = provider.practiceSessions.first;
      await provider.updatePracticeSession(session.copyWith(notes: 'Updated'));
      expect(provider.practiceSessions.length, 2);
    });

    test('notifies listeners after update', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      final session = provider.practiceSessions.first;
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.updatePracticeSession(session.copyWith(notes: 'Changed'));
      expect(notified, isTrue);
    });
  });

  // ── deletePracticeSession ─────────────────────────────────────────────────

  group('deletePracticeSession', () {
    test('removes session from practiceSessions list', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      final sessionId = provider.practiceSessions.first.id!;
      await provider.deletePracticeSession(sessionId);
      expect(provider.practiceSessions, isEmpty);
    });

    test('only removes the targeted session', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      await provider.logPractice(added.id!);
      final sessionId = provider.practiceSessions.first.id!;
      await provider.deletePracticeSession(sessionId);
      expect(provider.practiceSessions.length, 1);
    });

    test('returns true on success', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      final sessionId = provider.practiceSessions.first.id!;
      final result = await provider.deletePracticeSession(sessionId);
      expect(result, isTrue);
    });

    test('clears lastPracticeDate when last session for piece is deleted', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      expect(provider.lastPracticeDateForPiece(added.id!), isNotNull);
      final sessionId = provider.practiceSessions.first.id!;
      await provider.deletePracticeSession(sessionId);
      expect(provider.lastPracticeDateForPiece(added.id!), isNull);
    });

    test('notifies listeners after deletion', () async {
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      final sessionId = provider.practiceSessions.first.id!;
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.deletePracticeSession(sessionId);
      expect(notified, isTrue);
    });
  });

  // ── setPremium ────────────────────────────────────────────────────────────

  group('setPremium', () {
    test('sets isPremium to true', () async {
      await provider.setPremium(true);
      expect(provider.isPremium, isTrue);
    });

    test('sets isPremium to false', () async {
      await provider.setPremium(true);
      await provider.setPremium(false);
      expect(provider.isPremium, isFalse);
    });

    test('persists value to SharedPreferences', () async {
      await provider.setPremium(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('is_premium'), isTrue);
    });

    test('notifies listeners', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);
      await provider.setPremium(true);
      expect(notifyCount, greaterThan(0));
    });
  });

  // ── lastPracticeDateForPiece ───────────────────────────────────────────────

  group('lastPracticeDateForPiece', () {
    test('returns null before any sessions are logged', () async {
      final added = await provider.addPiece(_piece());
      expect(provider.lastPracticeDateForPiece(added!.id!), isNull);
    });

    test('returns a recent date after logging', () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final added = await provider.addPiece(_piece());
      await provider.logPractice(added!.id!);
      final date = provider.lastPracticeDateForPiece(added.id!);
      expect(date, isNotNull);
      expect(date!.isAfter(before), isTrue);
    });

    test('returns null for an unknown pieceId', () {
      expect(provider.lastPracticeDateForPiece(99999), isNull);
    });

    test('tracks dates independently per piece', () async {
      final a = await provider.addPiece(_piece(name: 'A'));
      final b = await provider.addPiece(_piece(name: 'B'));
      await provider.logPractice(a!.id!);
      expect(provider.lastPracticeDateForPiece(a.id!), isNotNull);
      expect(provider.lastPracticeDateForPiece(b!.id!), isNull);
    });
  });

  // ── recentMilestones ──────────────────────────────────────────────────────

  group('recentMilestones', () {
    test('returns empty list when no pieces have stage timestamps', () async {
      final milestones = await provider.recentMilestones;
      expect(milestones, isEmpty);
    });

    test('returns milestone entries for pieces with stage timestamps', () async {
      // addPiece always sets backlogAt, so one milestone entry is created
      await provider.addPiece(_piece(name: 'Milestone Piece'));
      final milestones = await provider.recentMilestones;
      expect(milestones, isNotEmpty);
      expect(
        milestones.any((m) => (m['piece'] as Piece).name == 'Milestone Piece'),
        isTrue,
      );
    });

    test('milestone entries have required keys', () async {
      await provider.addPiece(_piece(name: 'Key Check'));
      final milestones = await provider.recentMilestones;
      expect(milestones, isNotEmpty);
      final entry = milestones.first;
      expect(entry.containsKey('piece'), isTrue);
      expect(entry.containsKey('stage'), isTrue);
      expect(entry.containsKey('timestamp'), isTrue);
    });
  });
}
