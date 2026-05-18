# Repertoire — Claude Steering File

## Project Overview

**Repertoire** is a Flutter mobile app for pianists to track their practice progress through a 3-stage learning pipeline. Users add pieces, log practice sessions, and advance pieces stage by stage until they reach "Repertoire".

Target platform: Android (portrait-only). iOS is not a current target.

## Architecture

```
lib/
  main.dart                  # App entry point, theme, MultiProvider (PieceProvider + ExerciseProvider)
  models/
    piece.dart               # Piece model with computed properties
    practice_session.dart    # Practice session model
    exercise.dart            # Exercise model (name, source, notes, book, page — no stages)
    exercise_session.dart    # ExerciseSession model (exerciseId, bpm, notes, duration)
  database/
    database_helper.dart     # SQLite singleton (sqflite), schema version 9
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
    celebration_screen.dart  # Shown when piece reaches Repertoire
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
    book_field.dart          # Autocomplete widget for book name, shared by both forms
  utils/
    constants.dart           # Stage identifiers, kStageOrder, colors, nextStage(), etc.
    achievements.dart        # Achievement definitions (kAchievements list, Achievement class, AchievementCheck typedef)
```

## Stage Pipeline

Stages in order (defined in `kStageOrder`):
1. `learning` — Actively learning notes, measures, dynamics, tempo
2. `repertoire` — Performance-ready ("Mastered")

Stage constants: `kStageLearning`, `kStageRepertoire`.

Helper functions in `constants.dart`: `nextStage()`, `isLastStage()`, `stageIndex()`.

## Key Design Decisions

- **DatabaseHelper is a singleton** (`DatabaseHelper.instance`). `_database` is reset to null on `close()`, allowing re-initialization. The `database` getter is public.
- **Stage timestamps are write-once** — `advancePieceStage()` and `setPieceStage()` only set a stage timestamp if it is currently null. First-achievement time is preserved forever.
- **No backlog stage**: The pipeline is just two stages — `learning` → `repertoire`. All new pieces start in `learning` with `learningAt` set to creation time.
- **Free tier cap**: `canAddPiece` returns false if `!isPremium && pieces.length >= 3`. Premium status is stored in `SharedPreferences` under key `'is_premium'`.
- **Weekly practice goal**: Stored in `SharedPreferences` under key `'weekly_goal_hours'` (int, 1–20). Managed entirely within `_ThisWeekCard` (a `StatefulWidget` in `stats_screen.dart`). The flag icon button (outlined = no goal, filled = goal set) opens `_GoalDialog` (a slider dialog). The card shows a `LinearProgressIndicator` toward the goal when one is set; turns green when met. `_ThisWeekCard` is shown in both the normal and empty-state layout so users can set a goal even before logging any sessions.
- **Achievements**: 13 achievements defined in `lib/utils/achievements.dart` (`kAchievements` list). Each `Achievement` has an `id`, `name`, `description`, `icon`, `color`, and a `AchievementCheck` function `(PieceProvider, ExerciseProvider) → bool`. Unlock timestamps are persisted in `SharedPreferences` under keys `achievement_{id}`. The `_AchievementsCard` in `stats_screen.dart` is a `StatefulWidget` that loads unlock state on init, then re-checks whenever provider data changes (via `didUpdateWidget` with a signature-based diff). The card shows a 4-column `GridView` of tiles — colored icon + name when unlocked, lock icon + dimmed name when locked. Tapping a tile opens a detail dialog with description and unlock date. Achievements appear in both the empty-state and non-empty Stats layouts.
- **Piece sorting**: `filteredPieces` sorts by last practice date descending; pieces with no sessions sort to the end.
- **Portrait-only**: `SystemChrome.setPreferredOrientations` enforces this at startup.
- **Startup flow**: `SplashScreen` is the initial route. It parallel-loads both `PieceProvider.loadPieces()` and `ExerciseProvider.loadExercises()` via `Future.wait`, shows an animated progress bar, then crossfades to `MainScreen`. Neither `PiecesTab` nor `ExercisesTab` call load in `initState` — pull-to-refresh still works via explicit `onRefresh` callbacks.
- **Bottom NavigationBar**: `MainScreen` uses a `NavigationBar` (Material 3, bottom) with `IndexedStack` instead of a top `TabBar` + `TabBarView`. All four tabs are always mounted (IndexedStack keeps them alive), so `AutomaticKeepAliveClientMixin` on tab screens is redundant but harmless. NavigationBar is themed with `kBackgroundColor`, gold indicator, and `WidgetStateProperty` for label/icon colors.
- **Filter bar is horizontal scroll**: `_FilterBar` in `home_screen.dart` uses `SingleChildScrollView(scrollDirection: Axis.horizontal)` + `Row` instead of `Wrap`, so all filter chips stay on one row without wrapping.
- **Exercises tab**: Middle tab (index 1) in a 3-tab layout (Songs=0, Exercises=1, Practice=2). Exercises have no stages — just a name, optional source (e.g. "Hanon"), and optional notes. Sessions record BPM, notes, and duration. The Play button on each `ExerciseCard` is always visible (unconditional). Session history lives in `ExerciseDetailScreen`, not in `PracticeTab`.
- **DB schema v9**: Current version. v7 removed backlog stage; v8 dropped NOT NULL constraint on `measures` via table recreation; v9 added `book TEXT` and `page INTEGER` columns to both `pieces` and `exercises`. The `backlog_at` column remains in `pieces` (unused, harmless).
- **Book/page fields**: Both `Piece` and `Exercise` have optional `book` (String?) and `page` (int?) fields for referencing a music book and page number. In forms, book uses `BookField` (an `Autocomplete<String>` widget in `lib/widgets/book_field.dart`) populated from `PieceProvider.bookNames` / `ExerciseProvider.bookNames` — unique, sorted lists of previously used book names. The autocomplete `TextEditingController` is owned by `Autocomplete` and exposed via an `onControllerReady` callback; the form reads it at save time via a nullable `_bookFieldController` field.
- **FAB per tab**: Songs tab → Add Song (with long-press shortcut to Log Practice), Exercises tab → Add Exercise, Practice tab → Log Practice. Uses `Consumer2<PieceProvider, ExerciseProvider>`. Practice FAB hides only when BOTH providers have zero items.
- **Dark gold theme**: `kGoldColor = #C9A227`, `kBackgroundColor = #111318`. All UI uses the centralized theme from `main.dart`.
- **Debug seed button**: `Icons.science_outlined` FAB visible only in `kDebugMode`. Seeds 40 pieces across 2 stages (30 Learning, 10 Repertoire) with realistic data and practice sessions.
- **Naming convention**: All user-facing UI strings use "song"/"songs" (e.g. "Add Song", "No songs yet"). Code identifiers, DB table names (`pieces`, `practice_sessions`), and widget keys (`Key('pieces_scroll')`) remain unchanged.
- **No practice pill on cards**: `PieceCard` has no `onPractice` callback. Tapping a card always navigates to the detail screen. Practice sessions are logged via the "Log Practice" button on the detail screen, or via the FAB (Songs tab long-press or Practice tab FAB).
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
- `test/widgets/piece_card_test.dart` — PieceCard name/composer display, last practiced row, stage badge, tap routing
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
- The "Stats tab" group also clears `SharedPreferences` key `'weekly_goal_hours'` in `setUp` to avoid goal state leaking between tests.

