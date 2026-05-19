import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:repertoire/database/database_helper.dart';
import 'package:repertoire/main.dart' as app;
import 'package:repertoire/widgets/piece_card.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Key on the main CustomScrollView in the Pieces tab.
const _piecesScrollKey = Key('pieces_scroll');

/// Finds the vertical Scrollable inside the keyed CustomScrollView.
/// scrollUntilVisible requires a Scrollable, not the CustomScrollView itself.
/// Filters by axisDirection to exclude the horizontal Scrollable from the
/// filter bar's SingleChildScrollView.
Finder get _piecesScrollable => find.descendant(
      of: find.byKey(_piecesScrollKey),
      matching: find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      ),
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
/// Handles the CelebrationScreen that appears when advancing to Repertoire.
Future<void> _advanceOnce(WidgetTester tester) async {
  await tester.ensureVisible(find.textContaining('Promote to').first);
  await tester.pumpAndSettle();
  await tester.tap(find.textContaining('Promote to').first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Confirm'));
  // Pump with fixed durations instead of pumpAndSettle so that the Lottie
  // animation on the celebration screen does not prevent settling.
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.text('Dismiss').evaluate().isNotEmpty) break;
  }
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

/// Starts the app and waits for the splash screen to complete.
/// app.main() is async (awaits themeNotifier.load() via a platform channel
/// before calling runApp), so pumpAndSettle alone can return before runApp
/// fires. The extra pump bridges this gap consistently across all devices.
Future<void> _startApp(WidgetTester tester) async {
  app.main();
  await tester.pumpAndSettle();
  await tester.pump(const Duration(seconds: 2));
  await tester.pumpAndSettle();
}

