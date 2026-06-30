import 'package:flutter_test/flutter_test.dart';

import 'package:finance_predictor/main.dart';

void main() {
  testWidgets('app renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(firebaseEnabled: false),
    );

    // The app should render home screen with bottom navigation
    expect(find.text('Records'), findsWidgets);
  });
}