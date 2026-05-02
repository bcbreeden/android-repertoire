import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/models/piece.dart';
import 'package:repertoire/utils/constants.dart';
import 'package:repertoire/widgets/piece_card.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Piece _piece({
  String name = 'Moonlight Sonata',
  String? composer = 'Beethoven',
  int? measuresLearned = 80,
  int? currentTempo = 72,
  String status = kStagelearning,
}) {
  final now = DateTime(2024, 6, 1, 12, 0);
  return Piece(
    id: 1,
    name: name,
    composer: composer,
    measures: 200,
    measuresLearned: measuresLearned,
    currentTempo: currentTempo,
    status: status,
    createdAt: now,
    updatedAt: now,
  );
}

Widget _build({
  required Piece piece,
  required VoidCallback onTap,
  VoidCallback? onPractice,
  DateTime? lastPracticed,
}) =>
    MaterialApp(
      home: Scaffold(
        body: PieceCard(
          piece: piece,
          onTap: onTap,
          onPractice: onPractice,
          lastPracticed: lastPracticed,
        ),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('PieceCard practice button visibility', () {
    testWidgets('button is hidden when onPractice is null', (tester) async {
      await tester.pumpWidget(_build(piece: _piece(), onTap: () {}));

      expect(find.text('Practice'), findsNothing);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('button is shown when onPractice is provided', (tester) async {
      await tester.pumpWidget(
        _build(piece: _piece(), onTap: () {}, onPractice: () {}),
      );

      expect(find.text('Practice'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('button is shown for repertoire pieces', (tester) async {
      await tester.pumpWidget(
        _build(
          piece: _piece(status: kStageRepertoire),
          onTap: () {},
          onPractice: () {},
        ),
      );

      expect(find.text('Practice'), findsOneWidget);
    });
  });

  group('PieceCard practice button tap routing', () {
    testWidgets('tapping Practice calls onPractice, not onTap', (tester) async {
      var tapCalled = false;
      var practiceCalled = false;

      await tester.pumpWidget(_build(
        piece: _piece(),
        onTap: () => tapCalled = true,
        onPractice: () => practiceCalled = true,
      ));

      await tester.tap(find.text('Practice'));
      await tester.pump();

      expect(practiceCalled, isTrue);
      expect(tapCalled, isFalse);
    });

    testWidgets('tapping piece title calls onTap, not onPractice', (tester) async {
      var tapCalled = false;
      var practiceCalled = false;

      await tester.pumpWidget(_build(
        piece: _piece(),
        onTap: () => tapCalled = true,
        onPractice: () => practiceCalled = true,
      ));

      await tester.tap(find.text('Moonlight Sonata'));
      await tester.pump();

      expect(tapCalled, isTrue);
      expect(practiceCalled, isFalse);
    });

    testWidgets('tapping composer line calls onTap, not onPractice', (tester) async {
      var tapCalled = false;
      var practiceCalled = false;

      await tester.pumpWidget(_build(
        piece: _piece(composer: 'Beethoven'),
        onTap: () => tapCalled = true,
        onPractice: () => practiceCalled = true,
      ));

      await tester.tap(find.text('Beethoven'));
      await tester.pump();

      expect(tapCalled, isTrue);
      expect(practiceCalled, isFalse);
    });
  });
}
