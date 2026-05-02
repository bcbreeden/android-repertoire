import 'package:flutter/foundation.dart';
import '../database/database_helper.dart';
import '../models/exercise.dart';
import '../models/exercise_session.dart';

class ExerciseProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Exercise> _exercises = [];
  List<ExerciseSession> _sessions = [];
  Map<int, DateTime> _lastSessionDates = {};
  bool _isLoading = false;
  String? _error;

  List<ExerciseSession> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Exercises sorted by last session date descending; unsessioned sort to end.
  List<Exercise> get exercises {
    final list = List<Exercise>.from(_exercises);
    list.sort((a, b) {
      final aDate = _lastSessionDates[a.id];
      final bDate = _lastSessionDates[b.id];
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Exercise? getExerciseById(int id) {
    try {
      return _exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  DateTime? lastSessionDateForExercise(int id) => _lastSessionDates[id];

  List<ExerciseSession> sessionsForExercise(int exerciseId) =>
      _sessions.where((s) => s.exerciseId == exerciseId).toList();

  Future<void> loadExercises() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _exercises = await _db.getAllExercises();
      _sessions = await _db.getAllExerciseSessions();
      _lastSessionDates = await _db.getAllLastExerciseSessionDates();
    } catch (e) {
      _error = 'Failed to load exercises: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Exercise?> addExercise(Exercise exercise) async {
    try {
      final now = DateTime.now();
      final toInsert = exercise.copyWith(createdAt: now, updatedAt: now);
      final id = await _db.insertExercise(toInsert);
      final created = toInsert.copyWith(id: id);
      _exercises.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to add exercise: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Exercise?> updateExercise(Exercise exercise) async {
    try {
      final updated = exercise.copyWith(updatedAt: DateTime.now());
      await _db.updateExercise(updated);
      final idx = _exercises.indexWhere((e) => e.id == exercise.id);
      if (idx != -1) _exercises[idx] = updated;
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Failed to update exercise: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteExercise(int id) async {
    try {
      await _db.deleteExercise(id);
      _exercises.removeWhere((e) => e.id == id);
      _sessions.removeWhere((s) => s.exerciseId == id);
      _lastSessionDates.remove(id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete exercise: $e';
      notifyListeners();
      return false;
    }
  }

  Future<void> logSession(
    int exerciseId, {
    int? bpm,
    String? notes,
    int? durationSeconds,
  }) async {
    try {
      final now = DateTime.now();
      final session = ExerciseSession(
        exerciseId: exerciseId,
        timestamp: now,
        bpm: bpm,
        notes: notes,
        durationSeconds: durationSeconds,
      );
      final id = await _db.insertExerciseSession(session);
      final saved = ExerciseSession(
        id: id,
        exerciseId: exerciseId,
        timestamp: now,
        bpm: bpm,
        notes: notes,
        durationSeconds: durationSeconds,
      );
      _sessions.insert(0, saved);
      _lastSessionDates[exerciseId] = now;

      // Touch updated_at on the exercise so it sorts to top
      final exercise = getExerciseById(exerciseId);
      if (exercise != null) {
        final updated = exercise.copyWith(updatedAt: now);
        await _db.updateExercise(updated);
        final idx = _exercises.indexWhere((e) => e.id == exerciseId);
        if (idx != -1) _exercises[idx] = updated;
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to log session: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
