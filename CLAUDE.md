# Repertoire — Claude Steering File

## Project Overview

**Repertoire** is a Flutter mobile app for pianists to track their practice progress through a 5-stage learning pipeline. Users add pieces, log practice sessions, and advance pieces stage by stage until they reach "Mastered" (repertoire).

Target platform: Android (portrait-only). iOS is not a current target.

## Architecture

```
lib/
  main.dart                  # App entry point, theme, MultiProvider (PieceProvider + ExerciseProvider)
  models/
    piece.dart               # Piece model with computed properties
    practice_session.dart    # Practice session model
    exercise.dart            # Exercise model (name, source, notes — no stages)
    exercise_session.dart    # ExerciseSession model (exerciseId, bpm, notes, duration)
  database/
    database_helper.dart     # SQLite singleton (sqflite), schema version 5
  providers/
    piece_provider.dart      # PieceProvider (ChangeNotifier) — single source of truth for songs
    exercise_provider.dart   # ExerciseProvider (ChangeNotifier) — single source of truth for exercises
  screens/
    splash_screen.dart       # Launch screen; parallel-loads both providers, then navigates to MainScreen
    main_screen.dart         # TabBarView: Songs | Exercises | Practice (3 tabs)
    home_screen.dart         # CustomScrollView with slivers; filter chips; song list
    piece_detail_screen.dart # Stage badge, advance button, practice history
    piece_form_screen.dart   # Add/edit piece wizard
    practice_screen.dart     # Practice session history (songs only)
    celebration_screen.dart  # Shown when piece reaches Mastered
    exercises_screen.dart    # ExercisesTab: list of exercises with Play buttons
    exercise_detail_screen.dart  # Exercise info + session history + Log Session FAB
    exercise_form_screen.dart    # Add/edit exercise (single-page form)
  widgets/
    piece_card.dart          # Card shown in the list; PieceCard widget
    exercise_card.dart       # ExerciseCard with always-visible Play pill button
    log_practice_sheet.dart  # Bottom sheet for logging a song practice session
    log_exercise_sheet.dart  # Bottom sheet for logging an exercise session (BPM, notes, timer)
    stage_progress_tracker.dart
    stats_card.dart
    paywall_sheet.dart
  utils/
    constants.dart           # Stage identifiers, kStageOrder, colors, nextStage(), etc.
```

## Stage Pipeline

Stages in order (defined in `kStageOrder`):
1. `learning` — Learning notes measure by measure
2. `note_perfection` — All notes correct
3. `dynamics_perfection` — Correct dynamics
4. `tempo_perfection` — Correct dynamics at any tempo
5. `repertoire` — All notes, dynamics, at target tempo ("Mastered")

Stage constants: `kStagelearning`, `kStageNotePerfection`, `kStageDynamicsPerfection`, `kStageTempoPerfection`, `kStageRepertoire`.

Helper functions in `constants.dart`: `nextStage()`, `isLastStage()`, `stageIndex()`.

## Key Design Decisions

- **DatabaseHelper is a singleton** (`DatabaseHelper.instance`). `_database` is reset to null on `close()`, allowing re-initialization. The `database` getter is public.
- **Stage timestamps are write-once** — `advancePieceStage()` and `setPieceStage()` only set a stage timestamp if it is currently null. First-achievement time is preserved forever.
- **Free tier cap**: `canAddPiece` returns false if `!isPremium && pieces.length >= 3`. Premium status is stored in `SharedPreferences` under key `'is_premium'`.
- **Piece sorting**: `filteredPieces` sorts by last practice date descending; pieces with no sessions sort to the end.
- **Portrait-only**: `SystemChrome.setPreferredOrientations` enforces this at startup.
- **Startup flow**: `SplashScreen` is the initial route. It parallel-loads both `PieceProvider.loadPieces()` and `ExerciseProvider.loadExercises()` via `Future.wait`, shows an animated progress bar, then crossfades to `MainScreen`. Neither `PiecesTab` nor `ExercisesTab` call load in `initState` — pull-to-refresh still works via explicit `onRefresh` callbacks.
- **Exercises tab**: Middle tab (index 1) in a 3-tab layout (Songs=0, Exercises=1, Practice=2). Exercises have no stages — just a name, optional source (e.g. "Hanon"), and optional notes. Sessions record BPM, notes, and duration. The Play button on each `ExerciseCard` is always visible (unconditional). Session history lives in `ExerciseDetailScreen`, not in `PracticeTab`.
- **DB schema v5**: Adds `exercises` and `exercise_sessions` tables. `deleteExercise` also cascades to `exercise_sessions`. `resetForTesting()` clears both new tables.
- **FAB per tab**: Songs tab → Add Song (with long-press shortcut to Log Practice), Exercises tab → Add Exercise, Practice tab → Log Practice. Uses `Consumer2<PieceProvider, ExerciseProvider>`. Practice FAB hides only when BOTH providers have zero items.
- **Dark gold theme**: `kGoldColor = #C9A227`, `kBackgroundColor = #111318`. All UI uses the centralized theme from `main.dart`.
- **Debug seed button**: `Icons.science_outlined` FAB visible only in `kDebugMode`. Seeds 40 pieces across all 5 stages with realistic data and practice sessions.
- **Naming convention**: All user-facing UI strings use "song"/"songs" (e.g. "Add Song", "No songs yet"). Code identifiers, DB table names (`pieces`, `practice_sessions`), and widget keys (`Key('pieces_scroll')`) remain unchanged.
- **Practice pill button**: `PieceCard` accepts an optional `onPractice` callback. When provided, a small "Practice" pill renders below the stage badge. Tapping it opens `LogPracticeSheet` pre-filled for that piece (name + composer shown, dropdown hidden). When `onPractice` is null the pill is absent and tapping the card navigates normally.
- **Practice session deletion**: In `PracticeTab`, each `_SessionTile` is wrapped in a `Dismissible` (swipe left-to-right to reveal red delete background). `onDismissed` calls `PieceProvider.deletePracticeSession(id)`, which removes the session from `_practiceSessions`, refreshes `_lastPracticeDates` via DB, and notifies listeners. A "Session deleted" `SnackBar` confirms the action. The outer session-group `Container` uses `clipBehavior: Clip.hardEdge` to keep the red dismiss background within the rounded corners.

