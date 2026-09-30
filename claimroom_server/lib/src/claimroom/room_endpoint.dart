import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/future_calls.dart';
import '../generated/protocol.dart';

class RoomEndpoint extends Endpoint {
  static const _letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _newCode() {
    final rnd = Random.secure();
    return List.generate(
      5,
      (_) => _letters[rnd.nextInt(_letters.length)],
    ).join();
  }

  /// Seller creates a room and gets back its join code.
  Future<Room> createRoom(
    Session session,
    String title,
    String sellerName,
  ) async {
    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final room = Room(
          code: _newCode(),
          title: title.trim(),
          sellerName: sellerName.trim(),
          isOpen: true,
          createdAt: DateTime.now().toUtc(),
        );
        return await Room.db.insertRow(session, room);
      } catch (e) {
        // Code collision on the unique index: try a new code.
        if (attempt == 4) rethrow;
      }
    }
    throw Exception('Could not create room');
  }

  /// Buyers use this to join with a code.
  Future<Room?> getRoomByCode(Session session, String code) async {
    return await Room.db.findFirstRow(
      session,
      where: (t) => t.code.equals(code.trim().toUpperCase()),
    );
  }

  /// Get room by its ID.
  Future<Room?> getRoom(Session session, int roomId) async {
    return await Room.db.findById(session, roomId);
  }

  /// Seller can open or close claiming in the room.
  Future<Room> toggleRoomStatus(
    Session session,
    int roomId,
    bool isOpen,
  ) async {
    final room = await Room.db.findById(session, roomId);
    if (room == null) throw Exception('Room not found');

    room.isOpen = isOpen;
    final updated = await Room.db.updateRow(session, room);

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'room_status_changed',
        item: null,
        message: isOpen
            ? 'Room is now OPEN for claims!'
            : 'Room is now CLOSED for claims.',
        timestamp: DateTime.now().toUtc(),
      ),
    );

    return updated;
  }

  /// Seller adds one product to a room.
  Future<Item> addItem(
    Session session,
    int roomId,
    String name,
    double price,
    int quantity,
  ) async {
    final item = Item(
      roomId: roomId,
      name: name.trim(),
      price: price,
      quantity: quantity > 0 ? quantity : 1,
      status: 'available',
    );
    final inserted = await Item.db.insertRow(session, item);

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'item_added',
        item: inserted,
        message: 'New item added: ${inserted.name}',
        timestamp: DateTime.now().toUtc(),
      ),
    );

    return inserted;
  }

  /// Seller removes an available item.
  Future<bool> deleteItem(Session session, int itemId) async {
    final item = await Item.db.findById(session, itemId);
    if (item == null) return false;
    if (item.status != 'available') {
      throw Exception('Cannot delete an item that is already held or sold');
    }

    final roomId = item.roomId;
    await Item.db.deleteRow(session, item);

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'item_deleted',
        item: item,
        message: 'Item removed: ${item.name}',
        timestamp: DateTime.now().toUtc(),
      ),
    );

    return true;
  }

  /// Everyone in the room reads the current items.
  Future<List<Item>> listItems(Session session, int roomId) async {
    return await Item.db.find(
      session,
      where: (t) => t.roomId.equals(roomId),
      orderBy: (t) => t.id,
    );
  }

  /// Real-time event stream for the room.
  /// Clients subscribe to this stream to receive instant updates when
  /// items are added, claimed, held, confirmed, or released.
  Stream<RoomEvent> streamRoom(Session session, int roomId) {
    return session.messages.createStream<RoomEvent>('room_$roomId');
  }

  /// Atomic claim: Buyer taps "Claim".
  /// Uses a database transaction with LockMode.forUpdate to eliminate race conditions.
  /// If two buyers claim simultaneously, PostgreSQL row-level locks ensure only
  /// one succeeds.
  Future<ClaimResult> claimItem(
    Session session,
    int itemId,
    String buyerName,
    String? buyerContact,
  ) async {
    final trimmedName = buyerName.trim();
    if (trimmedName.isEmpty) {
      return ClaimResult(
        success: false,
        message: 'Please enter your name to claim.',
      );
    }

    ClaimResult result = await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (item == null) {
        return ClaimResult(
          success: false,
          message: 'Item does not exist.',
        );
      }

      // Check if room is open
      final room = await Room.db.findById(
        session,
        item.roomId,
        transaction: transaction,
      );
      if (room == null || !room.isOpen) {
        return ClaimResult(
          success: false,
          message: 'The room is currently closed for claims.',
          item: item,
        );
      }

      if (item.status != 'available') {
        final currentOwner = item.status == 'held' ? item.heldBy : item.soldTo;
        return ClaimResult(
          success: false,
          message:
              'Already ${item.status} by ${currentOwner ?? "another buyer"}.',
          item: item,
        );
      }

      // Claim successfully: place 60-second hold
      final holdExpiresAt = DateTime.now().toUtc().add(
        const Duration(seconds: 60),
      );
      item.status = 'held';
      item.heldBy = trimmedName;
      item.heldByContact = buyerContact?.trim();
      item.holdExpiresAt = holdExpiresAt;

      final updated = await Item.db.updateRow(
        session,
        item,
        transaction: transaction,
      );

      return ClaimResult(
        success: true,
        message: 'Item held for 60s! Confirm before the timer expires.',
        item: updated,
      );
    });

    if (result.success && result.item != null) {
      // 1. Schedule automatic release future call
      await session.serverpod.futureCalls
          .callWithDelay(
            const Duration(seconds: 60),
            identifier: 'hold_item_$itemId',
          )
          .holdExpiry
          .expireHold(itemId);

      // 2. Broadcast claim event to all connected clients
      await session.messages.postMessage(
        'room_${result.item!.roomId}',
        RoomEvent(
          roomId: result.item!.roomId,
          type: 'item_claimed',
          item: result.item,
          message: '${result.item!.name} claimed by $trimmedName!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    return result;
  }

  /// Buyer confirms their claim within the 60-second hold period.
  /// Converts hold state to permanent sold state.
  Future<ClaimResult> confirmClaim(
    Session session,
    int itemId,
    String buyerName,
  ) async {
    final trimmedName = buyerName.trim();

    ClaimResult result = await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (item == null) {
        return ClaimResult(
          success: false,
          message: 'Item not found.',
        );
      }

      if (item.status != 'held' || item.heldBy != trimmedName) {
        return ClaimResult(
          success: false,
          message: 'You do not have an active hold on this item.',
          item: item,
        );
      }

      // Check if hold has expired
      final now = DateTime.now().toUtc();
      if (item.holdExpiresAt != null && item.holdExpiresAt!.isBefore(now)) {
        return ClaimResult(
          success: false,
          message: 'Your 60-second hold has expired.',
          item: item,
        );
      }

      // Confirm order
      item.status = 'sold';
      item.soldTo = item.heldBy;
      item.soldToContact = item.heldByContact;
      item.soldAt = now;
      item.heldBy = null;
      item.heldByContact = null;
      item.holdExpiresAt = null;

      final updated = await Item.db.updateRow(
        session,
        item,
        transaction: transaction,
      );

      return ClaimResult(
        success: true,
        message: 'Order confirmed! Item marked as sold.',
        item: updated,
      );
    });

    if (result.success && result.item != null) {
      // Cancel the scheduled expiry future call
      await session.serverpod.futureCalls.cancel('hold_item_$itemId');

      // Broadcast confirmed order to room
      await session.messages.postMessage(
        'room_${result.item!.roomId}',
        RoomEvent(
          roomId: result.item!.roomId,
          type: 'item_confirmed',
          item: result.item,
          message: '${result.item!.name} sold to $trimmedName!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    return result;
  }

  /// Buyer cancels or releases a held item back to the room before expiry.
  Future<ClaimResult> releaseClaim(
    Session session,
    int itemId,
    String buyerName,
  ) async {
    final trimmedName = buyerName.trim();

    ClaimResult result = await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (item == null) {
        return ClaimResult(
          success: false,
          message: 'Item not found.',
        );
      }

      if (item.status != 'held' || item.heldBy != trimmedName) {
        return ClaimResult(
          success: false,
          message: 'You do not hold this item.',
          item: item,
        );
      }

      item.status = 'available';
      item.heldBy = null;
      item.heldByContact = null;
      item.holdExpiresAt = null;

      final updated = await Item.db.updateRow(
        session,
        item,
        transaction: transaction,
      );

      return ClaimResult(
        success: true,
        message: 'Item released back to the room.',
        item: updated,
      );
    });

    if (result.success && result.item != null) {
      await session.serverpod.futureCalls.cancel('hold_item_$itemId');

      await session.messages.postMessage(
        'room_${result.item!.roomId}',
        RoomEvent(
          roomId: result.item!.roomId,
          type: 'item_released',
          item: result.item,
          message: '${result.item!.name} was released and is available again!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    return result;
  }

  /// Generates the complete order sheet for the seller.
  /// Aggregates all confirmed (sold) items grouped by buyer name.
  Future<OrderSheet> getOrderSheet(Session session, int roomId) async {
    final room = await Room.db.findById(session, roomId);
    if (room == null) throw Exception('Room not found');

    final items = await Item.db.find(
      session,
      where: (t) => t.roomId.equals(roomId),
      orderBy: (t) => t.id,
    );

    final Map<String, List<Item>> buyerItemsMap = {};
    final Map<String, String?> buyerContactMap = {};

    double grandTotal = 0.0;
    int totalItemsSold = 0;

    for (final item in items) {
      if (item.status == 'sold' && item.soldTo != null) {
        final buyer = item.soldTo!;
        buyerItemsMap.putIfAbsent(buyer, () => []).add(item);
        if (item.soldToContact != null && item.soldToContact!.isNotEmpty) {
          buyerContactMap[buyer] = item.soldToContact;
        }
        grandTotal += item.price;
        totalItemsSold += item.quantity;
      }
    }

    final buyerSummaries = buyerItemsMap.entries.map((entry) {
      final buyer = entry.key;
      final bItems = entry.value;
      final total = bItems.fold<double>(0.0, (sum, i) => sum + i.price);
      final count = bItems.fold<int>(0, (sum, i) => sum + i.quantity);
      return BuyerOrderSummary(
        buyerName: buyer,
        buyerContact: buyerContactMap[buyer],
        items: bItems,
        totalAmount: total,
        itemCount: count,
      );
    }).toList();

    return OrderSheet(
      roomId: roomId,
      roomTitle: room.title,
      sellerName: room.sellerName,
      buyers: buyerSummaries,
      grandTotal: grandTotal,
      totalItemsSold: totalItemsSold,
      totalItems: items.length,
      generatedAt: DateTime.now().toUtc(),
    );
  }
}
