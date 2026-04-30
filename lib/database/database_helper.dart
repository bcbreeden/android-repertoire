import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/piece.dart';
import '../models/practice_session.dart';
import '../utils/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'repertoire.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _createDatabase,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pieces (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        composer TEXT,
        measures INTEGER NOT NULL,
        measures_learned INTEGER,
        current_tempo INTEGER,
        target_tempo INTEGER,
        notes TEXT,
        status TEXT NOT NULL DEFAULT '$kStagelearning',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        learning_at TEXT,
        note_perfection_at TEXT,
        dynamics_perfection_at TEXT,
        tempo_perfection_at TEXT,
        repertoire_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE app_opens (
        date TEXT PRIMARY KEY
      )
    ''');
    await db.execute('''
      CREATE TABLE practice_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        piece_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        measures_learned INTEGER,
        current_bpm INTEGER,
        notes TEXT
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_opens (
          date TEXT PRIMARY KEY
        )
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS practice_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          piece_id INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          measures_learned INTEGER,
          current_bpm INTEGER,
          notes TEXT
        )
      ''');
    }
  }

  Future<void> recordAppOpen() async {
    final db = await database;
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await db.insert(
      'app_opens',
      {'date': dateStr},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> getStreak() async {
    final db = await database;
    final rows = await db.query('app_opens', orderBy: 'date DESC');
    if (rows.isEmpty) return 0;

    final dates = rows.map((r) => DateTime.parse(r['date'] as String)).toList();
    final today = DateTime.now();
    final todayNorm = DateTime(today.year, today.month, today.day);

    int streak = 0;
    DateTime expected = todayNorm;

    for (final date in dates) {
      final d = DateTime(date.year, date.month, date.day);
      if (d == expected) {
        streak++;
        expected = expected.subtract(const Duration(days: 1));
      } else if (d.isBefore(expected)) {
        break;
      }
    }

    return streak;
  }

  // Create
  Future<int> insertPiece(Piece piece) async {
    final db = await database;
    final map = piece.toMap();
    map.remove('id');
    return await db.insert('pieces', map);
  }

  // Read all
  Future<List<Piece>> getAllPieces() async {
    final db = await database;
    final maps = await db.query('pieces', orderBy: 'updated_at DESC');
    return maps.map((m) => Piece.fromMap(m)).toList();
  }

  // Read by id
  Future<Piece?> getPieceById(int id) async {
    final db = await database;
    final maps =
        await db.query('pieces', where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Piece.fromMap(maps.first);
  }

  // Read by status
  Future<List<Piece>> getPiecesByStatus(String status) async {
    final db = await database;
    final maps = await db.query(
      'pieces',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'updated_at DESC',
    );
    return maps.map((m) => Piece.fromMap(m)).toList();
  }

  // Update
  Future<int> updatePiece(Piece piece) async {
    final db = await database;
    return await db.update(
      'pieces',
      piece.toMap(),
      where: 'id = ?',
      whereArgs: [piece.id],
    );
  }

  // Delete
  Future<int> deletePiece(int id) async {
    final db = await database;
    return await db.delete('pieces', where: 'id = ?', whereArgs: [id]);
  }

  // Advance piece to next stage, setting timestamp only if not already set
  Future<Piece?> advancePieceStage(Piece piece) async {
    if (isLastStage(piece.status)) return piece;

    final newStatus = nextStage(piece.status);
    final now = DateTime.now();

    Piece updated = piece.copyWith(
      status: newStatus,
      updatedAt: now,
    );

    // Set the timestamp for the new stage only if not already set
    switch (newStatus) {
      case kStageNotePerfection:
        if (piece.notePerfectionAt == null) {
          updated = updated.copyWith(notePerfectionAt: now);
        }
        break;
      case kStageDynamicsPerfection:
        if (piece.dynamicsPerfectionAt == null) {
          updated = updated.copyWith(dynamicsPerfectionAt: now);
        }
        break;
      case kStageTempoPerfection:
        if (piece.tempoPerfectionAt == null) {
          updated = updated.copyWith(tempoPerfectionAt: now);
        }
        break;
      case kStageRepertoire:
        if (piece.repertoireAt == null) {
          updated = updated.copyWith(repertoireAt: now);
        }
        break;
    }

    await updatePiece(updated);
    return updated;
  }

  // Set stage manually, preserving existing timestamps and only setting new ones
  Future<Piece?> setPieceStage(Piece piece, String newStatus) async {
    if (piece.status == newStatus) return piece;

    final now = DateTime.now();

    Piece updated = piece.copyWith(
      status: newStatus,
      updatedAt: now,
    );

    // Set timestamp for the target stage if not already set
    switch (newStatus) {
      case kStagelearning:
        if (piece.learningAt == null) {
          updated = updated.copyWith(learningAt: now);
        }
        break;
      case kStageNotePerfection:
        if (piece.notePerfectionAt == null) {
          updated = updated.copyWith(notePerfectionAt: now);
        }
        break;
      case kStageDynamicsPerfection:
        if (piece.dynamicsPerfectionAt == null) {
          updated = updated.copyWith(dynamicsPerfectionAt: now);
        }
        break;
      case kStageTempoPerfection:
        if (piece.tempoPerfectionAt == null) {
          updated = updated.copyWith(tempoPerfectionAt: now);
        }
        break;
      case kStageRepertoire:
        if (piece.repertoireAt == null) {
          updated = updated.copyWith(repertoireAt: now);
        }
        break;
    }

    await updatePiece(updated);
    return updated;
  }

  // Stats helpers
  Future<Map<String, int>> getStageCountMap() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT status, COUNT(*) as count FROM pieces GROUP BY status',
    );
    final map = <String, int>{};
    for (final row in result) {
      map[row['status'] as String] = row['count'] as int;
    }
    return map;
  }

  // Recent milestones: last 5 stage achievements across all pieces
  Future<List<Map<String, dynamic>>> getRecentMilestones({int limit = 5}) async {
    // We gather all stage timestamps and return the most recent ones
    final pieces = await getAllPieces();
    final milestones = <Map<String, dynamic>>[];

    for (final piece in pieces) {
      for (final stage in kStageOrder) {
        final ts = piece.timestampForStage(stage);
        if (ts != null) {
          milestones.add({
            'piece': piece,
            'stage': stage,
            'timestamp': ts,
          });
        }
      }
    }

    milestones.sort((a, b) =>
        (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

    return milestones.take(limit).toList();
  }

  // Practice session methods
  Future<List<PracticeSession>> getAllPracticeSessions() async {
    final db = await database;
    final rows = await db.query('practice_sessions', orderBy: 'timestamp DESC');
    return rows.map((r) => PracticeSession.fromMap(r)).toList();
  }

  Future<int> insertPracticeSession(PracticeSession session) async {
    final db = await database;
    return await db.insert('practice_sessions', session.toMap());
  }

  Future<DateTime?> getLastSessionDateForPiece(int pieceId) async {
    final db = await database;
    final rows = await db.query(
      'practice_sessions',
      where: 'piece_id = ?',
      whereArgs: [pieceId],
      orderBy: 'timestamp DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DateTime.parse(rows.first['timestamp'] as String);
  }

  Future<Map<int, DateTime>> getAllLastSessionDates() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT piece_id, MAX(timestamp) as last_ts FROM practice_sessions GROUP BY piece_id',
    );
    final map = <int, DateTime>{};
    for (final row in rows) {
      map[row['piece_id'] as int] =
          DateTime.parse(row['last_ts'] as String);
    }
    return map;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
