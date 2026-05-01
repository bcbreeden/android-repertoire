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
    main_screen.dart         # TabBarView: Pieces + Practice tabs
    home_screen.dart         # CustomScrollView with slivers; filter chips; piece list
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

## Testing

### Unit Tests (`test/`)

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

Database tests use `sqflite_common_ffi` (dev dependency) with `databaseFactory = databaseFactoryFfi`. Each test file's `setUp` deletes all rows from `pieces`, `practice_sessions`, and `app_opens`. Each file has a `tearDownAll` that calls `DatabaseHelper.instance.close()`.

### Integration Tests (`integration_test/`)

Run with:
```
flutter test integration_test/app_test.dart -d <device-id>
```

Key helpers in `app_test.dart`:
- `_cardFinder(name)` — `find.byWidgetPredicate` matching `PieceCard.piece.name`. Uses `skipOffstage: false` for assertions (to catch cards in SliverList regardless of scroll position).
- `_openPiece(tester, name)` — Uses `skipOffstage: true` (default) finder for `scrollUntilVisible` so `dragUntilVisible` loops correctly, then taps.
- `_advanceOnce(tester)` — Taps "Advance to…" button and confirms.

Integration test pitfalls to remember:
- `_RecentMilestones` section at the top of the home screen always shows piece names — use `_cardFinder` not `find.text()` to avoid false positives.
- `FilterChip`s scroll off-screen when the list is scrolled down; always call `tester.ensureVisible(chip)` before tapping a chip.
- Scroll direction: `drag(Offset(0, negative))` = drag UP = scroll DOWN to reveal content below the fold.
- `find.byType(Scrollable).first` targets the main `CustomScrollView` scrollable.

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
# Run unit tests
flutter test test/

# Run integration tests on a specific device
flutter test integration_test/app_test.dart -d emulator-5554

# Run a single integration test by name
flutter test integration_test/app_test.dart -d emulator-5554 --name "filter chips"

# List connected devices
flutter devices
```
