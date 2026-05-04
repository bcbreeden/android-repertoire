import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/utils/constants.dart';

void main() {
  // ── nextStage ─────────────────────────────────────────────────────────────

  group('nextStage', () {
    test('backlog → learning', () {
      expect(nextStage(kStageBacklog), kStageLearning);
    });

    test('learning → repertoire', () {
      expect(nextStage(kStageLearning), kStageRepertoire);
    });

    test('repertoire → repertoire (already last, no change)', () {
      expect(nextStage(kStageRepertoire), kStageRepertoire);
    });

    test('invalid stage returns the same invalid string unchanged', () {
      expect(nextStage('not_a_stage'), 'not_a_stage');
    });

    test('empty string returns empty string', () {
      expect(nextStage(''), '');
    });
  });

  // ── isLastStage ───────────────────────────────────────────────────────────

  group('isLastStage', () {
    test('returns true for repertoire', () {
      expect(isLastStage(kStageRepertoire), isTrue);
    });

    test('returns false for backlog', () {
      expect(isLastStage(kStageBacklog), isFalse);
    });

    test('returns false for learning', () {
      expect(isLastStage(kStageLearning), isFalse);
    });

    test('returns false for an invalid stage', () {
      expect(isLastStage('garbage'), isFalse);
    });
  });

  // ── stageIndex ────────────────────────────────────────────────────────────

  group('stageIndex', () {
    test('backlog is index 0', () {
      expect(stageIndex(kStageBacklog), 0);
    });

    test('learning is index 1', () {
      expect(stageIndex(kStageLearning), 1);
    });

    test('repertoire is index 2', () {
      expect(stageIndex(kStageRepertoire), 2);
    });

    test('invalid stage returns -1', () {
      expect(stageIndex('not_a_real_stage'), -1);
    });

    test('empty string returns -1', () {
      expect(stageIndex(''), -1);
    });
  });

  // ── kStageOrder integrity ─────────────────────────────────────────────────

  group('kStageOrder', () {
    test('contains exactly 3 stages', () {
      expect(kStageOrder.length, 3);
    });

    test('stages are in ascending progression order', () {
      expect(kStageOrder.first, kStageBacklog);
      expect(kStageOrder.last, kStageRepertoire);
    });
  });

  // ── kStageLabels ──────────────────────────────────────────────────────────

  group('kStageLabels', () {
    test('every stage in kStageOrder has a label', () {
      for (final stage in kStageOrder) {
        expect(kStageLabels.containsKey(stage), isTrue,
            reason: 'Missing label for stage "$stage"');
      }
    });

    test('no label is empty', () {
      for (final label in kStageLabels.values) {
        expect(label.isNotEmpty, isTrue);
      }
    });
  });

  // ── kStageTimestampKeys ───────────────────────────────────────────────────

  group('kStageTimestampKeys', () {
    test('every stage in kStageOrder has a timestamp key', () {
      for (final stage in kStageOrder) {
        expect(kStageTimestampKeys.containsKey(stage), isTrue,
            reason: 'Missing timestamp key for stage "$stage"');
      }
    });
  });

  // ── kStageDescriptions ────────────────────────────────────────────────────

  group('kStageDescriptions', () {
    test('every stage in kStageOrder has a description', () {
      for (final stage in kStageOrder) {
        expect(kStageDescriptions.containsKey(stage), isTrue,
            reason: 'Missing description for stage "$stage"');
      }
    });

    test('no description is empty', () {
      for (final desc in kStageDescriptions.values) {
        expect(desc.isNotEmpty, isTrue);
      }
    });

    test('has exactly as many entries as stages', () {
      expect(kStageDescriptions.length, kStageOrder.length);
    });
  });

  // ── kStageColors ──────────────────────────────────────────────────────────

  group('kStageColors', () {
    test('every stage in kStageOrder has a color', () {
      for (final stage in kStageOrder) {
        expect(kStageColors.containsKey(stage), isTrue,
            reason: 'Missing color for stage "$stage"');
      }
    });

    test('has exactly as many entries as stages', () {
      expect(kStageColors.length, kStageOrder.length);
    });

    test('no two stages share the same color value', () {
      final values = kStageColors.values.map((c) => c.value).toList();
      final unique = values.toSet();
      expect(unique.length, values.length,
          reason: 'Stage colors should be visually distinct');
    });
  });
}
