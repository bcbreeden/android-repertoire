import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/database/database_helper.dart';
import 'package:repertoire/models/piece.dart';
import 'package:repertoire/providers/piece_provider.dart';
import 'package:repertoire/utils/constants.dart';
import 'package:repertoire/widgets/log_practice_sheet.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Piece _piece({
  String name = 'Nocturne',
  String? composer = 'Chopin',
  int measures = 80,
  int? measuresLearned = 40,
  int? currentTempo = 72,
  int? targetTempo,
}) {
  final now = DateTime(2024, 1, 1, 12, 0);
  return Piece(
    name: name,
    composer: composer,
    measures: measures,
    measuresLearned: measuresLearned,
    currentTempo: currentTempo,
    targetTempo: targetTempo,
    status: kStageLearning,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _buildSheet(PieceProvider provider, {int? pieceId}) =>
    ChangeNotifierProvider<PieceProvider>.value(
      value: provider,
      child: MaterialApp(
        home: Scaffold(
          body: LogPracticeSheet(pieceId: pieceId),
        ),
      ),
    );

PieceProvider _emptyProvider() {
  SharedPreferences.setMockInitialValues({});
  return PieceProvider();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  // ── Timer controls ────────────────────────────────────────────────────────
  // These tests need no DB access; an empty provider is enough.

  group('LogPracticeSheet timer controls', () {
    testWidgets('initial state shows 00:00 and Start Practice', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      expect(find.text('00:00'), findsOneWidget);
      expect(find.text('Start Practice'), findsOneWidget);
      expect(find.text('Start the timer when you begin'), findsOneWidget);
    });

    testWidgets('tapping Start Practice shows Pause and End buttons', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Start Practice'), findsNothing);
      expect(find.text('Practice in progress'), findsOneWidget);
    });

    testWidgets('tapping Pause shows Resume and End buttons', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.tap(find.text('Pause'));
      await tester.pump();

      expect(find.text('Resume'), findsOneWidget);
      expect(find.text('End'), findsOneWidget);
      expect(find.text('Paused'), findsOneWidget);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('tapping Resume restores running state', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.tap(find.text('Resume'));
      await tester.pump();

      expect(find.text('Pause'), findsOneWidget);
      expect(find.text('Practice in progress'), findsOneWidget);
      expect(find.text('Resume'), findsNothing);
    });

    testWidgets('tapping End from running shows Session complete', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.tap(find.text('End'));
      await tester.pump();

      expect(find.text('Session complete'), findsOneWidget);
      expect(find.text('Start Practice'), findsNothing);
      expect(find.text('Pause'), findsNothing);
    });

    testWidgets('tapping End from paused shows Session complete', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.tap(find.text('Pause'));
      await tester.pump();
      await tester.tap(find.text('End'));
      await tester.pump();

      expect(find.text('Session complete'), findsOneWidget);
    });

    testWidgets('timer advances each second while running', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 5));

      expect(find.text('00:05'), findsOneWidget);
    });

    testWidgets('timer does not advance while paused', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      await tester.tap(find.text('Pause'));
      await tester.pump();

      // 5 more seconds while paused — display stays at 00:03
      await tester.pump(const Duration(seconds: 5));
      expect(find.text('00:03'), findsOneWidget);
    });

    testWidgets('timer shows MM:SS format for sub-hour durations', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      await tester.tap(find.text('Start Practice'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 65));

      expect(find.text('01:05'), findsOneWidget);
    });
  });

  // ── Piece display ─────────────────────────────────────────────────────────
  // DB operations use tester.runAsync() to stay outside FakeAsync.

  group('LogPracticeSheet piece display', () {
    testWidgets('shows dropdown with hint when no pieceId provided', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      expect(find.text('Select a song'), findsOneWidget);
      expect(find.byType(DropdownButton<int>), findsOneWidget);
    });

    testWidgets('Save button is disabled when no piece is selected', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save Session'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows piece info row with name when pieceId is provided', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(name: 'Fur Elise', composer: null));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.text('Select a song'), findsNothing);
      expect(find.byType(DropdownButton<int>), findsNothing);
      expect(find.text('Fur Elise'), findsOneWidget);
    });

    testWidgets('shows composer in info row when piece has one', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(name: 'Nocturne', composer: 'Chopin'));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.text('Nocturne'), findsOneWidget);
      expect(find.text('Chopin'), findsOneWidget);
    });

    testWidgets('does not show composer when piece has none', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(name: 'No Composer', composer: null));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.text('No Composer'), findsOneWidget);
      expect(find.text('Chopin'), findsNothing);
    });

    testWidgets('Save button is enabled when pieceId is pre-selected', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece());
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save Session'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('prefills measures from piece data', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(measuresLearned: 42));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('prefills BPM from piece data', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(currentTempo: 96));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.text('96'), findsOneWidget);
    });

    testWidgets('shows em-dash when pieceId has no matching piece', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider(), pieceId: 99999));
      await tester.pumpAndSettle();

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('shows total measures when piece is selected', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(measures: 120));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.textContaining('120 measures total'), findsOneWidget);
    });

    testWidgets('shows target BPM when piece has targetTempo', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(targetTempo: 108));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.textContaining('Target: 108 BPM'), findsOneWidget);
    });

    testWidgets('hides target BPM row when piece has no targetTempo', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(targetTempo: null));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      expect(find.textContaining('Target:'), findsNothing);
    });
  });

  // ── Validation ────────────────────────────────────────────────────────────

  group('LogPracticeSheet validation', () {
    testWidgets('shows error when measures exceed total', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(measures: 50));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '99');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Session'));
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      expect(find.text('Max 50'), findsOneWidget);
    });

    testWidgets('shows error when BPM exceeds target', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(targetTempo: 100));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      final bpmField = find.byType(TextFormField).at(1);
      await tester.tap(bpmField);
      await tester.enterText(bpmField, '150');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Session'));
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      expect(find.text('Max 100'), findsOneWidget);
    });

    testWidgets('allows saving when values are within limits', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(
            _piece(measures: 80, targetTempo: 120));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).first);
      await tester.enterText(find.byType(TextFormField).first, '40');
      final bpmField = find.byType(TextFormField).at(1);
      await tester.tap(bpmField);
      await tester.enterText(bpmField, '100');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Session'));
      await tester.tap(find.text('Save Session'));
      await tester.pump();

      expect(find.text('Max 80'), findsNothing);
      expect(find.text('Max 120'), findsNothing);
    });

    testWidgets('no BPM error when piece has no targetTempo', (tester) async {
      final provider = _emptyProvider();
      late int pid;
      await tester.runAsync(() async {
        final db = await DatabaseHelper.instance.database;
        await db.delete('practice_sessions');
        await db.delete('pieces');
        final added = await provider.addPiece(_piece(targetTempo: null));
        pid = added!.id!;
      });

      await tester.pumpWidget(_buildSheet(provider, pieceId: pid));
      await tester.pumpAndSettle();

      final bpmField = find.byType(TextFormField).at(1);
      await tester.tap(bpmField);
      await tester.enterText(bpmField, '9999');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Save Session'));
      await tester.tap(find.text('Save Session'));
      await tester.pump(); // just enough to render validation errors if any

      expect(find.textContaining('Max'), findsNothing);
    });
  });

  // ── Header ────────────────────────────────────────────────────────────────

  group('LogPracticeSheet header', () {
    testWidgets('shows Log Practice title', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      expect(find.text('Log Practice'), findsOneWidget);
    });

    testWidgets('shows Song label above the picker', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      expect(find.text('Song'), findsOneWidget);
    });

    testWidgets('shows Save Session button', (tester) async {
      await tester.pumpWidget(_buildSheet(_emptyProvider()));
      await tester.pump();

      expect(find.text('Save Session'), findsOneWidget);
    });
  });
}
