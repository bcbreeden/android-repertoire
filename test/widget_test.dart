import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const RepertoireApp());
    expect(find.text('Repertoire'), findsOneWidget);
  });
}
