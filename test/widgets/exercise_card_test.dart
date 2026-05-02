import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/models/exercise.dart';
import 'package:repertoire/utils/constants.dart';
import 'package:repertoire/widgets/exercise_card.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Exercise _exercise({
  String name = 'Scales',
  String? source = 'Hanon',
}) {
  final now = DateTime(2024, 1, 1, 12, 0);
  return Exercise(
      id: 1, name: name, source: source, createdAt: now, updatedAt: now);
}

Widget _buildCard(
  Exercise exercise, {
  VoidCallback? onTap,
  VoidCallback? onPlay,
  DateTime? lastPracticed,
}) =>
    MaterialApp(
      home: Scaffold(
        body: ExerciseCard(
          exercise: exercise,
          onTap: onTap ?? () {},
          onPlay: onPlay ?? () {},
          lastPracticed: lastPracticed,
        ),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('ExerciseCard name and source display', () {
    testWidgets('always shows exercise name', (tester) async {
      await tester.pumpWidget(_buildCard(_exercise(name: 'Arpeggios')));
      expect(find.text('Arpeggios'), findsOneWidget);
    });

    testWidgets('shows source when present and non-empty', (tester) async {
      await tester.pumpWidget(
          _buildCard(_exercise(name: 'Scales', source: 'Czerny')));
      expect(find.text('Czerny'), findsOneWidget);
    });

    testWidgets('hides source when null', (tester) async {
      await tester.pumpWidget(
          _buildCard(_exercise(name: 'Scales', source: null)));
      expect(find.text('Hanon'), findsNothing);
    });

    testWidgets('hides source when empty string', (tester) async {
      await tester.pumpWidget(
          _buildCard(_exercise(name: 'Scales', source: '')));
      expect(find.byType(Text),
          findsWidgets); // at least the name is shown
      // The empty source should not render a Text widget
      expect(find.text(''), findsNothing);
    });
  });

  group('ExerciseCard Play button', () {
    testWidgets('Play button is always visible', (tester) async {
      await tester.pumpWidget(_buildCard(_exercise()));
      expect(find.text('Play'), findsOneWidget);
    });

    testWidgets('Play button uses gold color indicator', (tester) async {
      await tester.pumpWidget(_buildCard(_exercise()));
      final icon = tester.widget<Icon>(
        find.descendant(
          of: find.byWidgetPredicate(
              (w) => w is GestureDetector && (w.child is Container)),
          matching: find.byType(Icon),
        ).first,
      );
      expect(icon.color, kGoldColor);
    });
  });

  group('ExerciseCard last practiced row', () {
    testWidgets('hidden when lastPracticed is null', (tester) async {
      await tester.pumpWidget(_buildCard(_exercise(), lastPracticed: null));
      expect(find.byIcon(Icons.check_circle), findsNothing);
      expect(find.byIcon(Icons.history), findsNothing);
    });

    testWidgets('shows "Today" with check_circle when practiced today',
        (tester) async {
      await tester.pumpWidget(
          _buildCard(_exercise(), lastPracticed: DateTime.now()));
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.textContaining('Today'), findsOneWidget);
    });
  });

  group('ExerciseCard tap routing', () {
    testWidgets('tapping Play calls onPlay, not onTap', (tester) async {
      var tapCount = 0;
      var playCount = 0;
      await tester.pumpWidget(_buildCard(
        _exercise(),
        onTap: () => tapCount++,
        onPlay: () => playCount++,
      ));
      await tester.tap(find.text('Play'));
      await tester.pump();
      expect(playCount, 1);
      expect(tapCount, 0);
    });

    testWidgets('tapping exercise name calls onTap, not onPlay', (tester) async {
      var tapCount = 0;
      var playCount = 0;
      await tester.pumpWidget(_buildCard(
        _exercise(name: 'TapTarget'),
        onTap: () => tapCount++,
        onPlay: () => playCount++,
      ));
      await tester.tap(find.text('TapTarget'));
      await tester.pump();
      expect(tapCount, 1);
      expect(playCount, 0);
    });
  });
}
