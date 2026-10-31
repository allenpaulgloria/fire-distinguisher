import 'package:fire_distinguisher/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Fire Distinguisher renders DISTINGUISH button',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FireDistinguisherApp(),
      ),
    );

    expect(find.text('DISTINGUISH'), findsOneWidget);
    expect(find.text('FIRE DISTINGUISHER // MK-IV'), findsOneWidget);
  });
}