## Development Workflow

Follow this order for every feature or fix:

1. **Build** the feature or fix.
2. **Write or update tests** — this is mandatory, not optional:
   - **Unit/widget tests**: every new method, model change, or widget behaviour change must have a corresponding test added or updated in `test/`. If existing tests break due to the change, fix them.
   - **Integration tests**: every new user-visible flow must have at least one end-to-end test added or updated in `integration_test/app_test.dart`. If existing integration tests are affected by the change (e.g. UI text changed, navigation changed), update them too.
   - Do not skip this step even for "small" changes — a fix with no test is incomplete.
3. **Run all tests** — unit tests first (fast, no device), then integration tests on both emulators. All must be green before pushing.
4. **Review and self-heal this steering file** — update any section that is now stale (architecture map, test file list, helpers, pitfalls, design decisions). Commit the updated `CLAUDE.md` alongside the feature changes.
5. **Push** (without `--no-verify` — the pre-push hook must pass).

```bash
# Step 2 & 4 — run everything (preferred)
bash test_all.sh

# Or manually:
# Unit + widget tests (no device needed)
flutter test test/

# Integration tests — all open emulators
for device in emulator-5554 emulator-5556; do
  echo "=== $device ==="
  flutter test integration_test/app_test.dart -d $device
done
```

**Windows note**: Flutter 3.41.x has two tooling bugs on Windows that prevent tests from running at all (not test failures — Flutter itself crashes before running a single test). `test_all.sh` works around both automatically:
- Kills lingering `dart.exe`/`flutter_tester.exe` processes that lock shader files
- Deletes stale `build/native_assets/windows/sqlite3.dll` before each run

The two emulators cover different API levels (emulator-5554 = API 37, emulator-5556 = API 29). Running both catches regressions on older APIs — API 29 in particular has different focus/keyboard behaviour, which is why form fields use tap-then-enterText rather than enterText alone.

## Testing

### Unit & Widget Tests (`test/`)

Run with:
```
flutter test test/
```

`dart_test.yaml` sets `concurrency: 1` — required to prevent SQLite lock conflicts between test files that share `DatabaseHelper.instance`.

Test files:
- `test/models/piece_test.dart` — Piece computed properties, copyWith, toMap/fromMap, equality
- `test/models/practice_session_test.dart` — PracticeSession toMap/fromMap
- `test/utils/constants_test.dart` — nextStage, isLastStage, stageIndex, constant integrity
- `test/database/database_helper_test.dart` — Full CRUD, stage advancement, streak, milestones
- `test/providers/piece_provider_test.dart` — filteredPieces, overallProgressPct, canAddPiece, deletePracticeSession, etc.
- `test/widgets/piece_card_test.dart` — PieceCard button visibility and tap-routing behaviour
- `test/widgets/log_practice_sheet_test.dart` — LogPracticeSheet timer controls, piece display (dropdown vs info row), prefill, Save button enabled state
- `test/widgets/exercise_card_test.dart` — ExerciseCard name/source display, Play button always visible, tap routing
- `test/providers/exercise_provider_test.dart` — ExerciseProvider CRUD, logSession, sorting by last session date

