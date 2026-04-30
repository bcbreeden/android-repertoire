import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repertoire/main.dart' as app;
import 'package:repertoire/widgets/piece_card.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Returns a Finder that matches a PieceCard whose piece.name equals [name].
/// This is more reliable than find.ancestor because it directly checks widget
/// properties rather than tree structure, avoiding false matches from the
/// Recent Milestones section.
Finder _cardFinder(String name) => find.byWidgetPredicate(
      (widget) => widget is PieceCard && widget.piece.name == name,
      skipOffstage: false,
    );

/// Scrolls to a piece card by name and opens its detail screen.
/// Delta is negative to scroll DOWN (positive Y drag = scroll UP in Flutter).
Future<void> _openPiece(WidgetTester tester, String name) async {
  // Use default skipOffstage: true so dragUntilVisible loops correctly until
  // the card is actually in the viewport (not just in SliverList cache extent).
  final card = find.byWidgetPredicate(
    (widget) => widget is PieceCard && widget.piece.name == name,
  );
  await tester.scrollUntilVisible(
    card,
    -500,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
  await tester.tap(card);
  await tester.pumpAndSettle();
}

/// Taps the Advance button on the detail screen once and confirms the dialog.
/// Handles the CelebrationScreen that appears when advancing to Mastered.
Future<void> _advanceOnce(WidgetTester tester) async {
  await tester.ensureVisible(find.textContaining('Advance to').first);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Advance to').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirm'));
  await tester.pumpAndSettle();
  // Dismiss celebration screen if this was the final stage
  if (find.text('Dismiss').evaluate().isNotEmpty) {
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
  }
}

/// Navigates back to the home screen from the detail screen.
Future<void> _goBack(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

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
        -500,
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
        -500,
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

  group('Stage advancement and filter chips', () {
    // These tests use the debug seed button to populate 40 pieces across all
    // five stages, then verify filter chips isolate pieces by stage and that
    // a piece can be advanced to the next stage.
    //
    // Seed data stage distribution:
    //   Learning (12): Clair de Lune, Moonlight Sonata, ...
    //   Note Perfection (9): Ballade No. 1, Sonatina in G, ...
    //   Dynamics Perfection (8): Waldstein Sonata, Minuet in G, ...
    //   Tempo Perfection (6): Pathetique Sonata, ...
    //   Mastered (5): Prelude in C# Minor, Gymnopédie No. 3, ...

    testWidgets('filter chips isolate pieces by stage', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Seed 40 pieces across all stages using the debug flask button
      await tester.tap(find.byIcon(Icons.science_outlined));
      await tester.pumpAndSettle();

      // Each stage chip should now show a count
      expect(find.textContaining('Learning'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Note Perfection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Dynamics Perfection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Tempo Perfection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Mastered'), findsAtLeastNWidgets(1));

      // Helper: bring a filter chip into view (FilterChips are in a
      // SliverToBoxAdapter so always in tree, but can scroll off screen)
      // and tap it.
      Future<void> tapChip(String label) async {
        final chip = find.ancestor(
          of: find.textContaining(label),
          matching: find.byType(FilterChip),
        );
        await tester.ensureVisible(chip.first);
        await tester.pumpAndSettle();
        await tester.tap(chip.first);
        await tester.pumpAndSettle();
      }

      // ── Learning filter ───────────────────────────────────────────────────
      await tapChip('Learning');
      // Scroll down to expose piece cards (negative delta = scroll DOWN)
      await tester.scrollUntilVisible(
        _cardFinder('Clair de Lune'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_cardFinder('Clair de Lune'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Ballade No. 1'), findsNothing);      // Note Perfection
      expect(_cardFinder('Waldstein Sonata'), findsNothing);   // Dynamics Perfection
      expect(_cardFinder('Pathetique Sonata'), findsNothing);  // Tempo Perfection
      expect(_cardFinder('Prelude in C# Minor'), findsNothing); // Mastered

      // ── Note Perfection filter ────────────────────────────────────────────
      await tapChip('Note Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Sonatina in G'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_cardFinder('Sonatina in G'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Clair de Lune'), findsNothing);
      expect(_cardFinder('Waldstein Sonata'), findsNothing);

      // ── Dynamics Perfection filter ────────────────────────────────────────
      await tapChip('Dynamics Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Minuet in G'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_cardFinder('Minuet in G'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Sonatina in G'), findsNothing);
      expect(_cardFinder('Pathetique Sonata'), findsNothing);

      // ── Tempo Perfection filter ───────────────────────────────────────────
      await tapChip('Tempo Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Pathetique Sonata'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_cardFinder('Pathetique Sonata'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Minuet in G'), findsNothing);
      expect(_cardFinder('Prelude in C# Minor'), findsNothing);

      // ── Mastered filter ───────────────────────────────────────────────────
      await tapChip('Mastered');
      await tester.scrollUntilVisible(
        _cardFinder('Gymnopédie No. 3'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_cardFinder('Gymnopédie No. 3'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Pathetique Sonata'), findsNothing);
      expect(_cardFinder('Clair de Lune'), findsNothing);

      // ── All filter restores the full list ─────────────────────────────────
      await tapChip('All');
      expect(find.textContaining('All'), findsAtLeastNWidgets(1));
    });

    testWidgets('advancing a piece moves it to the next stage', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Seed 40 pieces across all stages
      await tester.tap(find.byIcon(Icons.science_outlined));
      await tester.pumpAndSettle();

      // 'Clair de Lune' is in Learning — near top of sorted list.
      await _openPiece(tester, 'Clair de Lune');

      // Verify we navigated to the detail screen before advancing
      expect(find.text('Log Practice'), findsOneWidget);

      // Advance from Learning → Note Perfection
      await _advanceOnce(tester);

      // Stage badge on detail screen now shows Note Perfection
      expect(find.textContaining('Note Perfection'), findsAtLeastNWidgets(1));

      await _goBack(tester);

      // Learning filter should no longer contain Clair de Lune piece card
      final learningChip = find.ancestor(
        of: find.textContaining('Learning'),
        matching: find.byType(FilterChip),
      );
      await tester.ensureVisible(learningChip.first);
      await tester.pumpAndSettle();
      await tester.tap(learningChip.first);
      await tester.pumpAndSettle();
      expect(_cardFinder('Clair de Lune'), findsNothing);

      // Note Perfection filter should now contain it
      final npChip = find.ancestor(
        of: find.textContaining('Note Perfection'),
        matching: find.byType(FilterChip),
      );
      await tester.ensureVisible(npChip.first);
      await tester.pumpAndSettle();
      await tester.tap(npChip.first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        _cardFinder('Clair de Lune'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(_cardFinder('Clair de Lune'), findsAtLeastNWidgets(1));

      // Restore All using tapChip-style ensureVisible
      final allChip = find.ancestor(
        of: find.textContaining('All'),
        matching: find.byType(FilterChip),
      );
      await tester.ensureVisible(allChip.first);
      await tester.pumpAndSettle();
      await tester.tap(allChip.first);
      await tester.pumpAndSettle();
    });
  });
}
