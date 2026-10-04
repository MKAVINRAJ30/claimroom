import 'package:serverpod/serverpod.dart';
import '../generated/future_calls.dart';
import '../generated/protocol.dart';
import 'sanitizer.dart';

class HoldEndResult {
  final Item item;
  final bool handedOver;
  final int waitlistCount;

  HoldEndResult({
    required this.item,
    required this.handedOver,
    required this.waitlistCount,
  });
}

class HoldHelper {
  /// Ends a hold without a sale inside an existing locked [transaction].
  ///
  /// Checks the waitlist for [item]. The earliest waitlisted buyer who does NOT
  /// already have 3 active holds in this room receives the item with a fresh 60s hold.
  /// If a waitlisted buyer has 3 active holds, they are skipped (kept in the queue).
  /// If nobody can take it (or waitlist is empty), the item becomes 'available'.
  ///
  /// This must be executed inside the same locked transaction as the hold release
  /// so two paths can never hand the same item to two people.
  static Future<HoldEndResult> endHoldAndHandOver(
    Session session,
    Transaction transaction,
    Item item,
  ) async {
    final now = DateTime.now().toUtc();

    // Query waitlist entries for this item ordered by createdAt ascending
    final waitlistEntries = await WaitlistEntry.db.find(
      session,
      where: (t) => t.itemId.equals(item.id!),
      orderBy: (t) => t.createdAt,
      transaction: transaction,
    );

    WaitlistEntry? nextHolder;

    for (final entry in waitlistEntries) {
      // Check active holds for this buyer token in this room
      final activeHolds = await Item.db.find(
        session,
        where: (t) =>
            t.roomId.equals(item.roomId) &
            t.status.equals('held') &
            t.heldByToken.equals(entry.buyerToken) &
            t.holdExpiresAt.notEquals(null) &
            (t.holdExpiresAt > now),
        transaction: transaction,
      );

      if (activeHolds.length < 3) {
        nextHolder = entry;
        break;
      }
      // If 3 or more active holds, skip this buyer (keep them in queue)
    }

    if (nextHolder != null) {
      // Remove the winning buyer from the waitlist
      await WaitlistEntry.db.deleteRow(
        session,
        nextHolder,
        transaction: transaction,
      );

      // Hand over item with a fresh 60-second hold
      final holdExpiresAt = now.add(const Duration(seconds: 60));
      item.status = 'held';
      item.heldBy = nextHolder.buyerName;
      item.heldByContact = null;
      item.heldByToken = nextHolder.buyerToken;
      item.holdExpiresAt = holdExpiresAt;
    } else {
      // Nobody can take it: item becomes available
      item.status = 'available';
      item.heldBy = null;
      item.heldByContact = null;
      item.heldByToken = null;
      item.holdExpiresAt = null;
    }

    // Count remaining waitlist entries
    final remainingCount = await WaitlistEntry.db.count(
      session,
      where: (t) => t.itemId.equals(item.id!),
      transaction: transaction,
    );
    item.waitlistCount = remainingCount;

    final updated = await Item.db.updateRow(
      session,
      item,
      transaction: transaction,
    );

    return HoldEndResult(
      item: updated,
      handedOver: nextHolder != null,
      waitlistCount: remainingCount,
    );
  }

  /// Broadcasts post-transaction events and manages future calls after hold ends.
  ///
  /// Must be called AFTER the transaction commits.
  static Future<void> broadcastHoldEnd(
    Session session,
    HoldEndResult result,
  ) async {
    final item = result.item;
    final itemId = item.id!;
    final roomId = item.roomId;

    // 1. Cancel previous hold future call
    try {
      await session.serverpod.futureCalls.cancel('hold_item_$itemId');
    } catch (e) {
      session.log(
        'Failed to cancel future call for item $itemId: $e',
        level: LogLevel.warning,
      );
    }

    if (result.handedOver) {
      // 2. Schedule new 60s future call for the new holder
      try {
        await session.serverpod.futureCalls
            .callWithDelay(
              const Duration(seconds: 60),
              identifier: 'hold_item_$itemId',
            )
            .holdExpiry
            .expireHold(itemId);
      } catch (e) {
        session.log(
          'Failed to schedule hold expiry future call for item $itemId: $e',
          level: LogLevel.warning,
        );
      }

      // 3. Broadcast sanitized item_claimed event (no tokens or contacts)
      await session.messages.postMessage(
        'room_$roomId',
        RoomEvent(
          roomId: roomId,
          type: 'item_claimed',
          item: sanitizeItem(item),
          message: '${item.name} claimed by ${item.heldBy} from waitlist!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    } else {
      // 3. Broadcast sanitized item_released event
      await session.messages.postMessage(
        'room_$roomId',
        RoomEvent(
          roomId: roomId,
          type: 'item_released',
          item: sanitizeItem(item),
          message: '${item.name} hold expired and is available!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    // 4. Broadcast waitlist_updated event carrying ONLY itemId and waitlistCount
    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'waitlist_updated',
        waitlistItemId: itemId,
        waitlistCount: result.waitlistCount,
        item: null,
        timestamp: DateTime.now().toUtc(),
      ),
    );
  }
}
