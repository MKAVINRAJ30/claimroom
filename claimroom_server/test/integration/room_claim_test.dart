import 'package:test/test.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'Given ClaimRoom endpoints',
    rollbackDatabase: RollbackDatabase.disabled,
    (sessionBuilder, endpoints) {
      test(
        'full seller and buyer claim flow with atomic double-claim prevention',
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

          // 2. Buyer joins by code
          final foundRoom = await endpoints.room.getRoomByCode(
            sessionBuilder,
            room.code,
          );
          expect(foundRoom, isNotNull);
          expect(foundRoom!.id, room.id);

          // 3. Seller adds items
          final item1 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            'Vintage Denim Jacket',
            1499.0,
            1,
          );
          final item2 = await endpoints.room.addItem(
            sessionBuilder,
            room.id!,
            'Silk Floral Scarf',
            499.0,
            1,
          );
          expect(item1.status, 'available');
          expect(item2.status, 'available');

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

          // 7. Verify Order Sheet for Seller
          final orderSheet = await endpoints.room.getOrderSheet(
            sessionBuilder,
            room.id!,
          );
          expect(orderSheet.roomId, room.id);
          expect(orderSheet.totalItemsSold, 2);
          expect(orderSheet.grandTotal, 1499.0 + 499.0);
          expect(orderSheet.buyers.length, 1);
          expect(orderSheet.buyers.first.buyerName, winningBuyer);
          expect(orderSheet.buyers.first.items.length, 2);
          expect(orderSheet.buyers.first.totalAmount, 1998.0);
        },
      );
    },
  );
}
