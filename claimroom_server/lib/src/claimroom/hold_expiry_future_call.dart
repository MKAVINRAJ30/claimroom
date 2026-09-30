import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class HoldExpiryFutureCall extends FutureCall {
  Future<void> expireHold(Session session, int itemId) async {
    Item? releasedItem;
    int? targetRoomId;

    await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (item != null && item.status == 'held') {
        // Verify expiry time
        final now = DateTime.now().toUtc();
        if (item.holdExpiresAt != null &&
            (item.holdExpiresAt!.isBefore(now) ||
                item.holdExpiresAt!.difference(now).inSeconds <= 1)) {
          item.status = 'available';
          item.heldBy = null;
          item.heldByContact = null;
          item.holdExpiresAt = null;
          releasedItem = await Item.db.updateRow(
            session,
            item,
            transaction: transaction,
          );
          targetRoomId = item.roomId;
        }
      }
    });

    if (releasedItem != null && targetRoomId != null) {
      await session.messages.postMessage(
        'room_$targetRoomId',
        RoomEvent(
          roomId: targetRoomId!,
          type: 'item_released',
          item: releasedItem,
          message: '${releasedItem!.name} hold expired and is available!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }
  }
}
