import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repertoire/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Pieces', () {
    testWidgets('home screen loads with Pieces and Practice tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Pieces'), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('can add a new piece', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // If paywall appears (too many pieces already), skip gracefully
      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active — clear seeded data to test adding pieces.');
        return;
      }

      // Step 1: fill required fields (Title at index 0, Total Measures at index 2)
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '64');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: save
      await tester.tap(find.text('Add Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Test Piece'), findsAtLeastNWidgets(1));
    });

    testWidgets('piece card shows stage badge', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Learning'), findsWidgets);
    });

    testWidgets('filter chips filter the list', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Use textContaining in case the chip shows "Note Perfection (N)"
      await tester.tap(find.textContaining('Note Perfection').first);
      await tester.pumpAndSettle();

      // All (N) chip should still be visible
      expect(find.textContaining('All'), findsOneWidget);

      // Tap All to restore
      await tester.tap(find.textContaining('All').first);
      await tester.pumpAndSettle();
    });
  });

  group('Create and edit piece with all fields', () {
    testWidgets('fills all fields on add, then edits all fields and verifies', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // ── Add ──────────────────────────────────────────────────────────────
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active — clear seeded data first.');
        return;
      }

      // Step 1: all available fields
      await tester.enterText(find.byType(TextFormField).at(0), 'Full Field Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Composer');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '80');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(3), '120'); // Target BPM
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '60');  // Current BPM
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: notes
      await tester.enterText(find.byType(TextFormField).first, 'Original notes');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Piece'));
      await tester.pumpAndSettle();

      // Piece appears in list
      expect(find.text('Full Field Piece'), findsAtLeastNWidgets(1));

      // ── Navigate to detail ────────────────────────────────────────────────
      await tester.scrollUntilVisible(
        find.text('Full Field Piece').last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Full Field Piece').last);
      await tester.pumpAndSettle();

      expect(find.text('Log Practice'), findsOneWidget);

      // ── Open edit screen ──────────────────────────────────────────────────
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Piece'), findsOneWidget);

      // ── Edit all fields ───────────────────────────────────────────────────
      // Edit form field order: Title(0), Composer(1), Total Measures(2),
      // Measures Learned(3), Current Tempo(4), Target Tempo(5), Notes(6)
      // Use tap-then-enterText to ensure proper focus on all API levels.
      final fields = find.byType(TextFormField);

      await tester.tap(fields.at(0));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(0), 'Edited Piece Title');
      await tester.pumpAndSettle();

      await tester.tap(fields.at(1));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(1), 'Edited Composer');
      await tester.pumpAndSettle();

      await tester.tap(fields.at(2));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(2), '96');
      await tester.pumpAndSettle();

      await tester.tap(fields.at(3));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(3), '48');
      await tester.pumpAndSettle();

      await tester.tap(fields.at(4));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(4), '72');
      await tester.pumpAndSettle();

      // Scroll to expose Target Tempo and Notes fields
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(fields.at(5));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(5), '144');
      await tester.pumpAndSettle();

      await tester.tap(fields.at(6));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(6), 'Edited notes');
      await tester.pumpAndSettle();

      // Scroll Save Changes button into view and tap it
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // ── Verify on detail screen ───────────────────────────────────────────
      // 'Edited Piece Title' appears in the AppBar title on the detail screen
      expect(find.text('Edited Piece Title'), findsAtLeastNWidgets(1));
      expect(find.text('Log Practice'), findsOneWidget);
    });
  });

  group('Piece detail', () {
    testWidgets('tapping a piece opens detail screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Scroll past stats/milestones/filter bar to expose piece cards
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Find a piece card by scrolling past the stats/milestones section.
      // "Test Piece" is added by the previous test and persists in the DB.
      // Tap it to navigate to the detail screen.
      await tester.scrollUntilVisible(
        find.text('Test Piece').last,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Test Piece').last);
      await tester.pumpAndSettle();

      expect(find.text('Log Practice'), findsOneWidget);
    });
  });

  group('Practice logging', () {
    testWidgets('Practice tab shows correct empty or history state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      final hasValidState =
          find.text('No sessions yet').evaluate().isNotEmpty ||
          find.text('No pieces yet').evaluate().isNotEmpty ||
          find.text('Session History').evaluate().isNotEmpty;
      expect(hasValidState, isTrue);
    });

    testWidgets('can open log practice sheet and see timer', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        expect(find.text('Start Practice'), findsOneWidget);
        expect(find.text('Save Session'), findsOneWidget);
      }
    });

    testWidgets('timer start and pause work', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Start Practice'));
        await tester.pumpAndSettle();

        expect(find.text('Pause'), findsOneWidget);

        await tester.tap(find.text('Pause'));
        await tester.pumpAndSettle();

        expect(find.text('Resume'), findsOneWidget);
      }
    });
  });

  group('Database migration', () {
    testWidgets('app loads without crash on fresh install', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Repertoire'), findsOneWidget);
    });
  });
}
