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
  String status = kStagelearning,
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
      await provider.addPiece(_piece(name: 'A', status: kStagelearning));
      await provider.addPiece(_piece(name: 'B', status: kStageNotePerfection));
      expect(provider.filteredPieces.length, 2);
    });

    test('returns only pieces matching the active filter', () async {
      await provider.addPiece(_piece(name: 'Learning', status: kStagelearning));
      await provider.addPiece(_piece(name: 'NP', status: kStageNotePerfection));
      provider.setFilter(kStagelearning);
      expect(provider.filteredPieces.length, 1);
      expect(provider.filteredPieces.first.name, 'Learning');
    });

    test('returns empty list when filter matches no pieces', () async {
      await provider.addPiece(_piece(status: kStagelearning));
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
      provider.setFilter(kStageNotePerfection);
      expect(provider.activeFilter, kStageNotePerfection);
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
      provider.setFilter(kStagelearning);
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

    test('sets learningAt on the created piece regardless of input', () async {
      final pieceWithoutTimestamp = Piece(
        name: 'Test',
        measures: 50,
        createdAt: DateTime(2020, 1, 1),
        updatedAt: DateTime(2020, 1, 1),
        learningAt: null,
      );
      final result = await provider.addPiece(pieceWithoutTimestamp);
      expect(result!.learningAt, isNotNull);
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
      await provider.addPiece(_piece(status: kStagelearning));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.totalCount, 2);
    });

    test('repertoireCount counts only repertoire-stage pieces', () async {
      await provider.addPiece(_piece(status: kStagelearning));
      await provider.addPiece(_piece(status: kStageRepertoire));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.repertoireCount, 2);
    });

    test('repertoireCount is 0 when no pieces are in repertoire', () async {
      await provider.addPiece(_piece(status: kStagelearning));
      expect(provider.repertoireCount, 0);
    });
  });

  // ── overallProgressPct ────────────────────────────────────────────────────

  group('overallProgressPct', () {
    test('returns 0 when there are no pieces', () {
      expect(provider.overallProgressPct, 0.0);
    });

    test('returns 0 when all pieces are in learning stage', () async {
      await provider.addPiece(_piece(status: kStagelearning));
      await provider.addPiece(_piece(status: kStagelearning));
      expect(provider.overallProgressPct, 0.0);
    });

    test('returns 100 when all pieces are in repertoire stage', () async {
      await provider.addPiece(_piece(status: kStageRepertoire));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.overallProgressPct, 100.0);
    });

    test('returns 50 for one learning and one repertoire piece', () async {
      // learning stageIndex=0, repertoire stageIndex=4
      // total = 4, maxPossible = 2*4 = 8 → 4/8*100 = 50
      await provider.addPiece(_piece(status: kStagelearning));
      await provider.addPiece(_piece(status: kStageRepertoire));
      expect(provider.overallProgressPct, 50.0);
    });

    test('clamps at 100.0', () async {
      // All at max stage, pct should be exactly 100, never above.
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
      await provider.addPiece(_piece(status: kStagelearning));
      await provider.addPiece(_piece(status: kStagelearning));
      await provider.addPiece(_piece(status: kStageNotePerfection));
      final counts = provider.stageCounts;
      expect(counts[kStagelearning], 2);
      expect(counts[kStageNotePerfection], 1);
      expect(counts[kStageDynamicsPerfection], 0);
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
}
