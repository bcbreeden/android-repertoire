import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/exercise.dart';
import '../models/exercise_session.dart';
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
      version: 5,
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
        notes TEXT,
        duration_seconds INTEGER
      )
    ''');
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        source TEXT,
        notes TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE exercise_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exercise_id INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        bpm INTEGER,
        notes TEXT,
        duration_seconds INTEGER
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
          notes TEXT,
          duration_seconds INTEGER
        )
      ''');
    }
    if (oldVersion < 4) {
      final cols = await db.rawQuery('PRAGMA table_info(practice_sessions)');
      final hasCol = cols.any((c) => c['name'] == 'duration_seconds');
      if (!hasCol) {
        await db.execute(
          'ALTER TABLE practice_sessions ADD COLUMN duration_seconds INTEGER',
        );
      }
    }
    if (oldVersion < 5) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercises (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          source TEXT,
          notes TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercise_sessions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          exercise_id INTEGER NOT NULL,
          timestamp TEXT NOT NULL,
          bpm INTEGER,
          notes TEXT,
          duration_seconds INTEGER
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

  Future<void> seedTestData() async {
    final db = await database;

    // Clear existing data first
    await db.delete('practice_sessions');
    await db.delete('pieces');

    final now = DateTime.now();

    // 40 pieces spread across composers, stages, and tempos
    final pieces = <Map<String, dynamic>>[
      // ── Learning (12 pieces) ──────────────────────────────────────────────
      _seed(now, 'Moonlight Sonata', 'Beethoven', kStagelearning, 200, ml: 24, ct: 48, tt: 96, daysAgo: 2),
      _seed(now, 'Für Elise', 'Beethoven', kStagelearning, 105, ml: 12, ct: 60, tt: 120, daysAgo: 5),
      _seed(now, 'Clair de Lune', 'Debussy', kStagelearning, 144, ml: 30, ct: 54, tt: 108, daysAgo: 1),
      _seed(now, 'Gymnopédie No. 1', 'Satie', kStagelearning, 88, ml: 8, ct: 50, tt: 76, daysAgo: 7),
      _seed(now, 'Prelude in C Major', 'Bach', kStagelearning, 35, ml: 10, ct: 72, tt: 120, daysAgo: 3),
      _seed(now, 'Nocturne Op. 9 No. 2', 'Chopin', kStagelearning, 132, ml: 20, ct: 60, tt: 132, daysAgo: 10),
      _seed(now, 'Arabesque No. 1', 'Debussy', kStagelearning, 68, ml: 15, ct: 80, tt: 144, daysAgo: 4),
      _seed(now, 'Turkish March', 'Mozart', kStagelearning, 96, ml: 32, ct: 100, tt: 160, daysAgo: 6),
      _seed(now, 'Maple Leaf Rag', 'Joplin', kStagelearning, 96, ml: 16, ct: 76, tt: 100, daysAgo: 8),
      _seed(now, 'Rondo Alla Turca', 'Mozart', kStagelearning, 160, ml: 40, ct: 88, tt: 168, daysAgo: 9),
      _seed(now, 'Canon in D', 'Pachelbel', kStagelearning, 56, ml: 14, ct: 66, tt: 88, daysAgo: 11),
      _seed(now, 'River Flows in You', 'Yiruma', kStagelearning, 76, ml: 20, ct: 72, tt: 96, daysAgo: 14),

      // ── Note Perfection (9 pieces) ────────────────────────────────────────
      _seed(now, 'Ballade No. 1', 'Chopin', kStageNotePerfection, 264, ml: 264, ct: 92, tt: 152, daysAgo: 20),
      _seed(now, 'Fantasie Impromptu', 'Chopin', kStageNotePerfection, 188, ml: 188, ct: 108, tt: 176, daysAgo: 15),
      _seed(now, 'Sonata K. 331', 'Mozart', kStageNotePerfection, 180, ml: 180, ct: 84, tt: 132, daysAgo: 18),
      _seed(now, 'Invention No. 1', 'Bach', kStageNotePerfection, 44, ml: 44, ct: 96, tt: 120, daysAgo: 22),
      _seed(now, 'Waltz Op. 64 No. 2', 'Chopin', kStageNotePerfection, 80, ml: 80, ct: 132, tt: 176, daysAgo: 25),
      _seed(now, 'Sonatina in G', 'Beethoven', kStageNotePerfection, 68, ml: 68, ct: 100, tt: 140, daysAgo: 12),
      _seed(now, 'Liebestraum No. 3', 'Liszt', kStageNotePerfection, 90, ml: 90, ct: 60, tt: 84, daysAgo: 30),
      _seed(now, 'Spring (Four Seasons)', 'Vivaldi', kStageNotePerfection, 120, ml: 120, ct: 88, tt: 132, daysAgo: 16),
      _seed(now, 'Prelude Op. 28 No. 4', 'Chopin', kStageNotePerfection, 48, ml: 48, ct: 48, tt: 60, daysAgo: 19),

      // ── Dynamics Perfection (8 pieces) ───────────────────────────────────
      _seed(now, 'Waldstein Sonata', 'Beethoven', kStageDynamicsPerfection, 302, ml: 302, ct: 120, tt: 168, daysAgo: 40),
      _seed(now, 'Etude Op. 10 No. 1', 'Chopin', kStageDynamicsPerfection, 79, ml: 79, ct: 116, tt: 176, daysAgo: 35),
      _seed(now, 'Gnossienne No. 1', 'Satie', kStageDynamicsPerfection, 88, ml: 88, ct: 50, tt: 60, daysAgo: 45),
      _seed(now, 'Prelude in E Minor', 'Chopin', kStageDynamicsPerfection, 25, ml: 25, ct: 48, tt: 60, daysAgo: 38),
      _seed(now, 'Invention No. 4', 'Bach', kStageDynamicsPerfection, 38, ml: 38, ct: 104, tt: 132, daysAgo: 42),
      _seed(now, 'Sonatine', 'Ravel', kStageDynamicsPerfection, 112, ml: 112, ct: 88, tt: 116, daysAgo: 50),
      _seed(now, 'Minuet in G', 'Bach', kStageDynamicsPerfection, 32, ml: 32, ct: 100, tt: 120, daysAgo: 33),
      _seed(now, 'Etude Op. 25 No. 11', 'Chopin', kStageDynamicsPerfection, 56, ml: 56, ct: 88, tt: 160, daysAgo: 37),

      // ── Tempo Perfection (6 pieces) ───────────────────────────────────────
      _seed(now, 'Pathetique Sonata', 'Beethoven', kStageTempoPerfection, 352, ml: 352, ct: 138, tt: 152, daysAgo: 60),
      _seed(now, 'Nocturne Op. 27 No. 2', 'Chopin', kStageTempoPerfection, 110, ml: 110, ct: 52, tt: 58, daysAgo: 55),
      _seed(now, 'Goldberg Variations', 'Bach', kStageTempoPerfection, 320, ml: 320, ct: 80, tt: 88, daysAgo: 70),
      _seed(now, 'La Campanella', 'Liszt', kStageTempoPerfection, 188, ml: 188, ct: 168, tt: 184, daysAgo: 65),
      _seed(now, 'Rhapsody in Blue', 'Gershwin', kStageTempoPerfection, 400, ml: 400, ct: 112, tt: 126, daysAgo: 58),
      _seed(now, 'Consolation No. 3', 'Liszt', kStageTempoPerfection, 68, ml: 68, ct: 50, tt: 56, daysAgo: 62),

      // ── Mastered (5 pieces) ───────────────────────────────────────────────
      _seed(now, 'Prelude in C# Minor', 'Rachmaninoff', kStageRepertoire, 60, ml: 60, ct: 64, tt: 64, daysAgo: 120),
      _seed(now, 'Waltz in A Minor', 'Chopin', kStageRepertoire, 64, ml: 64, ct: 138, tt: 138, daysAgo: 95),
      _seed(now, 'Gymnopédie No. 3', 'Satie', kStageRepertoire, 88, ml: 88, ct: 60, tt: 60, daysAgo: 80),
      _seed(now, 'Minuet in D Minor', 'Bach', kStageRepertoire, 24, ml: 24, ct: 108, tt: 108, daysAgo: 110),
      _seed(now, 'Comptine d\'un autre été', 'Tiersen', kStageRepertoire, 56, ml: 56, ct: 84, tt: 84, daysAgo: 90),
    ];

    // Capture actual inserted IDs
    final insertedIds = <int>[];
    for (final p in pieces) {
      final id = await db.insert('pieces', p);
      insertedIds.add(id);
    }

    // Seed practice sessions using the real IDs for the first 20 pieces
    for (var i = 0; i < 20 && i < insertedIds.length; i++) {
      final pieceId = insertedIds[i];
      final sessionCount = (i % 4) + 1; // 1–4 sessions per piece
      for (var j = 0; j < sessionCount; j++) {
        final hoursAgo = j * 48 + (i * 3);
        await db.insert('practice_sessions', {
          'piece_id': pieceId,
          'timestamp': now.subtract(Duration(hours: hoursAgo)).toIso8601String(),
          'measures_learned': 10 + j * 4,
          'current_bpm': 60 + j * 8,
          'notes': j == 0 ? 'First session, rough but promising' : j == 1 ? 'Getting smoother' : null,
          'duration_seconds': 900 + j * 300,
        });
      }
    }
  }

  Map<String, dynamic> _seed(
    DateTime now,
    String name,
    String composer,
    String status,
    int measures, {
    int? ml,
    int? ct,
    int? tt,
    required int daysAgo,
  }) {
    final created = now.subtract(Duration(days: daysAgo));
    final stageProgression = <String, String?>{
      'learning_at': created.toIso8601String(),
      'note_perfection_at': null,
      'dynamics_perfection_at': null,
      'tempo_perfection_at': null,
      'repertoire_at': null,
    };

    // Set timestamps for all stages up to and including the current one
    final stageIndex = kStageOrder.indexOf(status);
    if (stageIndex >= 1) {
      stageProgression['note_perfection_at'] =
          now.subtract(Duration(days: (daysAgo * 0.8).round())).toIso8601String();
    }
    if (stageIndex >= 2) {
      stageProgression['dynamics_perfection_at'] =
          now.subtract(Duration(days: (daysAgo * 0.6).round())).toIso8601String();
    }
    if (stageIndex >= 3) {
      stageProgression['tempo_perfection_at'] =
          now.subtract(Duration(days: (daysAgo * 0.4).round())).toIso8601String();
    }
    if (stageIndex >= 4) {
      stageProgression['repertoire_at'] =
          now.subtract(Duration(days: (daysAgo * 0.2).round())).toIso8601String();
    }

    return {
      'name': name,
      'composer': composer,
      'measures': measures,
      'measures_learned': ml,
      'current_tempo': ct,
      'target_tempo': tt,
      'notes': null,
      'status': status,
      'created_at': created.toIso8601String(),
      'updated_at': now.subtract(const Duration(days: 1)).toIso8601String(),
      ...stageProgression,
    };
  }

  // ── Exercise CRUD ───────────────────────────────────────────────────────────

  Future<int> insertExercise(Exercise exercise) async {
    final db = await database;
    final map = exercise.toMap();
    map.remove('id');
    return await db.insert('exercises', map);
  }

  Future<List<Exercise>> getAllExercises() async {
    final db = await database;
    final maps = await db.query('exercises', orderBy: 'updated_at DESC');
    return maps.map((m) => Exercise.fromMap(m)).toList();
  }

  Future<Exercise?> getExerciseById(int id) async {
    final db = await database;
    final maps = await db.query('exercises',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (maps.isEmpty) return null;
    return Exercise.fromMap(maps.first);
  }

  Future<int> updateExercise(Exercise exercise) async {
    final db = await database;
    return await db.update(
      'exercises',
      exercise.toMap(),
      where: 'id = ?',
      whereArgs: [exercise.id],
    );
  }

  Future<int> deleteExercise(int id) async {
    final db = await database;
    await db.delete('exercise_sessions',
        where: 'exercise_id = ?', whereArgs: [id]);
    return await db.delete('exercises', where: 'id = ?', whereArgs: [id]);
  }

  // ── Exercise session methods ──────────────────────────────────────────────

  Future<int> insertExerciseSession(ExerciseSession session) async {
    final db = await database;
    return await db.insert('exercise_sessions', session.toMap());
  }

  Future<List<ExerciseSession>> getAllExerciseSessions() async {
    final db = await database;
    final rows = await db.query('exercise_sessions', orderBy: 'timestamp DESC');
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  Future<List<ExerciseSession>> getExerciseSessionsForExercise(
      int exerciseId) async {
    final db = await database;
    final rows = await db.query(
      'exercise_sessions',
      where: 'exercise_id = ?',
      whereArgs: [exerciseId],
      orderBy: 'timestamp DESC',
    );
    return rows.map((r) => ExerciseSession.fromMap(r)).toList();
  }

  Future<Map<int, DateTime>> getAllLastExerciseSessionDates() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT exercise_id, MAX(timestamp) as last_ts '
      'FROM exercise_sessions GROUP BY exercise_id',
    );
    final map = <int, DateTime>{};
    for (final row in rows) {
      map[row['exercise_id'] as int] =
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

  /// Deletes all rows from every table. Used by integration tests to guarantee
  /// a clean state before each test group without re-opening the database.
  Future<void> resetForTesting() async {
    final db = await database;
    await db.delete('exercise_sessions');
    await db.delete('exercises');
    await db.delete('practice_sessions');
    await db.delete('pieces');
    await db.delete('app_opens');
  }
}