Key helpers in `app_test.dart`:
- `_cardFinder(name)` — `find.byWidgetPredicate` matching `PieceCard.piece.name`. Uses `skipOffstage: false` so assertions work regardless of scroll position.
- `_piecesScrollable` — `find.descendant` targeting the **vertical** `Scrollable` inside the `CustomScrollView` keyed `'pieces_scroll'` (filters by `axisDirection == AxisDirection.down` to exclude the horizontal `Scrollable` inside the filter bar's `SingleChildScrollView`). Pass this as the `scrollable:` argument to `scrollUntilVisible`.
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
- **Tab navigation in tests**: Use `find.widgetWithText(NavigationDestination, 'Exercises')` (not `find.text('Exercises')`) to avoid ambiguity with exercise names rendered elsewhere on screen. Same pattern for `'Practice'`.
- **Stats tab ListView cache extent**: Cards deep in the Stats `ListView` (e.g. `MOST PRACTICED`, `DATA`) may not be built if the achievements grid pushes them far below the viewport. Use `skipOffstage: false` only for widgets that are built but invisible; for un-built ListView children, scroll first or omit the assertion. `ensureVisible` also requires the widget to already be in the element tree (built by ListView), so it won't work for un-built items.
- **Exercise names in Practice tab assertions**: When asserting an exercise name appears in the Practice tab after navigating from the Exercises tab, use `findsAtLeastNWidgets(1)` — the Exercises tab card remains in-tree via `AutomaticKeepAliveClientMixin` and is NOT wrapped in `Offstage`, so `skipOffstage: true` does not filter it out.
- **Piece wizard field indices**: `BookField` (Autocomplete) renders a `TextFormField` and is visible to `find.byType(TextFormField)`. Step 1 order: 0=Title, 1=Composer, 2=Book, 3=Page, 4=Total Measures, 5=Target BPM, 6=Current BPM. Edit form order: 0=Title, 1=Composer, 2=Book, 3=Page, 4=Total Measures, 5=Measures Learned, 6=Current Tempo, 7=Target Tempo, 8=Notes.
- **Exercise form field indices**: 0=Name, 1=Source, 2=Book (Autocomplete TextFormField), 3=Page, 4=Notes.
- **"Add Exercise" button scrolling**: The exercise form's `ListView` may need `await tester.ensureVisible(find.text('Add Exercise', skipOffstage: false))` before tapping — the extra book/page fields push the button below the visible area when the keyboard is up.

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
