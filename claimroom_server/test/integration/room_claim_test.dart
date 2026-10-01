import 'package:test/test.dart';
import 'package:claimroom_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given ClaimRoom endpoints',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      test(
        'full seller and buyer claim flow with sellerKey, atomic double-claim prevention, mark paid, and end sale',
        () async {
          // 1. Seller creates a room
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Vintage Drop #1',
            'Ananya',
          );
          expect(room.id, isNotNull);
          expect(room.code.length, 5);
          expect(room.isOpen, isTrue);
          expect(room.sellerKey, isNotNull);
          expect(room.sellerKey!.length, 16);
          final sellerKey = room.sellerKey!;

          // 2. Buyer joins by code - verify sellerKey is stripped!
          final foundRoom = await endpoints.room.getRoomByCode(
            sessionBuilder,
            room.code,
          );
          expect(foundRoom, isNotNull);
          expect(foundRoom!.id, room.id);
          expect(foundRoom.sellerKey, isNull);

          // 3. Seller adds items with sellerKey
          final item1 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Vintage Denim Jacket',
            1499.0,
            1,
          );
          final item2 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Silk Floral Scarf',
            499.0,
            3,
          );
          expect(item1.status, 'available');
          expect(item2.status, 'available');
          expect(item1.paid, isFalse);
          expect(item2.paid, isFalse);

          final items = await endpoints.room.listItems(
            sessionBuilder,
            room.id!,
          );
          expect(items.length, 2);

          // 4. Atomic claim test: Two buyers try to claim item1 at the same instant
          final futureClaim1 = endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            'Priya',
            '+919876543210',
          );
          final futureClaim2 = endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            'Rahul',
            '+919876543211',
          );

          final results = await Future.wait([futureClaim1, futureClaim2]);
          final successCount = results.where((r) => r.success).length;
          final failCount = results.where((r) => !r.success).length;

          // Exactly ONE claim must succeed, never both!
          expect(successCount, equals(1));
          expect(failCount, equals(1));

          // The winning claim holds the item for 60s
          final winningClaim = results.firstWhere((r) => r.success);
          expect(winningClaim.item!.status, 'held');
          final winningBuyer = winningClaim.item!.heldBy;
          expect(winningBuyer, isIn(['Priya', 'Rahul']));

          // 5. Confirm claim: The winning buyer confirms within hold window
          final confirmResult = await endpoints.room.confirmClaim(
            sessionBuilder,
            item1.id!,
            winningBuyer!,
          );
          expect(confirmResult.success, isTrue);
          expect(confirmResult.item!.status, 'sold');
          expect(confirmResult.item!.soldTo, winningBuyer);

          // 6. Test claim & release on item2
          final claim2 = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            'Sneha',
            '+919876543212',
          );
          expect(claim2.success, isTrue);
          expect(claim2.item!.status, 'held');

          // Sneha decides to release the hold
          final releaseResult = await endpoints.room.releaseClaim(
            sessionBuilder,
            item2.id!,
            'Sneha',
          );
          expect(releaseResult.success, isTrue);
          expect(releaseResult.item!.status, 'available');

          // Now someone else can claim item2
          final claim2Again = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            winningBuyer,
            '+919876543210',
          );
          expect(claim2Again.success, isTrue);

          await endpoints.room.confirmClaim(
            sessionBuilder,
            item2.id!,
            winningBuyer,
          );

          // 7. Mark item1 as paid
          final markedItem = await endpoints.room.markPaid(
            sessionBuilder,
            item1.id!,
            sellerKey,
            true,
          );
          expect(markedItem.paid, isTrue);

          // 8. Verify Order Sheet for Seller (with quantity math and paid totals)
          final orderSheet = await endpoints.room.getOrderSheet(
            sessionBuilder,
            room.id!,
            sellerKey,
          );
          expect(orderSheet.roomId, room.id);
          expect(orderSheet.totalItemsSold, 4); // 1 item1 + 3 item2
          expect(orderSheet.grandTotal, 1499.0 + (499.0 * 3)); // 2996.0
          expect(orderSheet.totalPaid, 1499.0);
          expect(orderSheet.totalUnpaid, 499.0 * 3); // 1497.0
          expect(orderSheet.buyers.length, 1);
          expect(orderSheet.buyers.first.buyerName, winningBuyer);
          expect(orderSheet.buyers.first.items.length, 2);
          expect(orderSheet.buyers.first.itemCount, 4);
          expect(orderSheet.buyers.first.totalAmount, 2996.0);

          // 9. End sale
          final endedRoom = await endpoints.room.endSale(
            sessionBuilder,
            room.id!,
            sellerKey,
          );
          expect(endedRoom.isOpen, isFalse);
        },
      );

      test(
        '20 parallel claims on one item (exactly 1 succeeds)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Flash Sale Room',
            'Sanjay',
          );
          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            room.sellerKey!,
            'Limited Edition Sneakers',
            4999.0,
            1,
          );

          // 20 simultaneous claim requests
          final claimFutures = List.generate(
            20,
            (i) => endpoints.room.claimItem(
              sessionBuilder,
              item.id!,
              'Buyer_$i',
              '+9190000000$i',
            ),
          );

          final results = await Future.wait(claimFutures);
          final successList = results.where((r) => r.success).toList();
          final failList = results.where((r) => !r.success).toList();

          expect(successList.length, equals(1));
          expect(failList.length, equals(19));
          expect(successList.first.item!.status, equals('held'));
        },
      );

      test(
        'Confirm after hold expired (fails)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Expiry Test Room',
            'Rohit',
          );
          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            room.sellerKey!,
            'Handmade Pottery',
            350.0,
            1,
          );

          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'Maya',
            null,
          );
          expect(claim.success, isTrue);

          // Manually expire the hold in the database
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          expect(dbItem, isNotNull);
          dbItem!.holdExpiresAt = DateTime.now().toUtc().subtract(
            const Duration(seconds: 15),
          );
          await Item.db.updateRow(session, dbItem);
          await session.close();

          // Buyer attempts to confirm after expiry
          final confirm = await endpoints.room.confirmClaim(
            sessionBuilder,
            item.id!,
            'Maya',
          );
          expect(confirm.success, isFalse);
          expect(confirm.message.toLowerCase(), contains('expired'));
        },
      );

      test(
        'Claim on closed room (fails)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Closed Sale Room',
            'Kiran',
          );
          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            room.sellerKey!,
            'Brass Lamp',
            800.0,
            1,
          );

          // Close the room
          await endpoints.room.toggleRoomStatus(
            sessionBuilder,
            room.id!,
            room.sellerKey!,
            false,
          );

          // Try claiming in a closed room
          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'Varun',
            null,
          );
          expect(claim.success, isFalse);
          expect(claim.message.toLowerCase(), contains('closed'));
        },
      );

      test(
        'Claim after hold expired without future call (succeeds)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Re-claim Room',
            'Deepa',
          );
          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            room.sellerKey!,
            'Silver Ring',
            1200.0,
            1,
          );

          // First buyer claims
          final claim1 = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'BuyerOne',
            null,
          );
          expect(claim1.success, isTrue);

          // Simulate hold expired in the database without future call running
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          dbItem!.holdExpiresAt = DateTime.now().toUtc().subtract(
            const Duration(seconds: 30),
          );
          await Item.db.updateRow(session, dbItem);
          await session.close();

          // Second buyer claims the item whose hold expired
          final claim2 = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'BuyerTwo',
            null,
          );
          expect(claim2.success, isTrue);
          expect(claim2.item!.heldBy, equals('BuyerTwo'));
          expect(claim2.item!.status, equals('held'));
        },
      );

      test(
        'deleteItem on held item (fails)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Delete Test Room',
            'Alok',
          );
          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            room.sellerKey!,
            'Copper Water Bottle',
            650.0,
            1,
          );

          // Claim item to put it in 'held' status
          await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'Rani',
            null,
          );

          // Attempt to delete held item should throw
          expect(
            () => endpoints.room.deleteItem(
              sessionBuilder,
              item.id!,
              room.sellerKey!,
            ),
            throwsA(isA<Exception>()),
          );
        },
      );

      test(
        'Wrong sellerKey on seller-only endpoints (fails)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Protected Room',
            'Owner',
          );
          final correctKey = room.sellerKey!;
          const wrongKey = 'wrong_seller_key_';

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            correctKey,
            'Watch',
            1500.0,
            1,
          );

          // Wrong key on toggleRoomStatus
          expect(
            () => endpoints.room.toggleRoomStatus(
              sessionBuilder,
              room.id!,
              wrongKey,
              false,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Wrong key on addItem
          expect(
            () => endpoints.room.addItem(
              sessionBuilder,
              room.id!,
              wrongKey,
              'Sunglasses',
              500.0,
              1,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Wrong key on deleteItem
          expect(
            () => endpoints.room.deleteItem(
              sessionBuilder,
              item.id!,
              wrongKey,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Wrong key on getOrderSheet
          expect(
            () => endpoints.room.getOrderSheet(
              sessionBuilder,
              room.id!,
              wrongKey,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Wrong key on markPaid
          expect(
            () => endpoints.room.markPaid(
              sessionBuilder,
              item.id!,
              wrongKey,
              true,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Wrong key on endSale
          expect(
            () => endpoints.room.endSale(
              sessionBuilder,
              room.id!,
              wrongKey,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'Claim limit: 4th held item for same buyer fails',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Limit Room',
            'Tanvi',
          );
          final sellerKey = room.sellerKey!;

          final item1 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Earrings 1',
            199.0,
            1,
          );
          final item2 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Earrings 2',
            299.0,
            1,
          );
          final item3 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Earrings 3',
            399.0,
            1,
          );
          final item4 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Earrings 4',
            499.0,
            1,
          );

          const buyerName = 'Shopaholic';

          // First 3 claims must succeed
          final c1 = await endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            buyerName,
            null,
          );
          expect(c1.success, isTrue);

          final c2 = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            buyerName,
            null,
          );
          expect(c2.success, isTrue);

          final c3 = await endpoints.room.claimItem(
            sessionBuilder,
            item3.id!,
            buyerName,
            null,
          );
          expect(c3.success, isTrue);

          // 4th claim for same buyer must fail due to claim limit
          final c4 = await endpoints.room.claimItem(
            sessionBuilder,
            item4.id!,
            buyerName,
            null,
          );
          expect(c4.success, isFalse);
          expect(c4.message.toLowerCase(), contains('limit'));
        },
      );
    },
  );
}
