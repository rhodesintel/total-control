import 'package:flutter_test/flutter_test.dart';
import 'package:total_control/main.dart';

void main() {
  testWidgets('App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const TotalControlApp());
    expect(find.text('TOTAL CONTROL'), findsOneWidget);
  });
}
