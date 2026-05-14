import 'package:flutter_test/flutter_test.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('app boots to home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MatterDartDemoApp());
    expect(find.text('matter-dart'), findsOneWidget);
  });
}
