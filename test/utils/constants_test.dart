import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/utils/constants.dart';

void main() {
  // ── nextStage ─────────────────────────────────────────────────────────────

  group('nextStage', () {
    test('learning → note_perfection', () {
      expect(nextStage(kStagelearning), kStageNotePerfection);
    });

    test('note_perfection → dynamics_perfection', () {
      expect(nextStage(kStageNotePerfection), kStageDynamicsPerfection);
    });

    test('dynamics_perfection → tempo_perfection', () {
      expect(nextStage(kStageDynamicsPerfection), kStageTempoPerfection);
    });

    test('tempo_perfection → repertoire', () {
      expect(nextStage(kStageTempoPerfection), kStageRepertoire);
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

    test('returns false for learning', () {
      expect(isLastStage(kStagelearning), isFalse);
    });

    test('returns false for note_perfection', () {
      expect(isLastStage(kStageNotePerfection), isFalse);
    });

    test('returns false for dynamics_perfection', () {
      expect(isLastStage(kStageDynamicsPerfection), isFalse);
    });

    test('returns false for tempo_perfection', () {
      expect(isLastStage(kStageTempoPerfection), isFalse);
    });

    test('returns false for an invalid stage', () {
      expect(isLastStage('garbage'), isFalse);
    });
  });

  // ── stageIndex ────────────────────────────────────────────────────────────

  group('stageIndex', () {
    test('learning is index 0', () {
      expect(stageIndex(kStagelearning), 0);
    });

    test('note_perfection is index 1', () {
      expect(stageIndex(kStageNotePerfection), 1);
    });

    test('dynamics_perfection is index 2', () {
      expect(stageIndex(kStageDynamicsPerfection), 2);
    });

    test('tempo_perfection is index 3', () {
      expect(stageIndex(kStageTempoPerfection), 3);
    });

    test('repertoire is index 4', () {
      expect(stageIndex(kStageRepertoire), 4);
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
    test('contains exactly 5 stages', () {
      expect(kStageOrder.length, 5);
    });

    test('stages are in ascending progression order', () {
      expect(kStageOrder.first, kStagelearning);
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
