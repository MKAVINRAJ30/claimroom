import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'hold_helper.dart';

class HoldExpiryFutureCall extends FutureCall {
  Future<void> expireHold(Session session, int itemId) async {
    HoldEndResult? endResult;

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
          endResult = await HoldHelper.endHoldAndHandOver(
            session,
            transaction,
            item,
          );
        }
      }
    });

    if (endResult != null) {
      await HoldHelper.broadcastHoldEnd(session, endResult!);
    }
  }
}
