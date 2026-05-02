import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:repertoire/database/database_helper.dart';
import 'package:repertoire/models/exercise.dart';
import 'package:repertoire/providers/exercise_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Exercise _exercise({
  String name = 'Scales',
  String? source = 'Hanon',
  String? notes,
}) {
  final now = DateTime(2024, 1, 1, 12, 0);
  return Exercise(name: name, source: source, notes: notes,
      createdAt: now, updatedAt: now);
}

Future<ExerciseProvider> _freshProvider() async {
  SharedPreferences.setMockInitialValues({});
  final p = ExerciseProvider();
  await p.loadExercises();
  return p;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late ExerciseProvider provider;

  setUp(() async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('exercise_sessions');
    await db.delete('exercises');
    await db.delete('app_opens');
    provider = await _freshProvider();
  });

  tearDownAll(() async {
    await DatabaseHelper.instance.close();
  });

  // ── Initial state ─────────────────────────────────────────────────────────
  group('initial state', () {
    test('exercises is empty after load on clean DB', () {
      expect(provider.exercises, isEmpty);
    });

    test('sessions is empty after load on clean DB', () {
      expect(provider.sessions, isEmpty);
    });

    test('isLoading is false after load completes', () {
      expect(provider.isLoading, isFalse);
    });

    test('error is null after successful load', () {
      expect(provider.error, isNull);
    });
  });

  // ── addExercise ───────────────────────────────────────────────────────────
  group('addExercise', () {
    test('returns the created exercise with an id', () async {
      final created = await provider.addExercise(_exercise());
      expect(created, isNotNull);
      expect(created!.id, isNotNull);
    });

    test('exercise appears in exercises list', () async {
      await provider.addExercise(_exercise(name: 'Arpeggios'));
      expect(provider.exercises.any((e) => e.name == 'Arpeggios'), isTrue);
    });

    test('multiple exercises all appear', () async {
      await provider.addExercise(_exercise(name: 'Scales'));
      await provider.addExercise(_exercise(name: 'Hanon No. 1'));
      expect(provider.exercises.length, 2);
    });

    test('notifies listeners after adding', () async {
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.addExercise(_exercise());
      expect(notified, isTrue);
    });
  });

  // ── updateExercise ────────────────────────────────────────────────────────
  group('updateExercise', () {
    test('updated name is reflected in the list', () async {
      final created = await provider.addExercise(_exercise(name: 'Old Name'));
      await provider.updateExercise(created!.copyWith(name: 'New Name'));
      expect(provider.exercises.any((e) => e.name == 'New Name'), isTrue);
      expect(provider.exercises.any((e) => e.name == 'Old Name'), isFalse);
    });

    test('notifies listeners after updating', () async {
      final created = await provider.addExercise(_exercise());
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.updateExercise(created!.copyWith(name: 'Updated'));
      expect(notified, isTrue);
    });
  });

  // ── deleteExercise ────────────────────────────────────────────────────────
  group('deleteExercise', () {
    test('exercise is removed from the list', () async {
      final created = await provider.addExercise(_exercise(name: 'To Delete'));
      await provider.deleteExercise(created!.id!);
      expect(provider.exercises.any((e) => e.name == 'To Delete'), isFalse);
    });

    test('returns true on success', () async {
      final created = await provider.addExercise(_exercise());
      final result = await provider.deleteExercise(created!.id!);
      expect(result, isTrue);
    });

    test('notifies listeners after deleting', () async {
      final created = await provider.addExercise(_exercise());
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.deleteExercise(created!.id!);
      expect(notified, isTrue);
    });
  });

  // ── getExerciseById ───────────────────────────────────────────────────────
  group('getExerciseById', () {
    test('returns the exercise when it exists', () async {
      final created = await provider.addExercise(_exercise(name: 'Lookup Me'));
      final found = provider.getExerciseById(created!.id!);
      expect(found, isNotNull);
      expect(found!.name, 'Lookup Me');
    });

    test('returns null for an unknown id', () {
      expect(provider.getExerciseById(99999), isNull);
    });
  });

  // ── logSession ────────────────────────────────────────────────────────────
  group('logSession', () {
    test('session appears in sessions list', () async {
      final created = await provider.addExercise(_exercise());
      await provider.logSession(created!.id!, bpm: 120);
      expect(provider.sessions.any((s) => s.bpm == 120), isTrue);
    });

    test('sessionsForExercise returns only that exercise\'s sessions',
        () async {
      final a = await provider.addExercise(_exercise(name: 'A'));
      final b = await provider.addExercise(_exercise(name: 'B'));
      await provider.logSession(a!.id!, bpm: 100);
      await provider.logSession(b!.id!, bpm: 200);
      expect(provider.sessionsForExercise(a.id!).length, 1);
      expect(provider.sessionsForExercise(b.id!).length, 1);
    });

    test('lastSessionDateForExercise is set after logging', () async {
      final created = await provider.addExercise(_exercise());
      await provider.logSession(created!.id!);
      expect(
          provider.lastSessionDateForExercise(created.id!), isNotNull);
    });

    test('notifies listeners after logging', () async {
      final created = await provider.addExercise(_exercise());
      var notified = false;
      provider.addListener(() => notified = true);
      await provider.logSession(created!.id!);
      expect(notified, isTrue);
    });
  });

  // ── sorting ───────────────────────────────────────────────────────────────
  group('exercises sorting', () {
    test('exercises with recent sessions sort before unsessioned', () async {
      final noSession = await provider.addExercise(_exercise(name: 'No Session'));
      final withSession = await provider.addExercise(_exercise(name: 'With Session'));
      await provider.logSession(withSession!.id!);
      expect(provider.exercises.first.id, withSession.id);
      expect(provider.exercises.last.id, noSession!.id);
    });

    test('exercises with no sessions all sort to end', () async {
      await provider.addExercise(_exercise(name: 'A'));
      await provider.addExercise(_exercise(name: 'B'));
      // Both have no sessions — order is stable (both unsessioned = 0 compare)
      expect(provider.exercises.length, 2);
    });
  });
}