/// Dismisses the software keyboard and waits for the OS-level dismiss
/// animation to fully complete before the caller taps a button.
/// pumpAndSettle() alone only settles Flutter animations; the Android keyboard
/// hides asynchronously via InputMethodManager, so an extra real-time pump
/// is needed (especially on API 37 where the dismiss animation is longer).
Future<void> _dismissKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  await tester.pump(const Duration(milliseconds: 500));
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

    testWidgets('home screen loads with all tabs', (tester) async {
      await _startApp(tester);

      expect(find.text('Songs', skipOffstage: false), findsOneWidget);
      expect(find.text('Practice', skipOffstage: false), findsOneWidget);
      expect(find.text('Stats', skipOffstage: false), findsOneWidget);
    });

    testWidgets('can add a new piece', (tester) async {
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // If paywall appears (too many pieces already), skip gracefully
      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active — clear seeded data to test adding pieces.');
        return;
      }

      // Step 1: fill required fields (Title at index 0, Total Measures at index 4)
      // Indices shifted: 0=Title, 1=Composer, 2=Book, 3=Page, 4=Total Measures, 5=Target BPM, 6=Current BPM
      await tester.enterText(find.byType(TextFormField).at(0), 'Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '64');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Step 2: save
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      expect(find.text('Test Piece'), findsAtLeastNWidgets(1));
    });

    testWidgets('piece card shows stage badge', (tester) async {
      await _startApp(tester);

      expect(find.text('Learning'), findsWidgets);
    });

    testWidgets('filter chips filter the list', (tester) async {
      await _startApp(tester);

      // Tap Learning chip — chip always exists even with 0 pieces in stage
      await _tapChip(tester, 'Learning');
      await tester.pumpAndSettle();

      // All chip should still be visible in the filter bar
      expect(find.textContaining('All'), findsOneWidget);

      // Restore
      await _tapChip(tester, 'All');
      await tester.pumpAndSettle();
    });

    testWidgets('tapping a piece opens detail screen', (tester) async {
      await _startApp(tester);

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
      await _startApp(tester);

      // ── Add ──────────────────────────────────────────────────────────────
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active — clear seeded data first.');
        return;
      }

      // Step 1: all available fields
      // Indices: 0=Title, 1=Composer, 2=Book, 3=Page, 4=Total Measures, 5=Target BPM, 6=Current BPM
      await tester.enterText(find.byType(TextFormField).at(0), 'Full Field Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Composer');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '80');  // Total Measures
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(5), '120'); // Target BPM
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(6), '60');  // Current BPM
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
      // Edit form field order: Title(0), Composer(1), Book(2), Page(3),
      // Total Measures(4), Measures Learned(5), Current Tempo(6), Target Tempo(7), Notes(8)
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

      await tester.tap(fields.at(4));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(4), '96');  // Total Measures
      await tester.pumpAndSettle();

      await tester.tap(fields.at(5));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(5), '48');  // Measures Learned
      await tester.pumpAndSettle();

      await tester.tap(fields.at(6));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(6), '72');  // Current Tempo
      await tester.pumpAndSettle();

      // Scroll to expose Target Tempo and Notes fields
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.tap(fields.at(7));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(7), '144');  // Target Tempo
      await tester.pumpAndSettle();

      await tester.tap(fields.at(8));
      await tester.pumpAndSettle();
      await tester.enterText(fields.at(8), 'Edited notes');
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
      await _startApp(tester);

      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();

      final hasValidState =
          find.text('No sessions yet').evaluate().isNotEmpty ||
          find.text('Nothing added yet').evaluate().isNotEmpty ||
          find.text('Session History').evaluate().isNotEmpty;
      expect(hasValidState, isTrue);
    });

    testWidgets('can open log practice sheet and see timer', (tester) async {
      await _startApp(tester);

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
      await _startApp(tester);

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
      await _startApp(tester);

      expect(find.text('Repertoire'), findsAtLeastNWidgets(1));
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
      await _startApp(tester);

      // Each stage chip should show a count from the seeded data
      expect(find.textContaining('Learning'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Repertoire'), findsAtLeastNWidgets(1));

      // ── Learning filter ───────────────────────────────────────────────────
      await _tapChip(tester, 'Learning');
      await tester.scrollUntilVisible(
        _cardFinder('Clair de Lune'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Clair de Lune'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Prelude in C# Minor'), findsNothing); // Repertoire

      // ── Repertoire filter ─────────────────────────────────────────────────
      await _tapChip(tester, 'Repertoire');
      await tester.scrollUntilVisible(
        _cardFinder('Gymnopédie No. 3'),
        -500,
        scrollable: _piecesScrollable,
      );
      expect(_cardFinder('Gymnopédie No. 3'), findsAtLeastNWidgets(1));
      expect(_cardFinder('Clair de Lune'), findsNothing);

      // ── All filter restores the full list ─────────────────────────────────
      await _tapChip(tester, 'All');
      expect(find.textContaining('All'), findsAtLeastNWidgets(1));
    });

    testWidgets('advancing a piece moves it to the next stage', (tester) async {
      await _startApp(tester);

      // 'Clair de Lune' is in Learning — near top of sorted list
      await _openPiece(tester, 'Clair de Lune');

      expect(find.text('Log Practice'), findsOneWidget);

      // Advance from Learning → Repertoire (celebration screen auto-dismissed)
      await _advanceOnce(tester);

      // Stage badge on detail screen now shows Repertoire
      expect(find.textContaining('Repertoire'), findsAtLeastNWidgets(1));

      await _goBack(tester);

      // PiecesTab preserves scroll position via AutomaticKeepAliveClientMixin.
      // Scroll back to top so the SliverToBoxAdapter holding the filter chips
      // is rendered in the element tree before we try to interact with them.
      await tester.drag(find.byKey(_piecesScrollKey), const Offset(0, 10000));
      await tester.pumpAndSettle();

      // Learning filter should no longer contain Clair de Lune
      await _tapChip(tester, 'Learning');
      expect(_cardFinder('Clair de Lune'), findsNothing);

      // Repertoire filter should now contain it
      await _tapChip(tester, 'Repertoire');
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
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active — cannot add song to test deletion.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Delete Me');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
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
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Keep Me');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
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
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Session Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '64');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Open the log sheet via the piece detail screen
      await _openPiece(tester, 'Session Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      // Fill in measures learned
      await tester.enterText(find.byType(TextFormField).at(0), '32');
      await tester.pumpAndSettle();

      // Dismiss keyboard so Save Session button is tappable
      await _dismissKeyboard(tester);

      // Save
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Back to songs list, then switch to Practice tab
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
      await tester.pumpAndSettle();

      // Session appears — piece name is shown in the session tile
      expect(find.text('Session Piece'), findsAtLeastNWidgets(1));
      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('saved session chip shows measures in the Practice tab', (tester) async {
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Chip Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '80');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      await _openPiece(tester, 'Chip Test Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      // Enter 55 measures
      await tester.enterText(find.byType(TextFormField).at(0), '55');
      await tester.pumpAndSettle();

      // Dismiss keyboard so Save Session button is tappable
      await _dismissKeyboard(tester);

      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Back to songs list, then switch to Practice tab
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
      await tester.pumpAndSettle();

      // The measures chip should show "55 / 80 measures"
      expect(find.text('55 / 80 measures'), findsOneWidget);
    });
  });

  // ── Practice button ───────────────────────────────────────────────────────
  // ── Log practice via detail screen ───────────────────────────────────────
  group('Log practice via detail screen', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('opening detail screen Log Practice shows sheet pre-filled for that piece', (tester) async {
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Detail Log Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'Test Composer');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '64');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Open detail screen and tap Log Practice
      await _openPiece(tester, 'Detail Log Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      // Sheet opened with piece pre-selected (no dropdown shown)
      expect(find.text('Log Practice'), findsAtLeastNWidgets(1));
      expect(find.text('Save Session'), findsOneWidget);
      expect(find.text('Select a song'), findsNothing);

      // Piece name and composer shown in the sheet
      expect(find.text('Detail Log Piece'), findsAtLeastNWidgets(1));
      expect(find.text('Test Composer'), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping a card navigates to the detail screen', (tester) async {
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Nav Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

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
      await _startApp(tester);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'C Major Scale');
      await tester.pumpAndSettle();

      // Dismiss keyboard so the viewport expands and Add Exercise is in range.
      await _dismissKeyboard(tester);
      await tester.ensureVisible(find.text('Add Exercise', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      expect(find.text('C Major Scale'), findsOneWidget);
    });

    testWidgets('Play button opens log exercise sheet', (tester) async {
      await _startApp(tester);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Arpeggios');
      await tester.pumpAndSettle();

      // Dismiss keyboard so the viewport expands and Add Exercise is in range.
      await _dismissKeyboard(tester);
      await tester.ensureVisible(find.text('Add Exercise', skipOffstage: false));
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
      await _startApp(tester);

      // Add an exercise
      await tester.tap(find.widgetWithText(NavigationDestination, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Hanon No. 1');
      await tester.pumpAndSettle();

      // Dismiss keyboard so the viewport expands and Add Exercise is in range.
      await _dismissKeyboard(tester);
      await tester.ensureVisible(find.text('Add Exercise', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Log a session via the Play button
      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);

      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Navigate to Practice tab
      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
      await tester.pumpAndSettle();

      // Exercise session appears in Practice tab
      // findsAtLeastNWidgets because the Exercises tab card (kept alive via
      // AutomaticKeepAliveClientMixin) also renders the exercise name in-tree.
      expect(find.text('Hanon No. 1'), findsAtLeastNWidgets(1));
      expect(find.text('Session History'), findsOneWidget);
    });

    testWidgets('tapping exercise session in Practice tab opens session detail',
        (tester) async {
      await _startApp(tester);

      // Add exercise and log a session
      await tester.tap(find.widgetWithText(NavigationDestination, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Scales');
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.ensureVisible(find.text('Add Exercise', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Play'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Navigate to Practice tab and tap the exercise session tile
      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining(RegExp(r'\d{1,2}:\d{2} [AP]M')).first);
      await tester.pumpAndSettle();

      // Should open the session detail screen directly
      expect(find.text('Session Details'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  // ── Exercise session detail ───────────────────────────────────────────────
  group('Exercise session detail', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    /// Helper: add exercise 'Edit Me', log a session, navigate to ExerciseDetailScreen.
    Future<void> _setupExerciseWithSession(WidgetTester tester) async {
      await _startApp(tester);

      await tester.tap(find.widgetWithText(NavigationDestination, 'Exercises'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), 'Edit Me');
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.ensureVisible(find.text('Add Exercise', skipOffstage: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Exercise'));
      await tester.pumpAndSettle();

      // Log a session via detail screen
      await tester.tap(find.text('Edit Me'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Session'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();
    }

    testWidgets('tapping a session tile opens the session detail screen',
        (tester) async {
      await _setupExerciseWithSession(tester);

      // A session tile is now visible; tap it
      await tester.tap(find.textContaining(RegExp(r'\d{1,2}:\d{2} [AP]M')).first);
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('editing duration in exercise session detail saves correctly',
        (tester) async {
      await _setupExerciseWithSession(tester);

      await tester.tap(find.textContaining(RegExp(r'\d{1,2}:\d{2} [AP]M')).first);
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);

      // Enter 20 minutes — Duration (min) is the first TextFormField (index 0)
      await tester.tap(find.byType(TextFormField).at(0));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '20');
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Back on exercise detail — timer chip should show 20:00
      expect(find.text('20:00'), findsOneWidget);
    });

    testWidgets('deleting an exercise session removes it from session history',
        (tester) async {
      await _setupExerciseWithSession(tester);

      await tester.tap(find.textContaining(RegExp(r'\d{1,2}:\d{2} [AP]M')).first);
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Back on exercise detail — no session history
      expect(find.text('SESSION HISTORY'), findsNothing);
    });
  });

  // ── Practice session detail ───────────────────────────────────────────────
  group('Practice session detail', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
    });

    testWidgets('tapping a session tile opens the detail screen', (tester) async {
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Detail Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Log a session via the detail screen
      await _openPiece(tester, 'Detail Test Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      // Navigate back then to Practice tab
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Detail Test Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
    });

    testWidgets('deleting a session from the detail screen removes it from Practice tab',
        (tester) async {
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Delete Session Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      await _openPiece(tester, 'Delete Session Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
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
      await _startApp(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Duration Edit Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      await _openPiece(tester, 'Duration Edit Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to Practice tab and open the session
      await tester.tap(find.widgetWithText(NavigationDestination, 'Practice'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duration Edit Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);

      // Enter 45 minutes — Duration (min) is the 3rd TextFormField (index 2)
      await tester.tap(find.byType(TextFormField).at(2));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(2), '45');
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Changes'));
      await tester.pumpAndSettle();

      // Re-open the session and verify the value persisted
      await tester.tap(find.text('Duration Edit Piece'));
      await tester.pumpAndSettle();

      expect(find.text('Session Details'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, '45'), findsOneWidget);
    });
  });

  // ── Stats tab ─────────────────────────────────────────────────────────────
  group('Stats tab', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('weekly_goal_hours');
    });

    testWidgets('Stats tab shows empty state when no data', (tester) async {
      await _startApp(tester);

      await tester.tap(find.text('Stats').last);
      await tester.pumpAndSettle();

      expect(find.text('No stats yet'), findsOneWidget);
    });

    testWidgets('Stats tab shows summary stats after logging a session',
        (tester) async {
      await _startApp(tester);

      // Add a song
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Stats Test Piece');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(4), '32');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      // Log a session via the detail screen
      await _openPiece(tester, 'Stats Test Piece');
      await tester.tap(find.text('Log Practice'));
      await tester.pumpAndSettle();

      await _dismissKeyboard(tester);
      await tester.tap(find.text('Save Session'));
      await tester.pumpAndSettle();

      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate to Stats tab
      await tester.tap(find.text('Stats').last);
      await tester.pumpAndSettle();

      // Summary stats are present
      expect(find.text('Total Time'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);

      // Section headers
      expect(find.text('THIS WEEK · time'), findsOneWidget);
      expect(find.text('MOST PRACTICED'), findsOneWidget);
    });

    testWidgets('weekly goal can be set and cleared', (tester) async {
      await _startApp(tester);

      // Add a song so the non-empty stats path renders, putting LAST 7 DAYS near top
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      if (find.text('Next').evaluate().isEmpty) {
        markTestSkipped('Paywall active.');
        return;
      }

      await tester.enterText(find.byType(TextFormField).at(0), 'Goal Test Song');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add Song'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Stats').last);
      await tester.pumpAndSettle();

      // No goal set — "Set goal" button with outlined flag icon
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);

      // Open goal dialog via Set goal button
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Practice Goal'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Accept the default (5h) and confirm
      await tester.tap(find.text('Set Goal'));
      await tester.pumpAndSettle();

      // Goal is now set — donut % shown, Set goal button gone, subtitle shows remaining time
      expect(find.byIcon(Icons.flag_outlined), findsNothing);
      expect(find.textContaining('to go'), findsOneWidget);

      // Open dialog again by tapping the donut percentage
      await tester.tap(find.textContaining('%'));
      await tester.pumpAndSettle();

      expect(find.text('Weekly Practice Goal'), findsOneWidget);
      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      // Goal cleared — Set goal button is back, no remaining-time subtitle
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
      expect(find.textContaining('to go'), findsNothing);
    });
  });

  group('Theme toggle', () {
    setUp(() async {
      await DatabaseHelper.instance.resetForTesting();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_dark_mode');
    });

    testWidgets('Toggle switches between dark and light mode', (tester) async {
      await _startApp(tester);

      // Default is dark — light_mode icon visible (tapping switches to light)
      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

      // Tap the toggle
      await tester.tap(find.byIcon(Icons.light_mode_outlined));
      await tester.pumpAndSettle();

      // Now in light mode — dark_mode icon visible
      expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);

      // Tap again to return to dark
      await tester.tap(find.byIcon(Icons.dark_mode_outlined));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
    });
  });
}
