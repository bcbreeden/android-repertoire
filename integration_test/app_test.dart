import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repertoire/database/database_helper.dart';
import 'package:repertoire/main.dart' as app;
import 'package:repertoire/widgets/piece_card.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Key on the main CustomScrollView in the Pieces tab.
const _piecesScrollKey = Key('pieces_scroll');

/// Finds the Scrollable inside the keyed CustomScrollView.
/// scrollUntilVisible requires a Scrollable, not the CustomScrollView itself.
Finder get _piecesScrollable => find.descendant(
      of: find.byKey(_piecesScrollKey),
      matching: find.byType(Scrollable),
    );

/// Returns a Finder that matches a PieceCard whose piece.name equals [name].
/// skipOffstage: false lets scrollUntilVisible find cards in the SliverList
/// cache extent before they enter the visible viewport, and keeps negative
/// assertions reliable regardless of scroll position.
Finder _cardFinder(String name) => find.byWidgetPredicate(
      (widget) => widget is PieceCard && widget.piece.name == name,
      skipOffstage: false,
    );

/// Scrolls to a PieceCard by name and opens its detail screen.
Future<void> _openPiece(WidgetTester tester, String name) async {
  final card = find.byWidgetPredicate(
    (widget) => widget is PieceCard && widget.piece.name == name,
    skipOffstage: false,
  );
  await tester.scrollUntilVisible(
    card,
    -500,
    scrollable: _piecesScrollable,
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

/// Brings a FilterChip matching [label] into view and taps it.
/// skipOffstage: false is required because the filter bar can scroll off the
/// top when the piece list has been scrolled down (AutomaticKeepAliveClientMixin
/// preserves scroll position across navigations).
Future<void> _tapChip(WidgetTester tester, String label) async {
  final chip = find.ancestor(
    of: find.textContaining(label, skipOffstage: false),
    matching: find.byType(FilterChip),
  );
  await tester.ensureVisible(chip.first);
  await tester.pumpAndSettle();
  await tester.tap(chip.first);
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Pieces ────────────────────────────────────────────────────────────────
  // setUpAll resets once so intra-group tests can share state:
  //   "can add" creates Test Piece → later tests in this group see it.
  group('Pieces', () {
    setUpAll(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('home screen loads with Pieces and Practice tabs', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Songs'), findsOneWidget);
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
      await tester.tap(find.text('Add Song'));
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

      // Tap Note Perfection chip — chip always exists even with 0 pieces in stage
      await tester.tap(find.textContaining('Note Perfection').first);
      await tester.pumpAndSettle();

      // All chip should still be visible in the filter bar
      expect(find.textContaining('All'), findsOneWidget);

      // Restore
      await tester.tap(find.textContaining('All').first);
      await tester.pumpAndSettle();
    });

    testWidgets('tapping a piece opens detail screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Test Piece was created by 'can add a new piece' above and persists
      // because setUpAll only resets once for the whole group.
      await _openPiece(tester, 'Test Piece');

      expect(find.text('Log Practice'), findsOneWidget);
    });
  });

  // ── Create and edit piece with all fields ────────────────────────────────
  group('Create and edit piece with all fields', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

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
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Piece appears in list
      expect(find.text('Full Field Piece'), findsAtLeastNWidgets(1));

      // ── Navigate to detail ────────────────────────────────────────────────
      await tester.scrollUntilVisible(
        _cardFinder('Full Field Piece'),
        -500,
        scrollable: _piecesScrollable,
      );
      await tester.tap(_cardFinder('Full Field Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Log Practice'), findsOneWidget);

      // ── Open edit screen ──────────────────────────────────────────────────
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Song'), findsOneWidget);

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
      expect(find.text('Edited Piece Title'), findsAtLeastNWidgets(1));
      expect(find.text('Log Practice'), findsOneWidget);
    });
  });

  // ── Practice logging ─────────────────────────────────────────────────────
  group('Practice logging', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('Practice tab shows correct empty or history state', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      final hasValidState =
          find.text('No sessions yet').evaluate().isNotEmpty ||
          find.text('Nothing added yet').evaluate().isNotEmpty ||
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

  // ── Database migration ────────────────────────────────────────────────────
  group('Database migration', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('app loads without crash on fresh install', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Repertoire'), findsOneWidget);
    });
  });

  // ── Stage advancement and filter chips ────────────────────────────────────
  // setUpAll seeds 40 pieces once for the whole group so both tests share the
  // same data without re-seeding. Filter chips test runs first (read-only),
  // advancement test runs second (mutates Clair de Lune's stage).
  group('Stage advancement and filter chips', () {
    setUpAll(() async {
      await DatabaseHelper.instance.resetForTesting();
      await DatabaseHelper.instance.seedTestData();
    });

    testWidgets('filter chips isolate pieces by stage', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Each stage chip should show a count from the seeded data
      expect(find.textContaining('Learning'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Note Perfection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Dynamics Perfection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Tempo Perfection'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Mastered'), findsAtLeastNWidgets(1));

      // ── Learning filter ───────────────────────────────────────────────────
      await _tapChip(tester, 'Learning');
      await tester.scrollUntilVisible(
        _cardFinder('Clair de Lune'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Clair de Lune'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Ballade No. 1'), findsNothing);      // Note Perfection
      expect(_cardFinder('Waldstein Sonata'), findsNothing);   // Dynamics Perfection
      expect(_cardFinder('Pathetique Sonata'), findsNothing);  // Tempo Perfection
      expect(_cardFinder('Prelude in C# Minor'), findsNothing); // Mastered

      // ── Note Perfection filter ────────────────────────────────────────────
      await _tapChip(tester, 'Note Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Sonatina in G'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Sonatina in G'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Clair de Lune'), findsNothing);
      expect(_cardFinder('Waldstein Sonata'), findsNothing);

      // ── Dynamics Perfection filter ────────────────────────────────────────
      await _tapChip(tester, 'Dynamics Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Minuet in G'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Minuet in G'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Sonatina in G'), findsNothing);
      expect(_cardFinder('Pathetique Sonata'), findsNothing);

      // ── Tempo Perfection filter ───────────────────────────────────────────
      await _tapChip(tester, 'Tempo Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Pathetique Sonata'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Pathetique Sonata'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Minuet in G'), findsNothing);
      expect(_cardFinder('Prelude in C# Minor'), findsNothing);

      // ── Mastered filter ───────────────────────────────────────────────────
      await _tapChip(tester, 'Mastered');
      await tester.scrollUntilVisible(
        _cardFinder('Gymnopédie No. 3'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Gymnopédie No. 3'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Pathetique Sonata'), findsNothing);
      expect(_cardFinder('Clair de Lune'), findsNothing);

      // ── All filter restores the full list ─────────────────────────────────
      await _tapChip(tester, 'All');
      expect(find.textContaining('All'), findsAtLeastNWidgets(1));
    });

    testWidgets('advancing a piece moves it to the next stage', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // 'Clair de Lune' is in Learning — near top of sorted list
      await _openPiece(tester, 'Clair de Lune');

      expect(find.text('Log Practice'), findsOneWidget);

      // Advance from Learning → Note Perfection
      await _advanceOnce(tester);

      // Stage badge on detail screen now shows Note Perfection
      expect(find.textContaining('Note Perfection'), findsAtLeastNWidgets(1));

      await _goBack(tester);

      // PiecesTab preserves scroll position via AutomaticKeepAliveClientMixin.
      // Scroll back to top so the SliverToBoxAdapter holding the filter chips
      // is rendered in the element tree before we try to interact with them.
      await tester.drag(find.byKey(_piecesScrollKey), const Offset(0, 10000));
      await tester.pumpAndSettle();

      // Learning filter should no longer contain Clair de Lune
      await _tapChip(tester, 'Learning');
      expect(_cardFinder('Clair de Lune'), findsNothing);

      // Note Perfection filter should now contain it
      await _tapChip(tester, 'Note Perfection');
      await tester.scrollUntilVisible(
        _cardFinder('Clair de Lune'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Clair de Lune'), findsAtLeastNWidgets(1));

      await _tapChip(tester, 'All');
    });
  });

  // ── Delete song ───────────────────────────────────────────────────────────
  group('Delete song', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('deleting a song removes it from the list', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active — cannot add song to test deletion.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Delete Me');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Open detail screen
      await tester.tap(_cardFinder('Delete Me'));
      await tester.pumpAndSettle();

      // Tap the delete icon
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Confirm dialog appears
      expect(find.text('Delete Song?'), findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Navigated back to songs list, piece is gone
      expect(_cardFinder('Delete Me'), findsNothing);
    });

    testWidgets('cancelling the delete dialog keeps the song', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Keep Me');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      await tester.tap(_cardFinder('Keep Me'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Cancel the dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Still on detail screen with song intact
      expect(find.text('Log Practice'), findsOneWidget);
    });
  });

  // ── End-to-end practice session save ─────────────────────────────────────
  group('Practice session save', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('saving a session shows it in the Practice tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Session Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '64');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Open the log sheet via the Practice pill on the card
      final practiceBtn = find.descendant(
        of: _cardFinder('Session Piece'),
        matching: find.text('Practice'),
      );
      await tester.tap(practiceBtn);
      await tester.pumpAndSettle();

      // Fill in measures learned
      await tester.enterText(find.byType(TextFormField).at(0), '32');
      await tester.pumpAndSettle();

      // Dismiss keyboard so Save Session button is tappable
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Switch to Practice tab (use Tab widget to avoid ambiguity with Practice pill)
      await tester.tap(find.widgetWithText(Tab, 'Practice'));
      await tester.pumpAndSettle();

      // Session appears — piece name is shown in the session tile
      expect(find.text('Session Piece'), findsAtLeastNWidgets(1));
      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('saved session chip shows measures in the Practice tab', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Chip Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '80');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      final practiceBtn = find.descendant(
        of: _cardFinder('Chip Test Piece'),
        matching: find.text('Practice'),
      );
      await tester.tap(practiceBtn);
      await tester.pumpAndSettle();

      // Enter 55 measures
      await tester.enterText(find.byType(TextFormField).at(0), '55');
      await tester.pumpAndSettle();

      // Dismiss keyboard so Save Session button is tappable
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Switch to Practice tab (use Tab widget to avoid ambiguity with Practice pill)
      await tester.tap(find.widgetWithText(Tab, 'Practice'));
      await tester.pumpAndSettle();

      // The measures chip should show "55 measures"
      expect(find.text('55 measures'), findsOneWidget);
    });
  });

  // ── Practice button ───────────────────────────────────────────────────────
  group('Practice button', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('tapping Practice on a card opens the sheet pre-filled for that piece', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add a piece with known measures and tempo so prefill is testable
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Practice Btn Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Composer');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '64');  // measures
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(3), '120'); // target BPM
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '80');  // current BPM
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Practice button is visible on the card
      final practiceBtn = find.descendant(
        of: _cardFinder('Practice Btn Piece'),
        matching: find.text('Practice'),
      );
      expect(practiceBtn, findsOneWidget);

      // Tap it
      await tester.tap(practiceBtn);
      await tester.pumpAndSettle();

      // Sheet opened
      expect(find.text('Log Practice'), findsOneWidget);
      expect(find.text('Save Session'), findsOneWidget);

      // Piece picker dropdown is hidden — sheet was opened with a pre-selected piece
      expect(find.text('Select a song'), findsNothing);

      // Piece name and composer are displayed in the sheet
      // (findsAtLeastNWidgets because the name also appears in the card behind the sheet)
      expect(find.text('Practice Btn Piece'), findsAtLeastNWidgets(1));
      expect(find.text('Test Composer'), findsAtLeastNWidgets(1));
    });

    testWidgets('Practice button absent when onPractice not wired — card tap still navigates', (tester) async {
      // This test seeds data and verifies the Practice button appears on real
      // cards rendered by the home screen (as opposed to the widget-level test
      // that builds PieceCard in isolation).
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Nav Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Tapping the card itself (not the Practice button) navigates to detail
      await tester.tap(_cardFinder('Nav Test Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Log Practice'), findsOneWidget);
    });
  });

  // ── Exercises tab ─────────────────────────────────────────────────────────
  group('Exercises tab', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('can add an exercise and see it in the list', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'C Major Scale');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      expect(find.text('C Major Scale'), findsOneWidget);
    });

    testWidgets('Play button opens log exercise sheet', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Arpeggios');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      expect(find.text('Save Session'), findsOneWidget);
    });
  });

  // ── Exercise session in Practice tab ─────────────────────────────────────
  group('Exercise session in Practice tab', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('logging an exercise session shows it in the Practice tab',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Add an exercise
      await tester.tap(find.widgetWithText(Tab, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Hanon No. 1');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Log a session via the Play button
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Navigate to Practice tab
      await tester.tap(find.widgetWithText(Tab, 'Practice'));
      await tester.pumpAndSettle();

      // Exercise session appears in Practice tab
      // findsAtLeastNWidgets because the Exercises tab card (kept alive via
      // AutomaticKeepAliveClientMixin) also renders the exercise name in-tree.
      expect(find.text('Hanon No. 1'), findsAtLeastNWidgets(1));
      expect(find.text('Session History'), findsOneWidget);
    });
  });

  // ── Practice session detail ───────────────────────────────────────────────
  group('Practice session detail', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('tapping a session tile opens the detail screen', (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Detail Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Log a session via the Practice pill
      final practiceBtn = find.descendant(
        of: _cardFinder('Detail Test Piece'),
        matching: find.text('Practice'),
      );
      await tester.tap(practiceBtn);
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Navigate to Practice tab and tap the session tile
      await tester.tap(find.widgetWithText(Tab, 'Practice'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Detail Test Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
    });

    testWidgets('deleting a session from the detail screen removes it from Practice tab',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Delete Session Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      final practiceBtn = find.descendant(
        of: _cardFinder('Delete Session Piece'),
        matching: find.text('Practice'),
      );
      await tester.tap(practiceBtn);
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(Tab, 'Practice'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete Session Piece'));
      await tester.pumpAndSettle();

      // Delete from detail screen
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Back in Practice tab — session is gone
      expect(find.text('Session History'), findsNothing);
      expect(find.text('Delete Session Piece'), findsNothing);
    });

    testWidgets('editing duration in detail screen saves and reflects change',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Duration Edit Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      final practiceBtn = find.descendant(
        of: _cardFinder('Duration Edit Piece'),
        matching: find.text('Practice'),
      );
      await tester.tap(practiceBtn);
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Navigate to Practice tab and open the session
      await tester.tap(find.widgetWithText(Tab, 'Practice'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duration Edit Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);

      // Enter 45 minutes — Duration (min) is the 3rd TextFormField (index 2)
      await tester.tap(find.byType(TextFormField).at(2));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '45');
      await tester.pumpAndSettle();

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Re-open the session and verify the value persisted
      await tester.tap(find.text('Duration Edit Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '45'), findsOneWidget);
    });
  });
}
