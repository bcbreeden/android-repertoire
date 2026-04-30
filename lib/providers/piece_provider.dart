import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database_helper.dart';
import '../models/piece.dart';
import '../models/practice_session.dart';
import '../utils/constants.dart';

class PieceProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Piece> _pieces = [];
  String _activeFilter = 'all';
  bool _isLoading = false;
  String? _error;
  int _streak = 0;
  bool _isPremium = false;
  Map<int, DateTime> _lastPracticeDates = {};

  List<Piece> get pieces => _pieces;
  String get activeFilter => _activeFilter;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get streak => _streak;
  bool get isPremium => _isPremium;

  List<Piece> get filteredPieces {
    if (_activeFilter == 'all') return _pieces;
    return _pieces.where((p) => p.status == _activeFilter).toList();
  }

  int get totalCount => _pieces.length;

  int get repertoireCount =>
      _pieces.where((p) => p.status == kStageRepertoire).length;

  double get overallProgressPct {
    if (_pieces.isEmpty) return 0.0;
    final totalStageIndex =
        _pieces.fold<int>(0, (sum, p) => sum + p.stageIndex);
    final maxPossible = _pieces.length * (kStageOrder.length - 1);
    if (maxPossible == 0) return 0.0;
    return (totalStageIndex / maxPossible * 100).clamp(0.0, 100.0);
  }

  Map<String, int> get stageCounts {
    final map = <String, int>{};
    for (final stage in kStageOrder) {
      map[stage] = _pieces.where((p) => p.status == stage).length;
    }
    return map;
  }

  bool get canAddPiece => _isPremium || _pieces.length < 3;

  DateTime? lastPracticeDateForPiece(int pieceId) => _lastPracticeDates[pieceId];

  Future<List<Map<String, dynamic>>> get recentMilestones =>
      _db.getRecentMilestones(limit: 5);

  Future<void> loadPieces() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _db.recordAppOpen();
      _pieces = await _db.getAllPieces();
      _streak = await _db.getStreak();
      _lastPracticeDates = await _db.getAllLastSessionDates();

      final prefs = await SharedPreferences.getInstance();
      _isPremium = prefs.getBool('is_premium') ?? false;
    } catch (e) {
      _error = 'Failed to load pieces: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setFilter(String filter) {
    if (_activeFilter == filter) return;
    _activeFilter = filter;
    notifyListeners();
  }

  Future<Piece?> addPiece(Piece piece) async {
    try {
      final now = DateTime.now();
      final newPiece = piece.copyWith(
        createdAt: now,
        updatedAt: now,
        learningAt: now, // Always set learning_at on creation
      );
      final id = await _db.insertPiece(newPiece);
      final created = newPiece.copyWith(id: id);
      _pieces.insert(0, created);
      notifyListeners();
      return created;
    } catch (e) {
      _error = 'Failed to add piece: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Piece?> updatePiece(Piece piece) async {
    try {
      final updated = piece.copyWith(updatedAt: DateTime.now());
      await _db.updatePiece(updated);
      final idx = _pieces.indexWhere((p) => p.id == piece.id);
      if (idx >= 0) {
        _pieces[idx] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      _error = 'Failed to update piece: $e';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deletePiece(int id) async {
    try {
      await _db.deletePiece(id);
      _pieces.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete piece: $e';
      notifyListeners();
      return false;
    }
  }

  Future<Piece?> advanceStage(Piece piece) async {
    try {
      final updated = await _db.advancePieceStage(piece);
      if (updated != null) {
        final idx = _pieces.indexWhere((p) => p.id == piece.id);
        if (idx >= 0) {
          _pieces[idx] = updated;
        }
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = 'Failed to advance stage: $e';
      notifyListeners();
      return null;
    }
  }

  Future<Piece?> setStage(Piece piece, String newStatus) async {
    try {
      final updated = await _db.setPieceStage(piece, newStatus);
      if (updated != null) {
        final idx = _pieces.indexWhere((p) => p.id == piece.id);
        if (idx >= 0) {
          _pieces[idx] = updated;
        }
        notifyListeners();
      }
      return updated;
    } catch (e) {
      _error = 'Failed to set stage: $e';
      notifyListeners();
      return null;
    }
  }

  Future<void> setPremium(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_premium', value);
    _isPremium = value;
    notifyListeners();
  }

  Future<void> logPractice(
    int pieceId, {
    int? measuresLearned,
    int? currentBpm,
    String? notes,
  }) async {
    try {
      final session = PracticeSession(
        pieceId: pieceId,
        timestamp: DateTime.now(),
        measuresLearned: measuresLearned,
        currentBpm: currentBpm,
        notes: notes,
      );
      await _db.insertPracticeSession(session);

      // Optionally update piece measures/bpm if provided
      if (measuresLearned != null || currentBpm != null) {
        final piece = getPieceById(pieceId);
        if (piece != null) {
          final updatedPiece = piece.copyWith(
            measuresLearned: measuresLearned ?? piece.measuresLearned,
            currentTempo: currentBpm ?? piece.currentTempo,
            updatedAt: DateTime.now(),
          );
          await _db.updatePiece(updatedPiece);
          final idx = _pieces.indexWhere((p) => p.id == pieceId);
          if (idx >= 0) {
            _pieces[idx] = updatedPiece;
          }
        }
      }

      // Reload last practice dates
      _lastPracticeDates = await _db.getAllLastSessionDates();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to log practice: $e';
      notifyListeners();
    }
  }

  Piece? getPieceById(int id) {
    try {
      return _pieces.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
