# Repertoire — Claude Steering File

## Project Overview

**Repertoire** is a Flutter mobile app for pianists to track their practice progress through a 5-stage learning pipeline. Users add pieces, log practice sessions, and advance pieces stage by stage until they reach "Mastered" (repertoire).

Target platform: Android (portrait-only). iOS is not a current target.

## Architecture

```
lib/
  main.dart                  # App entry point, theme definition, ChangeNotifierProvider
  models/
    piece.dart               # Piece model with computed properties
    practice_session.dart    # Practice session model
  database/
    database_helper.dart     # SQLite singleton (sqflite), schema version 4
  providers/
    piece_provider.dart      # PieceProvider (ChangeNotifier) — single source of truth
  screens/
    main_screen.dart         # TabBarView: Songs + Practice tabs
    home_screen.dart         # CustomScrollView with slivers; filter chips; song list
    piece_detail_screen.dart # Stage badge, advance button, practice history
    piece_form_screen.dart   # Add/edit piece wizard
    practice_screen.dart     # Practice session history
    celebration_screen.dart  # Shown when piece reaches Mastered
  widgets/
    piece_card.dart          # Card shown in the list; PieceCard widget
    log_practice_sheet.dart  # Bottom sheet for logging a session
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
- **Dark gold theme**: `kGoldColor = #C9A227`, `kBackgroundColor = #111318`. All UI uses the centralized theme from `main.dart`.
- **Debug seed button**: `Icons.science_outlined` FAB visible only in `kDebugMode`. Seeds 40 pieces across all 5 stages with realistic data and practice sessions.
- **Naming convention**: All user-facing UI strings use "song"/"songs" (e.g. "Add Song", "No songs yet"). Code identifiers, DB table names (`pieces`, `practice_sessions`), and widget keys (`Key('pieces_scroll')`) remain unchanged.
- **Practice pill button**: `PieceCard` accepts an optional `onPractice` callback. When provided, a small "Practice" pill renders below the stage badge. Tapping it opens `LogPracticeSheet` pre-filled for that piece (name + composer shown, dropdown hidden). When `onPractice` is null the pill is absent and tapping the card navigates normally.

## Development Workflow

Follow this order for every feature or fix:

1. **Build** the feature or fix.
2. **Run existing tests** — unit tests first (fast, no device), then integration tests.
3. **Write new tests** — unit/widget tests for logic and widget behaviour; integration tests for any new user-visible flow.
4. **Run tests again** — all must be green before pushing.
5. **Review and self-heal this steering file** — update any section that is now stale (architecture map, test file list, helpers, pitfalls, design decisions). Commit the updated `CLAUDE.md` alongside the feature changes.
6. **Push.**

```bash
# Step 2 & 4 — unit + widget tests (no device needed)
flutter test test/

# Step 2 & 4 — integration tests (run against ALL open emulators)
for device in emulator-5554 emulator-5556; do
  echo "=== $device ==="
  flutter test integration_test/app_test.dart -d $device
done
```

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
- `test/providers/piece_provider_test.dart` — filteredPieces, overallProgressPct, canAddPiece, etc.
- `test/widgets/piece_card_test.dart` — PieceCard button visibility and tap-routing behaviour

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
