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
  String status = kStageLearning,
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
  DateTime? lastPracticed,
}) =>
    MaterialApp(
      home: Scaffold(
        body: PieceCard(
          piece: piece,
          onTap: onTap,
          lastPracticed: lastPracticed,
        ),
      ),
    );

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('PieceCard name and composer display', () {
    testWidgets('always shows piece name', (tester) async {
      await tester.pumpWidget(_build(piece: _piece(name: 'La Campanella'), onTap: () {}));
      expect(find.text('La Campanella'), findsOneWidget);
    });

    testWidgets('shows composer when present and non-empty', (tester) async {
      await tester.pumpWidget(_build(piece: _piece(composer: 'Liszt'), onTap: () {}));
      expect(find.text('Liszt'), findsOneWidget);
    });

    testWidgets('hides composer when null', (tester) async {
      await tester.pumpWidget(_build(piece: _piece(composer: null), onTap: () {}));
      // The default in _piece is 'Beethoven'; passing null should suppress it
      expect(find.text('Beethoven'), findsNothing);
    });

    testWidgets('hides composer when empty string', (tester) async {
      await tester.pumpWidget(_build(piece: _piece(name: 'Solo', composer: ''), onTap: () {}));
      // Empty string matches the isNotEmpty guard — no composer row rendered
      final texts = tester.widgetList<Text>(find.byType(Text))
          .where((t) => t.data?.isEmpty == true)
          .toList();
      expect(texts, isEmpty);
    });
  });

  group('PieceCard last practiced row', () {
    testWidgets('shows "Never practiced" with amber icon when null', (tester) async {
      await tester.pumpWidget(
        _build(piece: _piece(), onTap: () {}, lastPracticed: null),
      );
      expect(find.textContaining('Never practiced'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows "Today" with check_circle icon', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _build(piece: _piece(), onTap: () {}, lastPracticed: now),
      );
      expect(find.textContaining('Today'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('shows "Yesterday" with history icon', (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await tester.pumpWidget(
        _build(piece: _piece(), onTap: () {}, lastPracticed: yesterday),
      );
      expect(find.textContaining('Yesterday'), findsOneWidget);
      expect(find.byIcon(Icons.history), findsOneWidget);
    });

    testWidgets('shows amber schedule icon for dates 3+ days ago', (tester) async {
      final older = DateTime(2023, 3, 15, 10, 30);
      await tester.pumpWidget(
        _build(piece: _piece(), onTap: () {}, lastPracticed: older),
      );
      expect(find.textContaining('Mar'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('shows history icon for dates 1-2 days ago', (tester) async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
      await tester.pumpWidget(
        _build(piece: _piece(), onTap: () {}, lastPracticed: twoDaysAgo),
      );
      expect(find.byIcon(Icons.history), findsOneWidget);
    });
  });

  group('PieceCard stage badge', () {
    testWidgets('shows correct label for learning stage', (tester) async {
      await tester.pumpWidget(
        _build(piece: _piece(status: kStageLearning), onTap: () {}),
      );
      expect(find.text('Learning'), findsOneWidget);
    });

    testWidgets('shows star icon for repertoire stage', (tester) async {
      await tester.pumpWidget(
        _build(piece: _piece(status: kStageRepertoire), onTap: () {}),
      );
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.text('Repertoire'), findsOneWidget);
    });

    testWidgets('does not show star icon for non-repertoire stage', (tester) async {
      await tester.pumpWidget(_build(piece: _piece(status: kStageLearning), onTap: () {}));
      expect(find.byIcon(Icons.star), findsNothing);
    });
  });

  group('PieceCard tap routing', () {
    testWidgets('tapping piece title calls onTap', (tester) async {
      var tapCalled = false;

      await tester.pumpWidget(_build(
        piece: _piece(),
        onTap: () => tapCalled = true,
      ));

      await tester.tap(find.text('Moonlight Sonata'));
      await tester.pump();

      expect(tapCalled, isTrue);
    });

    testWidgets('tapping composer line calls onTap', (tester) async {
      var tapCalled = false;

      await tester.pumpWidget(_build(
        piece: _piece(composer: 'Beethoven'),
        onTap: () => tapCalled = true,
      ));

      await tester.tap(find.text('Beethoven'));
      await tester.pump();

      expect(tapCalled, isTrue);
    });
  });
}
