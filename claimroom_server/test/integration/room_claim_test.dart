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

          // 3. Verify getOrderSheet with sellerKey DOES retain buyer contact details but strips tokens
          final orderSheet = await endpoints.room.getOrderSheet(
            sessionBuilder,
            room.id!,
            sellerKey,
          );
          expect(orderSheet.buyers.length, 1);
          expect(orderSheet.buyers.first.buyerName, equals('SecretBuyer'));
          expect(orderSheet.buyers.first.buyerContact, equals('+919999888877'));
          expect(
            orderSheet.buyers.first.items.first.soldToContact,
            equals('+919999888877'),
          );
          expect(orderSheet.buyers.first.items.first.heldByToken, isNull);
          expect(orderSheet.buyers.first.items.first.soldToToken, isNull);
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

      test(
        'Hold expiry on read sweep: expired hold returned as available by listItems without future call, broadcasts item_released, unexpired hold untouched',
        () async {
          // 1. Seller creates room and adds 2 items
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Hold Expiry Sweep Room',
            'SweepSeller',
          );
          final sellerKey = room.sellerKey!;

          final itemExpired = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Antique Brass Bell',
            650.0,
            1,
          );

          final itemActive = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Handmade Wool Rug',
            2400.0,
            1,
          );

          // 2. Buyers claim both items
          const token1 = 'token_expired_buyer_12345';
          const token2 = 'token_active_buyer_123456';

          final claim1 = await endpoints.room.claimItem(
            sessionBuilder,
            itemExpired.id!,
            'BuyerExpired',
            '+919876500001',
            token1,
          );
          expect(claim1.success, isTrue);

          final claim2 = await endpoints.room.claimItem(
            sessionBuilder,
            itemActive.id!,
            'BuyerActive',
            '+919876500002',
            token2,
          );
          expect(claim2.success, isTrue);

          // 3. Listen to stream for broadcasted item_released event
          final stream = endpoints.room.streamRoom(sessionBuilder, room.id!);
          final releasedEventFuture = stream.firstWhere(
            (e) => e.type == 'item_released',
          );

          // 4. Manually expire itemExpired's hold in the database without running future call
          final session = sessionBuilder.build();
          final dbItemExpired = await Item.db.findById(
            session,
            itemExpired.id!,
          );
          expect(dbItemExpired, isNotNull);
          dbItemExpired!.holdExpiresAt = DateTime.now().toUtc().subtract(
            const Duration(seconds: 10),
          );
          await Item.db.updateRow(session, dbItemExpired);
          await session.close();

          // 5. Call listItems (this triggers the sweep helper _releaseExpiredHolds)
          final items = await endpoints.room.listItems(
            sessionBuilder,
            room.id!,
          );
          expect(items.length, 2);

          // Verify expired hold is reset to 'available' with heldBy/token/holdExpiresAt cleared
          final sweptItem = items.firstWhere((i) => i.id == itemExpired.id);
          expect(sweptItem.status, equals('available'));
          expect(sweptItem.heldBy, isNull);
          expect(sweptItem.heldByContact, isNull);
          expect(sweptItem.heldByToken, isNull);
          expect(sweptItem.holdExpiresAt, isNull);

          // Verify unexpired hold is NOT touched (remains held)
          final activeItem = items.firstWhere((i) => i.id == itemActive.id);
          expect(activeItem.status, equals('held'));
          expect(activeItem.heldBy, equals('BuyerActive'));
          expect(activeItem.holdExpiresAt, isNotNull);
          expect(
            activeItem.holdExpiresAt!.isAfter(DateTime.now().toUtc()),
            isTrue,
          );

          // 6. Verify broadcast 'item_released' event was emitted
          final event = await releasedEventFuture;
          expect(event.type, equals('item_released'));
          expect(event.roomId, equals(room.id));
          expect(event.item, isNotNull);
          expect(event.item!.id, equals(itemExpired.id));
          expect(event.item!.status, equals('available'));
          expect(event.item!.heldBy, isNull);
          expect(event.item!.heldByContact, isNull);
          expect(event.item!.heldByToken, isNull);

          // 7. Verify directly in database that itemExpired is available
          final checkSession = sessionBuilder.build();
          final finalDbItem = await Item.db.findById(
            checkSession,
            itemExpired.id!,
          );
          expect(finalDbItem!.status, equals('available'));
          expect(finalDbItem.heldBy, isNull);
          expect(finalDbItem.holdExpiresAt, isNull);
          await checkSession.close();
        },
      );

      test(
        'Release by holder hands the item to the first waitlisted buyer, with a new holdExpiresAt',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Waitlist Handover Room',
            'Seller1',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Silk Kimono',
            1800.0,
            1,
          );

          const holderToken = 'holder_token_1111111111111111';
          const waitlistToken1 = 'waitlist_token_22222222222222';
          const waitlistToken2 = 'waitlist_token_33333333333333';

          // 1. First buyer claims the item
          final claim = await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'OriginalHolder',
            null,
            holderToken,
          );
          expect(claim.success, isTrue);

          // 2. Buyer 1 joins waitlist -> position 1
          final pos1 = await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'WaitlistBuyer1',
            waitlistToken1,
          );
          expect(pos1, equals(1));

          // 3. Buyer 2 joins waitlist -> position 2
          final pos2 = await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'WaitlistBuyer2',
            waitlistToken2,
          );
          expect(pos2, equals(2));

          // 4. Verify getMyWaitlist returns correct positions
          final myWaitlist1 = await endpoints.room.getMyWaitlist(
            sessionBuilder,
            room.id!,
            waitlistToken1,
          );
          expect(myWaitlist1.length, equals(1));
          expect(myWaitlist1.first.itemId, equals(item.id));
          expect(myWaitlist1.first.position, equals(1));

          final myWaitlist2 = await endpoints.room.getMyWaitlist(
            sessionBuilder,
            room.id!,
            waitlistToken2,
          );
          expect(myWaitlist2.length, equals(1));
          expect(myWaitlist2.first.itemId, equals(item.id));
          expect(myWaitlist2.first.position, equals(2));

          // 5. Listen for events
          final stream = endpoints.room.streamRoom(sessionBuilder, room.id!);
          final events = <RoomEvent>[];
          final subscription = stream.listen(events.add);

          // 6. Original holder releases the claim -> auto-handover to WaitlistBuyer1
          final releaseResult = await endpoints.room.releaseClaim(
            sessionBuilder,
            item.id!,
            holderToken,
          );
          expect(releaseResult.success, isTrue);

          // Wait a tick for events to arrive
          await Future.delayed(const Duration(milliseconds: 50));
          await subscription.cancel();

          // 7. Verify item is handed over to WaitlistBuyer1 with fresh 60s hold
          final claimedEvent = events.firstWhere(
            (e) => e.type == 'item_claimed' && e.item?.id == item.id,
          );
          expect(claimedEvent.item, isNotNull);
          expect(claimedEvent.item!.heldBy, equals('WaitlistBuyer1'));
          expect(claimedEvent.item!.heldByToken, isNull); // sanitized
          expect(claimedEvent.item!.heldByContact, isNull);

          final waitlistEvent = events.firstWhere(
            (e) => e.type == 'waitlist_updated' && e.waitlistItemId == item.id,
          );
          expect(
            waitlistEvent.waitlistCount,
            equals(1),
          ); // WaitlistBuyer2 remains

          // 8. Verify DB state
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          expect(dbItem!.status, equals('held'));
          expect(dbItem.heldBy, equals('WaitlistBuyer1'));
          expect(dbItem.heldByToken, equals(waitlistToken1));
          expect(
            dbItem.holdExpiresAt!.isAfter(DateTime.now().toUtc()),
            isTrue,
          );
          await session.close();

          // 9. Handed-over buyer confirms claim
          final confirmResult = await endpoints.room.confirmClaim(
            sessionBuilder,
            item.id!,
            waitlistToken1,
          );
          expect(confirmResult.success, isTrue);
          expect(confirmResult.item!.soldTo, equals('WaitlistBuyer1'));
        },
      );

      test(
        'Expiry through read-sweep (no future call) hands over to the next waitlisted buyer',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Read Sweep Handover Room',
            'Seller2',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Vintage Watch',
            3500.0,
            1,
          );

          const holderToken = 'holder_token_sweep_11111111';
          const waitlistToken = 'waitlist_token_sweep_222222';

          await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'HolderToExpire',
            null,
            holderToken,
          );

          await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'WaitlistSuccessor',
            waitlistToken,
          );

          // Manually expire hold in DB without running future call
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          dbItem!.holdExpiresAt = DateTime.now().toUtc().subtract(
            const Duration(seconds: 15),
          );
          await Item.db.updateRow(session, dbItem);
          await session.close();

          // Call listItems to trigger the read-sweep handover
          final items = await endpoints.room.listItems(
            sessionBuilder,
            room.id!,
          );
          expect(items.length, 1);
          final sweptItem = items.first;

          // Verified handed over to WaitlistSuccessor
          expect(sweptItem.status, equals('held'));
          expect(sweptItem.heldBy, equals('WaitlistSuccessor'));
          expect(sweptItem.holdExpiresAt, isNotNull);
          expect(
            sweptItem.holdExpiresAt!.isAfter(DateTime.now().toUtc()),
            isTrue,
          );
        },
      );

      test(
        'A buyer with 3 active holds is skipped in waitlist handover',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Skip 3-Holds Room',
            'Seller3',
          );
          final sellerKey = room.sellerKey!;

          // Add 4 items
          final item1 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Item One',
            100.0,
            1,
          );
          final item2 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Item Two',
            200.0,
            1,
          );
          final item3 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Item Three',
            300.0,
            1,
          );
          final item4 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Item Four',
            400.0,
            1,
          );

          const greedyToken = 'greedy_buyer_token_3holds111';
          const normalToken = 'normal_holder_token_22222222';
          const eligibleToken = 'eligible_waitlist_token_333';

          // Greedy buyer holds 3 items
          await endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            'GreedyBuyer',
            null,
            greedyToken,
          );
          await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            'GreedyBuyer',
            null,
            greedyToken,
          );
          await endpoints.room.claimItem(
            sessionBuilder,
            item3.id!,
            'GreedyBuyer',
            null,
            greedyToken,
          );

          // Normal buyer holds item 4
          await endpoints.room.claimItem(
            sessionBuilder,
            item4.id!,
            'NormalHolder',
            null,
            normalToken,
          );

          // GreedyBuyer joins waitlist for item 4 (position 1)
          final posGreedy = await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item4.id!,
            'GreedyBuyer',
            greedyToken,
          );
          expect(posGreedy, equals(1));

          // EligibleBuyer joins waitlist for item 4 (position 2)
          final posEligible = await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item4.id!,
            'EligibleBuyer',
            eligibleToken,
          );
          expect(posEligible, equals(2));

          // NormalHolder releases item 4
          final releaseResult = await endpoints.room.releaseClaim(
            sessionBuilder,
            item4.id!,
            normalToken,
          );
          expect(releaseResult.success, isTrue);

          // Verify item 4 went to EligibleBuyer (GreedyBuyer was skipped)
          final session = sessionBuilder.build();
          final dbItem4 = await Item.db.findById(session, item4.id!);
          expect(dbItem4!.heldBy, equals('EligibleBuyer'));
          expect(dbItem4.heldByToken, equals(eligibleToken));

          // Verify GreedyBuyer was kept in the queue!
          final greedyWaitlist = await endpoints.room.getMyWaitlist(
            sessionBuilder,
            room.id!,
            greedyToken,
          );
          expect(greedyWaitlist.length, equals(1));
          expect(greedyWaitlist.first.itemId, equals(item4.id));
          expect(greedyWaitlist.first.position, equals(1));
          await session.close();
        },
      );

      test(
        'Concurrent release plus expiry never produces two holders',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Concurrent Release/Expiry Room',
            'Seller4',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Antique Mirror',
            2200.0,
            1,
          );

          const holderToken = 'holder_token_concurrent_111';
          const waitlistToken = 'waitlist_token_concurrent_2';

          await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'HolderConcurrent',
            null,
            holderToken,
          );

          await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'WaitlistWinner',
            waitlistToken,
          );

          // Manually expire hold
          final session = sessionBuilder.build();
          final dbItem = await Item.db.findById(session, item.id!);
          dbItem!.holdExpiresAt = DateTime.now().toUtc().subtract(
            const Duration(seconds: 10),
          );
          await Item.db.updateRow(session, dbItem);
          await session.close();

          // Concurrent releaseClaim and listItems (read-sweep)
          final releaseFuture = endpoints.room.releaseClaim(
            sessionBuilder,
            item.id!,
            holderToken,
          );
          final sweepFuture = endpoints.room.listItems(
            sessionBuilder,
            room.id!,
          );

          await Future.wait([releaseFuture, sweepFuture]);

          // Exactly one holder in DB: WaitlistWinner
          final checkSession = sessionBuilder.build();
          final finalItem = await Item.db.findById(checkSession, item.id!);
          expect(finalItem!.status, equals('held'));
          expect(finalItem.heldBy, equals('WaitlistWinner'));
          expect(finalItem.heldByToken, equals(waitlistToken));

          // Waitlist count is 0
          final remainingWaitlist = await WaitlistEntry.db.count(
            checkSession,
            where: (t) => t.itemId.equals(item.id!),
          );
          expect(remainingWaitlist, equals(0));
          await checkSession.close();
        },
      );

      test(
        'Sold item clears its waitlist; endSale clears all waitlists',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Clear Waitlist Room',
            'Seller5',
          );
          final sellerKey = room.sellerKey!;

          final item1 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Product One',
            500.0,
            1,
          );
          final item2 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Product Two',
            600.0,
            1,
          );

          const buyer1Token = 'buyer_token_clear_1111111111';
          const buyer2Token = 'buyer_token_clear_2222222222';
          const waitlistToken = 'waitlist_token_clear_3333333';

          // Hold item 1 and item 2
          await endpoints.room.claimItem(
            sessionBuilder,
            item1.id!,
            'Buyer1',
            null,
            buyer1Token,
          );
          await endpoints.room.claimItem(
            sessionBuilder,
            item2.id!,
            'Buyer2',
            null,
            buyer2Token,
          );

          // Join waitlists
          await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item1.id!,
            'WL_Buyer1',
            waitlistToken,
          );
          await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item2.id!,
            'WL_Buyer2',
            waitlistToken,
          );

          // 1. Confirm item 1 -> sold clears its waitlist
          await endpoints.room.confirmClaim(
            sessionBuilder,
            item1.id!,
            buyer1Token,
          );

          final session = sessionBuilder.build();
          final waitlist1Count = await WaitlistEntry.db.count(
            session,
            where: (t) => t.itemId.equals(item1.id!),
          );
          expect(waitlist1Count, equals(0));

          // Item 2 waitlist still has 1 entry
          final waitlist2CountBefore = await WaitlistEntry.db.count(
            session,
            where: (t) => t.itemId.equals(item2.id!),
          );
          expect(waitlist2CountBefore, equals(1));

          // 2. End sale -> clears all waitlists in room
          await endpoints.room.endSale(
            sessionBuilder,
            room.id!,
            sellerKey,
          );

          final waitlistTotalAfter = await WaitlistEntry.db.count(
            session,
            where: (t) => t.roomId.equals(room.id!),
          );
          expect(waitlistTotalAfter, equals(0));
          await session.close();
        },
      );

      test(
        'Waitlist limit of 10 and no duplicate entries',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Waitlist Limit Room',
            'Seller6',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Hot Limited Item',
            999.0,
            1,
          );

          const holderToken = 'holder_token_limit_00000000';
          await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'InitialHolder',
            null,
            holderToken,
          );

          // Cannot join waitlist if holding it
          expect(
            () => endpoints.room.joinWaitlist(
              sessionBuilder,
              room.id!,
              item.id!,
              'InitialHolder',
              holderToken,
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Add 10 buyers to waitlist
          for (int i = 1; i <= 10; i++) {
            final pos = await endpoints.room.joinWaitlist(
              sessionBuilder,
              room.id!,
              item.id!,
              'Buyer$i',
              'token_limit_buyer_$i',
            );
            expect(pos, equals(i));
          }

          // Duplicate entry fails
          expect(
            () => endpoints.room.joinWaitlist(
              sessionBuilder,
              room.id!,
              item.id!,
              'Buyer1Duplicate',
              'token_limit_buyer_1',
            ),
            throwsA(isA<ArgumentError>()),
          );

          // 11th buyer fails (waitlist full)
          expect(
            () => endpoints.room.joinWaitlist(
              sessionBuilder,
              room.id!,
              item.id!,
              'Buyer11',
              'token_limit_buyer_11',
            ),
            throwsA(isA<ArgumentError>()),
          );

          // Buyer 5 leaves waitlist
          final leaveResult = await endpoints.room.leaveWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'token_limit_buyer_5',
          );
          expect(leaveResult, isTrue);

          // Now a new buyer can join
          final newPos = await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'NewBuyer',
            'token_limit_new_buyer',
          );
          expect(newPos, equals(10));
        },
      );

      test(
        'No tokens or contacts appear in listItems or stream events after waitlist changes',
        () async {
          final room = await endpoints.room.createRoom(
            sessionBuilder,
            'Privacy Waitlist Room',
            'Seller7',
          );
          final sellerKey = room.sellerKey!;

          final item = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            sellerKey,
            'Secret Product',
            1500.0,
            1,
          );

          const holderToken = 'holder_private_token_123456';
          const waitlistToken = 'waitlist_private_token_1234';

          final stream = endpoints.room.streamRoom(sessionBuilder, room.id!);
          final events = <RoomEvent>[];
          final subscription = stream.listen(events.add);

          // Holder claims with contact
          await endpoints.room.claimItem(
            sessionBuilder,
            item.id!,
            'PrivateHolder',
            '+919876543210',
            holderToken,
          );

          // Waitlist buyer joins
          await endpoints.room.joinWaitlist(
            sessionBuilder,
            room.id!,
            item.id!,
            'PrivateWaitlister',
            waitlistToken,
          );

          // Holder releases -> handover
          await endpoints.room.releaseClaim(
            sessionBuilder,
            item.id!,
            holderToken,
          );

          // Fetch items via listItems
          final items = await endpoints.room.listItems(
            sessionBuilder,
            room.id!,
          );
          expect(items.length, 1);
          final fetchedItem = items.first;

          // Verify listItems has no contact or token
          expect(fetchedItem.heldByToken, isNull);
          expect(fetchedItem.soldToToken, isNull);
          expect(fetchedItem.heldByContact, isNull);
          expect(fetchedItem.soldToContact, isNull);

          // Wait a tick for events
          await Future.delayed(const Duration(milliseconds: 50));
          await subscription.cancel();

          // Verify stream events
          for (final event in events) {
            if (event.item != null) {
              expect(event.item!.heldByToken, isNull);
              expect(event.item!.soldToToken, isNull);
              expect(event.item!.heldByContact, isNull);
              expect(event.item!.soldToContact, isNull);
            }
            if (event.type == 'waitlist_updated') {
              expect(event.item, isNull);
              expect(event.waitlistItemId, isNotNull);
              expect(event.waitlistCount, isNotNull);
            }
          }
        },
      );
    },
  );
}
