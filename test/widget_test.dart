import 'package:flutter_test/flutter_test.dart';
import 'package:repertoire/main.dart';
import 'package:repertoire/providers/theme_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final themeNotifier = ThemeNotifier();
    await tester.pumpWidget(RepertoireApp(themeNotifier: themeNotifier));
    expect(find.text('Repertoire'), findsOneWidget);
  });
}
