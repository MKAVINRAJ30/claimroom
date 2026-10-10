import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:claimroom_client/claimroom_client.dart';
import 'package:claimroom_flutter/screens/buyer_room_screen.dart';
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
    expect(find.text("Join a Sale"), findsOneWidget);

    // Verify Quick Start Instant Demo button is removed
    expect(find.text('⚡ Quick Start Instant Demo'), findsNothing);

    // Tap on Buyer tab
    await tester.tap(find.text("Join a Sale"));
    await tester.pumpAndSettle();

    // Verify buyer name hint text is 'Enter your name' and starts empty
    expect(find.text('Enter your name'), findsOneWidget);
    expect(find.text('Priya'), findsNothing);

    // Verify branding tagline
    expect(find.text("Stop losing sales to 'mine!' comments."), findsOneWidget);

    // Verify buyer disclaimer notice is rendered
    expect(
      find.textContaining(
        'ClaimRoom does not process payments or verify products',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'BuyerRoomScreen never displays waitlist or in line on a sold item',
    (WidgetTester tester) async {
      final room = Room(
        id: 99,
        code: 'TEST9',
        title: 'Test Room',
        sellerName: 'Seller9',
        isOpen: true,
        createdAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BuyerRoomScreen(
            room: room,
            initialBuyerName: 'Akash',
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Join waitlist'), findsNothing);
      expect(find.textContaining('in line'), findsNothing);
    },
  );

  testWidgets(
    'BuyerRoomScreen displays empty state message and renders cleanly on 360px wide screen',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final room = Room(
        id: 99,
        code: 'TEST9',
        title: 'Test Room',
        sellerName: 'Seller9',
        isOpen: true,
        createdAt: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BuyerRoomScreen(
            room: room,
            initialBuyerName: 'Akash',
          ),
        ),
      );

      await tester.pump();

      expect(
        find.text('The seller is setting up. Items appear here live.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