Database tests use `sqflite_common_ffi` (dev dependency) with `databaseFactory = databaseFactoryFfi`. Each test file's `setUp` deletes all rows from `pieces`, `practice_sessions`, and `app_opens`. Each file has a `tearDownAll` that calls `DatabaseHelper.instance.close()`.

Widget tests (e.g. `piece_card_test.dart`) wrap the widget under test in a plain `MaterialApp` + `Scaffold`. No SQLite or provider setup is needed.

### Integration Tests (`integration_test/`)

Run with:
```
flutter test integration_test/app_test.dart -d <device-id>
```

**DB isolation strategy:**
- Groups whose tests intentionally share state (e.g. "Pieces") use `setUpAll` to reset once before the group.
- Groups with independent tests use `setUp` to reset before each test.
- `DatabaseHelper.instance.resetForTesting()` deletes all rows without closing the connection.
- The "Stage advancement" group uses `setUpAll` to reset + seed once; both tests share that data.

Key helpers in `app_test.dart`:
- `_cardFinder(name)` — `find.byWidgetPredicate` matching `PieceCard.piece.name`. Uses `skipOffstage: false` so assertions work regardless of scroll position.
- `_piecesScrollable` — `find.descendant` targeting the `Scrollable` inside the `CustomScrollView` keyed `'pieces_scroll'`. Pass this as the `scrollable:` argument to `scrollUntilVisible`.
- `_openPiece(tester, name)` — scrolls to a `PieceCard` by name using `_piecesScrollable` and taps it.
- `_tapChip(tester, label)` — uses `skipOffstage: false` on the text finder and `ensureVisible` to handle chips that have scrolled off the top of the sliver.
- `_advanceOnce(tester)` — taps "Advance to…", confirms, and dismisses any celebration screen.

Integration test pitfalls:
- `_RecentMilestones` at the top of the home screen renders piece names — use `_cardFinder`, not `find.text()`, to avoid false positives.
- Filter chips live in a `SliverToBoxAdapter`. When the list is scrolled down, the sliver is disposed (not merely offstage). Use `_tapChip` which handles `ensureVisible`, and scroll back to the top with a large `drag(..., Offset(0, 10000))` after returning from a detail screen before interacting with chips.
- `PiecesTab` uses `AutomaticKeepAliveClientMixin`, so scroll position is preserved across navigation. Always scroll to top before tapping chips after `_goBack`.
- Scroll direction: `drag(Offset(0, negative))` = scroll DOWN; `drag(Offset(0, positive))` = scroll UP / back to top.
- **Keyboard blocking bottom-sheet buttons**: After `enterText` inside a modal bottom sheet, the soft keyboard remains up and its hit-test layer blocks taps on buttons near the bottom of the sheet (e.g. "Save Session"). Always call `FocusManager.instance.primaryFocus?.unfocus(); await tester.pumpAndSettle();` before tapping such buttons.
- **Practice tab empty-state text**: When both providers have zero items the text is "Nothing added yet"; when items exist but no sessions have been logged it is "No sessions yet". The old "No songs yet" string no longer exists.
- **Tab navigation in tests**: Use `find.widgetWithText(Tab, 'Exercises')` (not `find.text('Exercises')`) to avoid ambiguity with exercise names rendered elsewhere on screen.
- **Exercise names in Practice tab assertions**: When asserting an exercise name appears in the Practice tab after navigating from the Exercises tab, use `findsAtLeastNWidgets(1)` — the Exercises tab card remains in-tree via `AutomaticKeepAliveClientMixin` and is NOT wrapped in `Offstage`, so `skipOffstage: true` does not filter it out.

## Dependencies

```yaml
dependencies:
  sqflite: ^2.3.0        # SQLite database
  path: ^1.8.3
  provider: ^6.1.1       # State management (ChangeNotifier)
  intl: ^0.19.0          # Date formatting
  lottie: ^3.0.0         # Animations (celebration screen)
  in_app_purchase: ^3.2.0
  shared_preferences: ^2.3.0  # Premium flag storage

dev_dependencies:
  sqflite_common_ffi: ^2.4.0  # SQLite FFI for unit tests (no device needed)
  integration_test: sdk: flutter
```

## Common Commands

```bash
# Unit + widget tests (no device)
flutter test test/

# Integration tests — all open emulators
for device in emulator-5554 emulator-5556; do
  echo "=== $device ==="
  flutter test integration_test/app_test.dart -d $device
done

# Integration tests — single group, single device
flutter test integration_test/app_test.dart -d emulator-5554 --name "Practice button"

# List connected devices
flutter devices
```
