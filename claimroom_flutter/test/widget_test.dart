import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimroom_flutter/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders Create and Join tabs and buyer disclaimer', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify tabs are present
    expect(find.text("I'm a Seller"), findsOneWidget);
    expect(find.text("I'm a Buyer"), findsOneWidget);

    // Verify Quick Start Instant Demo button is removed
    expect(find.text('⚡ Quick Start Instant Demo'), findsNothing);

    // Tap on Buyer tab
    await tester.tap(find.text("I'm a Buyer"));
    await tester.pumpAndSettle();

    // Verify buyer name hint text is 'Enter your name' and starts empty
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Priya'), findsNothing);

    // Verify buyer disclaimer notice is rendered
    expect(
      find.textContaining(
        'ClaimRoom does not process payments or verify products',
      ),
      findsOneWidget,
    );
  });
}
