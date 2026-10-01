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
          const priyaToken = 'token_priya_12345678901234';
          const rahulToken = 'token_rahul_12345678901234';
          final futureClaim1 = endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            'Priya',
            '+919876543210',
            priyaToken,
          );
          final futureClaim2 = endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            'Rahul',
            '+919876543211',
            rahulToken,
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
          final winningToken = winningBuyer == 'Priya'
              ? priyaToken
              : rahulToken;

          // 5. Confirm claim: The winning buyer confirms within hold window
          final confirmResult = await endpoints.room.confirmClaim(
            sessionBuilder,
            item1.id!,
            winningToken,
          );
          expect(confirmResult.success, isTrue);
          expect(confirmResult.item!.status, 'sold');
          expect(confirmResult.item!.soldTo, winningBuyer);

          // 6. Test claim & release on item2
          const snehaToken = 'token_sneha_12345678901234';
          final claim2 = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            'Sneha',
            '+919876543212',
            snehaToken,
          );
          expect(claim2.success, isTrue);
          expect(claim2.item!.status, 'held');

          // Sneha decides to release the hold
          final releaseResult = await endpoints.room.releaseClaim(
            sessionBuilder,
            item2.id!,
            snehaToken,
          );
          expect(releaseResult.success, isTrue);
          expect(releaseResult.item!.status, 'available');

          // Now someone else can claim item2
          final claim2Again = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            winningBuyer!,
            '+919876543210',
            winningToken,
          );
          expect(claim2Again.success, isTrue);

          await endpoints.room.confirmClaim(
            sessionBuilder,
            item2.id!,
            winningToken,
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
              'token_buyer_${i}_123456789012',
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

          const mayaToken = 'token_maya_1234567890123456';
          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'Maya',
            null,
            mayaToken,
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
            mayaToken,
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
            'token_varun_1234567890123456',
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
            'token_one_1234567890123456',
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
            'token_two_1234567890123456',
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
            'token_rani_1234567890123456',
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
          const shopaholicToken = 'token_shopaholic_12345678';

          // First 3 claims must succeed
          final c1 = await endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            buyerName,
            null,
            shopaholicToken,
          );
          expect(c1.success, isTrue);

          final c2 = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            buyerName,
            null,
            shopaholicToken,
          );
          expect(c2.success, isTrue);

          final c3 = await endpoints.room.claimItem(
            sessionBuilder,
            item3.id!,
            buyerName,
            null,
            shopaholicToken,
          );
          expect(c3.success, isTrue);

          // 4th claim for same buyer must fail due to claim limit
          final c4 = await endpoints.room.claimItem(
            sessionBuilder,
            item4.id!,
            buyerName,
            null,
            shopaholicToken,
          );
          expect(c4.success, isFalse);
          expect(c4.message.toLowerCase(), contains('limit'));
        },
      );

      test(
        'Buyer-visible data (listItems, stream events, ClaimResult for others) contains no contact fields or tokens',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Privacy Room',
            'SafeSeller',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Private Dress',
            1200.0,
            1,
          );

          // Listen to stream before claim
          final stream = endpoints.room.streamRoom(sessionBuilder, room.id!);
          final streamFuture = stream.firstWhere(
            (e) => e.type == 'item_claimed',
          );

          // Buyer claims with private contact info
          const secretToken = 'token_secret_12345678901234';
          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'SecretBuyer',
            '+919999888877',
            secretToken,
          );
          expect(claim.success, isTrue);

          // 1. Verify stream event item has no contact fields or tokens
          final event = await streamFuture;
          expect(event.item, isNotNull);
          expect(event.item!.heldBy, equals('SecretBuyer'));
          expect(event.item!.heldByContact, isNull);
          expect(event.item!.soldToContact, isNull);
          expect(event.item!.heldByToken, isNull);
          expect(event.item!.soldToToken, isNull);

          // 2. Verify listItems returns sanitized items with no contacts or tokens
          final items = await endpoints.room.listItems(
            sessionBuilder,
            room.id!,
          );
          expect(items.length, 1);
          expect(items.first.heldBy, equals('SecretBuyer'));
          expect(items.first.heldByContact, isNull);
          expect(items.first.soldToContact, isNull);
          expect(items.first.heldByToken, isNull);
          expect(items.first.soldToToken, isNull);

          // 3. Another buyer tries to claim held item -> ClaimResult has no contacts or tokens
          final otherClaim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'OtherBuyer',
            null,
            'token_other_987654321',
          );
          expect(otherClaim.success, isFalse);
          expect(otherClaim.item, isNotNull);
          expect(otherClaim.item!.heldByContact, isNull);
          expect(otherClaim.item!.soldToContact, isNull);
          expect(otherClaim.item!.heldByToken, isNull);
          expect(otherClaim.item!.soldToToken, isNull);

          // Buyer confirms claim
          final confirm = await endpoints.room.confirmClaim(
            sessionBuilder,
            item.id!,
            secretToken,
          );
          expect(confirm.success, isTrue);
          expect(confirm.item!.heldByToken, isNull);
          expect(confirm.item!.soldToToken, isNull);

          // 3. Verify getOrderSheet with sellerKey DOES retain buyer contact details
          final orderSheet = await endpoints.room.getOrderSheet(
            sessionBuilder,
            room.id!,
            sellerKey,
          );
          expect(orderSheet.buyers.length, 1);
          expect(orderSheet.buyers.first.buyerName, equals('SecretBuyer'));
          expect(orderSheet.buyers.first.buyerContact, equals('+919999888877'));
        },
      );

      test(
        'Buyer identity by token: same name different token cannot confirm or release, wrong token fails, correct token confirms',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Token Identity Room',
            'SellerTest',
          );
          final sellerKey = room.sellerKey!;

          final item1 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Handmade Vase',
            750.0,
            1,
          );
          final item2 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Handmade Bowl',
            450.0,
            1,
          );

          const buyerName = 'DuplicateNameBuyer';
          const tokenA = 'token_buyer_A_1111111111111';
          const tokenB = 'token_buyer_B_2222222222222';

          // Buyer A claims item1
          final claim1 = await endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            buyerName,
            '+911111111111',
            tokenA,
          );
          expect(claim1.success, isTrue);

          // Buyer B (same name, different token) tries to confirm Buyer A's hold -> fails
          final confirmFail = await endpoints.room.confirmClaim(
            sessionBuilder,
            item1.id!,
            tokenB,
          );
          expect(confirmFail.success, isFalse);
          expect(
            confirmFail.message.toLowerCase(),
            contains('not have an active hold'),
          );

          // Buyer B tries to release Buyer A's hold -> fails
          final releaseFail = await endpoints.room.releaseClaim(
            sessionBuilder,
            item1.id!,
            tokenB,
          );
          expect(releaseFail.success, isFalse);
          expect(releaseFail.message.toLowerCase(), contains('do not hold'));

          // Buyer A confirms with correct token -> succeeds!
          final confirmSuccess = await endpoints.room.confirmClaim(
            sessionBuilder,
            item1.id!,
            tokenA,
          );
          expect(confirmSuccess.success, isTrue);
          expect(confirmSuccess.item!.status, equals('sold'));
          expect(confirmSuccess.item!.soldTo, equals(buyerName));

          // Now test release with item2
          final claim2 = await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            buyerName,
            null,
            tokenA,
          );
          expect(claim2.success, isTrue);

          // Buyer B cannot release item2
          final releaseFail2 = await endpoints.room.releaseClaim(
            sessionBuilder,
            item2.id!,
            tokenB,
          );
          expect(releaseFail2.success, isFalse);

          // Buyer A can release item2
          final releaseSuccess = await endpoints.room.releaseClaim(
            sessionBuilder,
            item2.id!,
            tokenA,
          );
          expect(releaseSuccess.success, isTrue);
          expect(releaseSuccess.item!.status, equals('available'));
        },
      );

      test(
        'markPaid fails on unsold item (available or held)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'MarkPaid Room',
            'SellerM',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Silk Shirt',
            999.0,
            1,
          );

          // 1. Available item cannot be marked paid
          expect(
            () => endpoints.room.markPaid(
              sessionBuilder,
              item.id!,
              sellerKey,
              true,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // 2. Held item cannot be marked paid
          await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'BuyerH',
            null,
            'token_buyer_held_1234567890',
          );
          expect(
            () => endpoints.room.markPaid(
              sessionBuilder,
              item.id!,
              sellerKey,
              true,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'endSale releases holds and claims fail afterwards',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'EndSale Room',
            'SellerE',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Leather Wallet',
            499.0,
            1,
          );

          // Buyer holds the item
          const buyerToken = 'token_endsale_buyer_123456';
          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'BuyerE',
            null,
            buyerToken,
          );
          expect(claim.success, isTrue);
          expect(claim.item!.status, equals('held'));

          // Seller ends the sale
          final ended = await endpoints.room.endSale(
            sessionBuilder,
            room.id!,
            sellerKey,
          );
          expect(ended.isOpen, isFalse);

          // Verify held item was released back to 'available'
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          expect(dbItem, isNotNull);
          expect(dbItem!.status, equals('available'));
          expect(dbItem.heldBy, isNull);
          expect(dbItem.heldByToken, isNull);
          expect(dbItem.holdExpiresAt, isNull);
          await session.close();

          // Claims after the sale ended must fail
          final lateClaim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'LateBuyer',
            null,
            'token_late_buyer_12345678901',
          );
          expect(lateClaim.success, isFalse);
          expect(lateClaim.message.toLowerCase(), contains('closed'));
        },
      );

      test(
        'addItem rejects invalid imageUrl and accepts valid or blank',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Image Room',
            'SellerImg',
          );
          final sellerKey = room.sellerKey!;

          // Rejects ftp://
          expect(
            () => endpoints.room.addItem(
              sessionBuilder,
              room.id!,
              sellerKey,
              'Invalid FTP',
              100.0,
              1,
              imageUrl: 'ftp://example.com/pic.jpg',
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Rejects non-url text
          expect(
            () => endpoints.room.addItem(
              sessionBuilder,
              room.id!,
              sellerKey,
              'Invalid Plain Text',
              100.0,
              1,
              imageUrl: 'not-a-url',
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Rejects url > 500 characters
          final longUrl = 'https://example.com/${'x' * 500}';
          expect(
            () => endpoints.room.addItem(
              sessionBuilder,
              room.id!,
              sellerKey,
              'Too Long URL',
              100.0,
              1,
              imageUrl: longUrl,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Accepts blank imageUrl and stores null
          final blankItem = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Blank Image Item',
            150.0,
            1,
            imageUrl: '   ',
          );
          expect(blankItem.imageUrl, isNull);

          // Accepts valid https:// url
          final validItem = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Valid Image Item',
            200.0,
            1,
            imageUrl: 'https://images.unsplash.com/photo-test.jpg',
          );
          expect(
            validItem.imageUrl,
            equals('https://images.unsplash.com/photo-test.jpg'),
          );
        },
      );

      test(
        'addItem rejects 51st item (room limit of 50)',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Limit 50 Room',
            'SellerBulk',
          );
          final sellerKey = room.sellerKey!;

          // Add 50 items
          for (int i = 1; i <= 50; i++) {
            await endpoints.room.addItem(
              sessionBuilder,
              room.id!,
              sellerKey,
              'Bulk Item $i',
              10.0 + i,
              1,
            );
          }

          // 51st item must be rejected
          expect(
            () => endpoints.room.addItem(
              sessionBuilder,
              room.id!,
              sellerKey,
              '51st Item',
              99.0,
              1,
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'reportRoom accepts valid report and rejects empty or long reasons',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Trust & Safety Room',
            'SuspiciousSeller',
          );

          // 1. Valid report
          final report = await endpoints.room.reportRoom(
            sessionBuilder,
            room.code,
            'Seller is charging extra delivery fee off-platform.',
          );
          expect(report.id, isNotNull);
          expect(report.roomId, equals(room.id));
          expect(
            report.reason,
            equals('Seller is charging extra delivery fee off-platform.'),
          );
          expect(report.createdAt, isNotNull);

          // 2. Reject empty reason
          expect(
            () => endpoints.room.reportRoom(
              sessionBuilder,
              room.code,
              '   ',
            ),
            throwsA(isA<ArgumentError>()),
          );

          // 3. Reject reason > 500 characters
          final longReason = 'x' * 501;
          expect(
            () => endpoints.room.reportRoom(
              sessionBuilder,
              room.code,
              longReason,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // 4. Reject non-existent room code
          expect(
            () => endpoints.room.reportRoom(
              sessionBuilder,
              'ZZZZZ',
              'Valid reason for non-existent room',
            ),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test(
        'Seller release abandoned hold: sellerKey required, resets to available and broadcasts',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Release Hold Room',
            'ActiveSeller',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Handmade Vase',
            600.0,
            1,
          );

          // Buyer claims item
          final token = 'buyer_token_123456789012';
          final claimRes = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'Priya',
            'priya@example.com',
            token,
          );
          expect(claimRes.success, isTrue);

          // Wrong sellerKey fails
          expect(
            () => endpoints.room.releaseHoldAsSeller(
              sessionBuilder,
              item.id!,
              'wrong_key_123456',
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Correct sellerKey releases hold early
          final released = await endpoints.room.releaseHoldAsSeller(
            sessionBuilder,
            item.id!,
            sellerKey,
          );
          expect(released.status, equals('available'));
          expect(released.heldBy, isNull);
          expect(released.heldByContact, isNull);
          expect(released.heldByToken, isNull);
          expect(released.holdExpiresAt, isNull);

          // Attempting to release an already available item fails
          expect(
            () => endpoints.room.releaseHoldAsSeller(
              sessionBuilder,
              item.id!,
              sellerKey,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Another buyer can now claim the item
          final token2 = 'buyer_token_987654321098';
          final claimRes2 = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'Ananya',
            'ananya@example.com',
            token2,
          );
          expect(claimRes2.success, isTrue);
          expect(claimRes2.item!.heldBy, equals('Ananya'));
        },
      );

      test(
        'Concurrent confirm and release on the same hold: exactly one succeeds',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Concurrent Action Room',
            'ConcurrentSeller',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Vintage Lamp',
            850.0,
            1,
          );

          const buyerToken = 'concurrent_buyer_token_12345';
          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'ConcurrentBuyer',
            'buyer@concurrent.com',
            buyerToken,
          );
          expect(claim.success, isTrue);

          // Fire confirm and release concurrently on the same held item
          final confirmFuture = endpoints.room.confirmClaim(
            sessionBuilder,
            item.id!,
            buyerToken,
          );
          final releaseFuture = endpoints.room.releaseClaim(
            sessionBuilder,
            item.id!,
            buyerToken,
          );

          final results = await Future.wait([confirmFuture, releaseFuture]);
          final successCount = results.where((r) => r.success).length;
          final failureCount = results.where((r) => !r.success).length;

          // Exactly one must succeed, and the other must fail safely
          expect(successCount, equals(1));
          expect(failureCount, equals(1));

          // Verify database state is consistent (either 'sold' or 'available', never corrupt)
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          expect(dbItem, isNotNull);
          expect(dbItem!.status, anyOf(equals('sold'), equals('available')));
          await session.close();
        },
      );
    },
  );
}
