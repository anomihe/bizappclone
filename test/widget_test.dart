import 'package:flutter_test/flutter_test.dart';
import 'package:bizpaddi/main.dart';

void main() {
  testWidgets('Bizpaddi App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const BizpaddiApp());
    // Advance timers so splash sequences complete
    await tester.pumpAndSettle(const Duration(seconds: 4));
    expect(find.byType(BizpaddiApp), findsOneWidget);
  });
}
