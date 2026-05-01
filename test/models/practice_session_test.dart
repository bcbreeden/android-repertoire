import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/models/practice_session.dart';

void main() {
  // ── toMap ─────────────────────────────────────────────────────────────────

  group('PracticeSession.toMap', () {
    test('omits id when id is null', () {
      final s = PracticeSession(
        pieceId: 1,
        timestamp: DateTime(2024, 3, 1),
      );
      expect(s.toMap().containsKey('id'), isFalse);
    });

    test('includes id when id is set', () {
      final s = PracticeSession(
        id: 99,
        pieceId: 1,
        timestamp: DateTime(2024, 3, 1),
      );
      expect(s.toMap()['id'], 99);
    });

    test('serialises timestamp to ISO-8601 string', () {
      final ts = DateTime(2024, 6, 20, 9, 15, 30);
      final s = PracticeSession(pieceId: 2, timestamp: ts);
      expect(s.toMap()['timestamp'], ts.toIso8601String());
    });

    test('includes piece_id', () {
      final s = PracticeSession(pieceId: 42, timestamp: DateTime(2024, 1, 1));
      expect(s.toMap()['piece_id'], 42);
    });

    test('null optional fields are null in map', () {
      final s = PracticeSession(pieceId: 1, timestamp: DateTime(2024, 1, 1));
      final map = s.toMap();
      expect(map['measures_learned'], isNull);
      expect(map['current_bpm'], isNull);
      expect(map['notes'], isNull);
      expect(map['duration_seconds'], isNull);
    });

    test('populated optional fields are included in map', () {
      final s = PracticeSession(
        pieceId: 1,
        timestamp: DateTime(2024, 1, 1),
        measuresLearned: 12,
        currentBpm: 88,
        notes: 'Great session',
        durationSeconds: 1800,
      );
      final map = s.toMap();
      expect(map['measures_learned'], 12);
      expect(map['current_bpm'], 88);
      expect(map['notes'], 'Great session');
      expect(map['duration_seconds'], 1800);
    });
  });

  // ── fromMap ───────────────────────────────────────────────────────────────

  group('PracticeSession.fromMap', () {
    final baseTs = DateTime(2024, 5, 10, 14, 0);

    Map<String, dynamic> _baseMap() => {
          'id': 7,
          'piece_id': 3,
          'timestamp': baseTs.toIso8601String(),
          'measures_learned': null,
          'current_bpm': null,
          'notes': null,
          'duration_seconds': null,
        };

    test('deserialises id, pieceId, and timestamp', () {
      final s = PracticeSession.fromMap(_baseMap());
      expect(s.id, 7);
      expect(s.pieceId, 3);
      expect(s.timestamp, baseTs);
    });

    test('null optional fields remain null', () {
      final s = PracticeSession.fromMap(_baseMap());
      expect(s.measuresLearned, isNull);
      expect(s.currentBpm, isNull);
      expect(s.notes, isNull);
      expect(s.durationSeconds, isNull);
    });

    test('deserialises all optional fields when present', () {
      final map = _baseMap()
        ..['measures_learned'] = 20
        ..['current_bpm'] = 96
        ..['notes'] = 'Smooth run-through'
        ..['duration_seconds'] = 2700;
      final s = PracticeSession.fromMap(map);
      expect(s.measuresLearned, 20);
      expect(s.currentBpm, 96);
      expect(s.notes, 'Smooth run-through');
      expect(s.durationSeconds, 2700);
    });

    test('round-trip preserves all data', () {
      final original = PracticeSession(
        id: 5,
        pieceId: 10,
        timestamp: DateTime(2024, 8, 1, 18, 30),
        measuresLearned: 8,
        currentBpm: 72,
        notes: 'Slow practice',
        durationSeconds: 600,
      );
      final result = PracticeSession.fromMap(original.toMap());
      expect(result.id, original.id);
      expect(result.pieceId, original.pieceId);
      expect(result.timestamp, original.timestamp);
      expect(result.measuresLearned, original.measuresLearned);
      expect(result.currentBpm, original.currentBpm);
      expect(result.notes, original.notes);
      expect(result.durationSeconds, original.durationSeconds);
    });
  });
}
