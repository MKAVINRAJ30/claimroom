import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/future_calls.dart';
import '../generated/protocol.dart';
import 'sanitizer.dart';
import 'hold_helper.dart';

class RoomEndpoint extends Endpoint {
  static const _letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _newCode() {
    final rnd = Random.secure();
    return List.generate(
      5,
      (_) => _letters[rnd.nextInt(_letters.length)],
    ).join();
  }

  String _newSellerKey() {
    final rnd = Random.secure();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789';
    return List.generate(
      16,
      (_) => chars[rnd.nextInt(chars.length)],
    ).join();
  }

  void _verifySellerKey(Room room, String sellerKey) {
    if (room.sellerKey == null || room.sellerKey != sellerKey.trim()) {
      throw ArgumentError('Invalid seller key for this room.');
    }
  }

  /// Seller creates a room and gets back its join code and unique sellerKey.
  Future<Room> createRoom(
    Session session,
    String title,
    String sellerName,
  ) async {
    final trimmedTitle = title.trim();
    final trimmedSellerName = sellerName.trim();
    if (trimmedTitle.isEmpty) {
      throw ArgumentError('Room title cannot be empty.');
    }
    if (trimmedSellerName.isEmpty) {
      throw ArgumentError('Seller name cannot be empty.');
    }

    for (var attempt = 0; attempt < 5; attempt++) {
      try {
        final room = Room(
          code: _newCode(),
          title: trimmedTitle,
          sellerName: trimmedSellerName,
          sellerKey: _newSellerKey(),
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
  /// sellerKey is stripped to ensure buyers never receive it.
  Future<Room?> getRoomByCode(Session session, String code) async {
    final room = await Room.db.findFirstRow(
      session,
      where: (t) => t.code.equals(code.trim().toUpperCase()),
    );
    if (room == null) return null;
    room.sellerKey = null; // Sanitized: buyers never receive sellerKey
    return room;
  }

  /// Returning sellers use this to verify their sellerKey and rejoin the room.
  Future<Room?> verifySellerKey(
    Session session,
    String code,
    String sellerKey,
  ) async {
    final room = await Room.db.findFirstRow(
      session,
      where: (t) => t.code.equals(code.trim().toUpperCase()),
    );
    if (room == null) return null;
    _verifySellerKey(room, sellerKey);
    return room;
  }

  /// Get room by its ID. sellerKey is stripped for safety.
  Future<Room?> getRoom(Session session, int roomId) async {
    final room = await Room.db.findById(session, roomId);
    if (room == null) return null;
    room.sellerKey = null; // Sanitized
    return room;
  }

  /// Seller can open or close claiming in the room. Requires sellerKey.
  Future<Room> toggleRoomStatus(
    Session session,
    int roomId,
    String sellerKey,
    bool isOpen,
  ) async {
    final room = await Room.db.findById(session, roomId);
    if (room == null) throw Exception('Room not found');
    _verifySellerKey(room, sellerKey);

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

    updated.sellerKey = null;
    return updated;
  }

  /// Seller adds one product to a room. Requires sellerKey.
  Future<Item> addItem(
    Session session,
    int roomId,
    String sellerKey,
    String name,
    double price,
    int quantity, {
    String? imageUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Product name cannot be empty.');
    }
    if (price <= 0) {
      throw ArgumentError('Price must be greater than 0.');
    }
    if (quantity < 1 || quantity > 99) {
      throw ArgumentError('Quantity must be between 1 and 99.');
    }

    String? validatedImageUrl;
    if (imageUrl != null) {
      final trimmedUrl = imageUrl.trim();
      if (trimmedUrl.isNotEmpty) {
        if (trimmedUrl.length > 500) {
          throw ArgumentError('Image URL cannot exceed 500 characters.');
        }
        if (!trimmedUrl.startsWith('http://') &&
            !trimmedUrl.startsWith('https://')) {
          throw ArgumentError(
            'Image URL must start with http:// or https://',
          );
        }
        validatedImageUrl = trimmedUrl;
      }
    }

    final room = await Room.db.findById(session, roomId);
    if (room == null) {
      throw ArgumentError('Room with ID $roomId does not exist.');
    }
    _verifySellerKey(room, sellerKey);

    final currentCount = await Item.db.count(
      session,
      where: (t) => t.roomId.equals(roomId),
    );
    if (currentCount >= 50) {
      throw ArgumentError(
        'Room item limit reached: maximum 50 items per room.',
      );
    }

    final item = Item(
      roomId: roomId,
      name: trimmedName,
      price: price,
      quantity: quantity,
      status: 'available',
      paid: false,
      imageUrl: validatedImageUrl,
    );
    final inserted = await Item.db.insertRow(session, item);

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'item_added',
        item: sanitizeItem(inserted),
        message: 'New item added: ${inserted.name}',
        timestamp: DateTime.now().toUtc(),
      ),
    );

    return inserted;
  }

  /// Seller removes an available item. Requires sellerKey.
  /// Wrapped in a transaction with LockMode.forUpdate to prevent race conditions.
  Future<bool> deleteItem(
    Session session,
    int itemId,
    String sellerKey,
  ) async {
    Item? deletedItem;
    int? targetRoomId;

    await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (item == null) {
        throw Exception('Item not found');
      }

      final room = await Room.db.findById(
        session,
        item.roomId,
        transaction: transaction,
      );
      if (room == null) {
        throw Exception('Room not found');
      }
      _verifySellerKey(room, sellerKey);

      if (item.status != 'available') {
        throw Exception(
          'Cannot delete an item that is already held or sold (status: ${item.status})',
        );
      }

      targetRoomId = item.roomId;
      deletedItem = item;
      await WaitlistEntry.db.deleteWhere(
        session,
        where: (t) => t.itemId.equals(itemId),
        transaction: transaction,
      );
      await Item.db.deleteRow(session, item, transaction: transaction);
    });

    if (deletedItem != null && targetRoomId != null) {
      await session.messages.postMessage(
        'room_$targetRoomId',
        RoomEvent(
          roomId: targetRoomId!,
          type: 'item_deleted',
          item: sanitizeItem(deletedItem!),
          message: 'Item removed: ${deletedItem!.name}',
          timestamp: DateTime.now().toUtc(),
        ),
      );
      return true;
    }

    return false;
  }

  /// Seller marks an item as paid/unpaid in the order sheet. Requires sellerKey.
  Future<Item> markPaid(
    Session session,
    int itemId,
    String sellerKey,
    bool paid,
  ) async {
    Item? updatedItem;

    await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (item == null) {
        throw Exception('Item not found');
      }

      final room = await Room.db.findById(
        session,
        item.roomId,
        transaction: transaction,
      );
      if (room == null) {
        throw Exception('Room not found');
      }
      _verifySellerKey(room, sellerKey);

      if (item.status != 'sold') {
        throw ArgumentError(
          'Cannot mark payment: item has not been sold (current status: ${item.status}).',
        );
      }

      item.paid = paid;
      updatedItem = await Item.db.updateRow(
        session,
        item,
        transaction: transaction,
      );
    });

    if (updatedItem != null) {
      await session.messages.postMessage(
        'room_${updatedItem!.roomId}',
        RoomEvent(
          roomId: updatedItem!.roomId,
          type: 'item_paid',
          item: sanitizeItem(updatedItem!),
          message:
              '${updatedItem!.name} marked as ${paid ? "paid" : "unpaid"}.',
          timestamp: DateTime.now().toUtc(),
        ),
      );
      return updatedItem!;
    }

    throw Exception('Failed to update paid status.');
  }

  /// Seller ends the live sale: closes the room, automatically releases any
  /// unconfirmed holds, and broadcasts sale_ended. Requires sellerKey.
  /// Performed inside a single database transaction with LockMode.forUpdate on held items.
  Future<Room> endSale(
    Session session,
    int roomId,
    String sellerKey,
  ) async {
    final List<int> releasedItemIds = [];
    Room? updatedRoom;

    await session.db.transaction((transaction) async {
      final room = await Room.db.findById(
        session,
        roomId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (room == null) throw Exception('Room not found');
      _verifySellerKey(room, sellerKey);

      room.isOpen = false;
      updatedRoom = await Room.db.updateRow(
        session,
        room,
        transaction: transaction,
      );

      // Release all active holds inside this locked transaction
      final heldItems = await Item.db.find(
        session,
        where: (t) => t.roomId.equals(roomId) & t.status.equals('held'),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      for (final item in heldItems) {
        item.status = 'available';
        item.heldBy = null;
        item.heldByContact = null;
        item.heldByToken = null;
        item.holdExpiresAt = null;
        item.waitlistCount = 0;
        await Item.db.updateRow(session, item, transaction: transaction);
        if (item.id != null) {
          releasedItemIds.add(item.id!);
        }
      }

      // Clear all waitlists in this room when the sale ends
      await WaitlistEntry.db.deleteWhere(
        session,
        where: (t) => t.roomId.equals(roomId),
        transaction: transaction,
      );
    });

    // Cancel matching future calls after the transaction completes
    for (final itemId in releasedItemIds) {
      try {
        await session.serverpod.futureCalls.cancel('hold_item_$itemId');
      } catch (e) {
        session.log(
          'Failed to cancel future call for item $itemId: $e',
          level: LogLevel.warning,
        );
      }
    }

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'sale_ended',
        item: null,
        message: 'The sale has ended! Thank you for participating.',
        timestamp: DateTime.now().toUtc(),
      ),
    );

    updatedRoom!.sellerKey = null;
    return updatedRoom!;
  }

  /// Sweeps expired holds in the room inside a single locked transaction,
  /// resetting them or handing them over to the next waitlisted buyer.
  /// After the transaction, broadcasts matching events.
  /// This ensures hold expiry and handovers work even when Serverpod future calls are disabled.
  Future<void> _releaseExpiredHolds(Session session, int roomId) async {
    final List<HoldEndResult> results = [];
    final now = DateTime.now().toUtc();

    await session.db.transaction((transaction) async {
      final expiredHeldItems = await Item.db.find(
        session,
        where: (t) =>
            t.roomId.equals(roomId) &
            t.status.equals('held') &
            t.holdExpiresAt.notEquals(null) &
            (t.holdExpiresAt < now),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      for (final item in expiredHeldItems) {
        final result = await _endHoldAndHandOver(session, transaction, item);
        results.add(result);
      }
    });

    for (final result in results) {
      await _broadcastHoldEnd(session, result);
    }
  }

  /// Everyone in the room reads the current items.
  /// Sweeps expired holds first, then returns items with private contact fields sanitized.
  Future<List<Item>> listItems(Session session, int roomId) async {
    await _releaseExpiredHolds(session, roomId);
    final items = await Item.db.find(
      session,
      where: (t) => t.roomId.equals(roomId),
      orderBy: (t) => t.id,
    );
    for (final item in items) {
      if (item.id != null) {
        item.waitlistCount = await WaitlistEntry.db.count(
          session,
          where: (t) => t.itemId.equals(item.id!),
        );
      }
    }
    return items.map(sanitizeItem).toList();
  }

  /// Real-time event stream for the room.
  /// Clients subscribe to this stream to receive instant updates when
  /// items are added, claimed, held, confirmed, released, or paid.
  Stream<RoomEvent> streamRoom(Session session, int roomId) {
    return session.messages.createStream<RoomEvent>('room_$roomId');
  }

  /// Atomic claim: Buyer taps "Claim".
  /// Uses a database transaction with LockMode.forUpdate to eliminate race conditions.
  /// If two buyers claim simultaneously, PostgreSQL row-level locks ensure only
  /// one succeeds.
  /// Expired holds are treated as available and reset automatically.
  /// Enforces a maximum of 3 simultaneously active holds per buyer token in this room.
  Future<ClaimResult> claimItem(
    Session session,
    int itemId,
    String buyerName,
    String? buyerContact,
    String buyerToken,
  ) async {
    final trimmedName = buyerName.trim();
    final trimmedToken = buyerToken.trim();
    if (trimmedName.isEmpty) {
      return ClaimResult(
        success: false,
        message: 'Please enter your name to claim.',
      );
    }
    if (trimmedToken.isEmpty) {
      return ClaimResult(
        success: false,
        message: 'Invalid buyer session token.',
      );
    }

    final initialItem = await Item.db.findById(session, itemId);
    if (initialItem != null) {
      await _releaseExpiredHolds(session, initialItem.roomId);
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
          item: sanitizeItem(item),
        );
      }

      final now = DateTime.now().toUtc();

      // Check claim limit per buyer token: max 3 simultaneously held items per buyer token in this room.
      // NOTE: The 3-hold check is performed within the item-lock transaction.
      // Two simultaneous claims by the same token on different items could race and both succeed,
      // which is a known minor trade-off to maintain high concurrency without table-level locking.
      final activeHolds = await Item.db.find(
        session,
        where: (t) =>
            t.roomId.equals(item.roomId) &
            t.status.equals('held') &
            t.heldByToken.equals(trimmedToken) &
            (t.holdExpiresAt > now),
        transaction: transaction,
      );

      if (activeHolds.length >= 3) {
        return ClaimResult(
          success: false,
          message: 'Claim limit reached: maximum 3 items held simultaneously.',
          item: sanitizeItem(item),
        );
      }

      final isHoldExpired =
          item.status == 'held' &&
          item.holdExpiresAt != null &&
          item.holdExpiresAt!.isBefore(now);

      if (item.status != 'available' && !isHoldExpired) {
        final currentOwner = item.status == 'held' ? item.heldBy : item.soldTo;
        return ClaimResult(
          success: false,
          message:
              'Already ${item.status} by ${currentOwner ?? "another buyer"}.',
          item: sanitizeItem(item),
        );
      }

      // Claim successfully: place 60-second hold (resets any previous expired hold)
      final holdExpiresAt = now.add(
        const Duration(seconds: 60),
      );
      item.status = 'held';
      item.heldBy = trimmedName;
      item.heldByContact = buyerContact?.trim();
      item.heldByToken = trimmedToken;
      item.holdExpiresAt = holdExpiresAt;

      final updated = await Item.db.updateRow(
        session,
        item,
        transaction: transaction,
      );

      return ClaimResult(
        success: true,
        message: 'Item held for 60s! Confirm before the timer expires.',
        item: updated.copyWith(
          heldByToken: null,
          soldToToken: null,
        ),
      );
    });

    if (result.success && result.item != null) {
      // 1. Schedule automatic release future call
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

      // 2. Broadcast claim event to all connected clients (sanitized)
      await session.messages.postMessage(
        'room_${result.item!.roomId}',
        RoomEvent(
          roomId: result.item!.roomId,
          type: 'item_claimed',
          item: sanitizeItem(result.item!),
          message: '${result.item!.name} claimed by $trimmedName!',
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    return result;
  }

  /// Buyer confirms their claim within the 60-second hold period.
  /// Converts hold state to permanent sold state.
  /// Enforces token match so only the buyer session that held the item can confirm it.
  Future<ClaimResult> confirmClaim(
    Session session,
    int itemId,
    String buyerToken,
  ) async {
    final trimmedToken = buyerToken.trim();

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

      if (item.status != 'held' || item.heldByToken != trimmedToken) {
        return ClaimResult(
          success: false,
          message: 'You do not have an active hold on this item.',
          item: sanitizeItem(item),
        );
      }

      // Check if hold has expired
      final now = DateTime.now().toUtc();
      if (item.holdExpiresAt != null && item.holdExpiresAt!.isBefore(now)) {
        return ClaimResult(
          success: false,
          message: 'Your 60-second hold has expired.',
          item: sanitizeItem(item),
        );
      }

      // Confirm order
      item.status = 'sold';
      item.soldTo = item.heldBy;
      item.soldToContact = item.heldByContact;
      item.soldToToken = item.heldByToken;
      item.soldAt = now;
      item.heldBy = null;
      item.heldByContact = null;
      item.heldByToken = null;
      item.holdExpiresAt = null;
      item.waitlistCount = 0;

      // Clear waitlist for this item when sold
      await WaitlistEntry.db.deleteWhere(
        session,
        where: (t) => t.itemId.equals(itemId),
        transaction: transaction,
      );

      final updated = await Item.db.updateRow(
        session,
        item,
        transaction: transaction,
      );

      return ClaimResult(
        success: true,
        message: 'Order confirmed! Item marked as sold.',
        item: updated.copyWith(
          heldByToken: null,
          soldToToken: null,
        ),
      );
    });

    if (result.success && result.item != null) {
      // Cancel the scheduled expiry future call
      try {
        await session.serverpod.futureCalls.cancel('hold_item_$itemId');
      } catch (e) {
        session.log(
          'Failed to cancel future call for item $itemId: $e',
          level: LogLevel.warning,
        );
      }

      // Broadcast confirmed order to room (sanitized)
      await session.messages.postMessage(
        'room_${result.item!.roomId}',
        RoomEvent(
          roomId: result.item!.roomId,
          type: 'item_confirmed',
          item: sanitizeItem(result.item!),
          message: '${result.item!.name} sold to ${result.item!.soldTo}!',
          timestamp: DateTime.now().toUtc(),
        ),
      );

      // Broadcast waitlist_updated event
      await session.messages.postMessage(
        'room_${result.item!.roomId}',
        RoomEvent(
          roomId: result.item!.roomId,
          type: 'waitlist_updated',
          waitlistItemId: itemId,
          waitlistCount: 0,
          item: null,
          timestamp: DateTime.now().toUtc(),
        ),
      );
    }

    return result;
  }

  /// Buyer cancels or releases a held item back to the room before expiry.
  /// Enforces token match so only the buyer session that held the item can release it.
  /// If waitlisted buyers exist, automatically hands over to the next eligible buyer.
  Future<ClaimResult> releaseClaim(
    Session session,
    int itemId,
    String buyerToken,
  ) async {
    final trimmedToken = buyerToken.trim();

    HoldEndResult? endResult;

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

      if (item.status != 'held' || item.heldByToken != trimmedToken) {
        return ClaimResult(
          success: false,
          message: 'You do not hold this item.',
          item: sanitizeItem(item),
        );
      }

      endResult = await _endHoldAndHandOver(session, transaction, item);

      return ClaimResult(
        success: true,
        message: 'Item released back to the room.',
        item: sanitizeItem(endResult!.item),
      );
    });

    if (endResult != null) {
      await _broadcastHoldEnd(session, endResult!);
    }

    return result;
  }

  /// Seller forces the release of an abandoned hold back to the room before the 60s timer expires.
  /// Requires a valid sellerKey.
  /// Wrapped in a database transaction with LockMode.forUpdate to prevent race conditions.
  /// If waitlisted buyers exist, automatically hands over to the next eligible buyer.
  Future<Item> releaseHoldAsSeller(
    Session session,
    int itemId,
    String sellerKey,
  ) async {
    final item = await Item.db.findById(session, itemId);
    if (item == null) {
      throw ArgumentError('Item not found.');
    }

    final room = await Room.db.findById(session, item.roomId);
    if (room == null) {
      throw ArgumentError('Room not found.');
    }
    _verifySellerKey(room, sellerKey);

    if (item.status != 'held') {
      throw ArgumentError(
        'Cannot release hold: item is not held (status: ${item.status}).',
      );
    }

    HoldEndResult? endResult;

    await session.db.transaction((transaction) async {
      final lockedItem = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (lockedItem == null) {
        throw ArgumentError('Item not found.');
      }

      if (lockedItem.status != 'held') {
        throw ArgumentError(
          'Cannot release hold: item is not held (status: ${lockedItem.status}).',
        );
      }

      endResult = await _endHoldAndHandOver(session, transaction, lockedItem);
    });

    if (endResult != null) {
      await _broadcastHoldEnd(session, endResult!);
    }

    return sanitizeItem(endResult!.item);
  }

  /// Buyer joins the waitlist for an item currently held or sold by another buyer.
  /// Returns the buyer's 1-indexed position in the waitlist.
  Future<int> joinWaitlist(
    Session session,
    int roomId,
    int itemId,
    String buyerName,
    String buyerToken,
  ) async {
    final trimmedName = buyerName.trim();
    final trimmedToken = buyerToken.trim();
    if (trimmedName.isEmpty) {
      throw ArgumentError('Please enter your name to join waitlist.');
    }
    if (trimmedToken.isEmpty) {
      throw ArgumentError('Invalid buyer session token.');
    }

    final room = await Room.db.findById(session, roomId);
    if (room == null || !room.isOpen) {
      throw ArgumentError('The room is closed for waitlists.');
    }

    int position = 0;
    int updatedCount = 0;

    await session.db.transaction((transaction) async {
      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );

      if (item == null || item.roomId != roomId) {
        throw ArgumentError('Item not found in this room.');
      }

      if (item.status != 'held' && item.status != 'sold') {
        throw ArgumentError(
          'Cannot join waitlist for available item. You can claim it directly.',
        );
      }

      final currentHolderToken = item.status == 'held'
          ? item.heldByToken
          : item.soldToToken;

      if (currentHolderToken != null && currentHolderToken == trimmedToken) {
        throw ArgumentError('You already hold or purchased this item.');
      }

      final existing = await WaitlistEntry.db.findFirstRow(
        session,
        where: (t) =>
            t.itemId.equals(itemId) & t.buyerToken.equals(trimmedToken),
        transaction: transaction,
      );
      if (existing != null) {
        throw ArgumentError('You are already on the waitlist for this item.');
      }

      final count = await WaitlistEntry.db.count(
        session,
        where: (t) => t.itemId.equals(itemId),
        transaction: transaction,
      );
      if (count >= 10) {
        throw ArgumentError('Waitlist is full (maximum 10 entries).');
      }

      final entry = WaitlistEntry(
        roomId: roomId,
        itemId: itemId,
        buyerName: trimmedName,
        buyerToken: trimmedToken,
        createdAt: DateTime.now().toUtc(),
      );
      await WaitlistEntry.db.insertRow(
        session,
        entry,
        transaction: transaction,
      );

      updatedCount = count + 1;
      position = updatedCount;

      item.waitlistCount = updatedCount;
      await Item.db.updateRow(session, item, transaction: transaction);
    });

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'waitlist_updated',
        waitlistItemId: itemId,
        waitlistCount: updatedCount,
        item: null,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    return position;
  }

  /// Buyer leaves the waitlist for an item.
  Future<bool> leaveWaitlist(
    Session session,
    int roomId,
    int itemId,
    String buyerToken,
  ) async {
    final trimmedToken = buyerToken.trim();
    if (trimmedToken.isEmpty) {
      throw ArgumentError('Invalid buyer session token.');
    }

    int remainingCount = 0;

    await session.db.transaction((transaction) async {
      await WaitlistEntry.db.deleteWhere(
        session,
        where: (t) =>
            t.itemId.equals(itemId) & t.buyerToken.equals(trimmedToken),
        transaction: transaction,
      );

      remainingCount = await WaitlistEntry.db.count(
        session,
        where: (t) => t.itemId.equals(itemId),
        transaction: transaction,
      );

      final item = await Item.db.findById(
        session,
        itemId,
        transaction: transaction,
        lockMode: LockMode.forUpdate,
      );
      if (item != null) {
        item.waitlistCount = remainingCount;
        await Item.db.updateRow(session, item, transaction: transaction);
      }
    });

    await session.messages.postMessage(
      'room_$roomId',
      RoomEvent(
        roomId: roomId,
        type: 'waitlist_updated',
        waitlistItemId: itemId,
        waitlistCount: remainingCount,
        item: null,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    return true;
  }

  /// Returns items and waitlist queue positions for the specified buyer token only.
  Future<List<WaitlistPosition>> getMyWaitlist(
    Session session,
    int roomId,
    String buyerToken,
  ) async {
    final trimmedToken = buyerToken.trim();
    if (trimmedToken.isEmpty) {
      return [];
    }

    final myEntries = await WaitlistEntry.db.find(
      session,
      where: (t) => t.roomId.equals(roomId) & t.buyerToken.equals(trimmedToken),
    );

    final List<WaitlistPosition> result = [];
    for (final myEntry in myEntries) {
      final allEntries = await WaitlistEntry.db.find(
        session,
        where: (t) => t.itemId.equals(myEntry.itemId),
        orderBy: (t) => t.createdAt,
      );
      final idx = allEntries.indexWhere((e) => e.buyerToken == trimmedToken);
      if (idx != -1) {
        result.add(
          WaitlistPosition(
            itemId: myEntry.itemId,
            position: idx + 1,
          ),
        );
      }
    }

    return result;
  }

  Future<HoldEndResult> _endHoldAndHandOver(
    Session session,
    Transaction transaction,
    Item item,
  ) => HoldHelper.endHoldAndHandOver(session, transaction, item);

  Future<void> _broadcastHoldEnd(
    Session session,
    HoldEndResult result,
  ) => HoldHelper.broadcastHoldEnd(session, result);

  /// Generates the complete order sheet for the seller. Requires sellerKey.
  /// Aggregates all confirmed (sold) items grouped by buyer name.
  /// Quantity math: price is per unit, total = price * quantity.
  /// Computes grandTotal, totalPaid, and totalUnpaid.
  Future<OrderSheet> getOrderSheet(
    Session session,
    int roomId,
    String sellerKey,
  ) async {
    await _releaseExpiredHolds(session, roomId);

    final room = await Room.db.findById(session, roomId);
    if (room == null) throw Exception('Room not found');
    _verifySellerKey(room, sellerKey);

    final items = await Item.db.find(
      session,
      where: (t) => t.roomId.equals(roomId),
      orderBy: (t) => t.id,
    );

    final Map<String, List<Item>> buyerItemsMap = {};
    final Map<String, String?> buyerContactMap = {};

    double grandTotal = 0.0;
    double totalPaid = 0.0;
    double totalUnpaid = 0.0;
    int totalItemsSold = 0;

    for (final item in items) {
      if (item.status == 'sold' && item.soldTo != null) {
        final buyer = item.soldTo!;
        buyerItemsMap.putIfAbsent(buyer, () => []).add(item);
        if (item.soldToContact != null && item.soldToContact!.isNotEmpty) {
          buyerContactMap[buyer] = item.soldToContact;
        }
        final itemTotal = item.price * item.quantity;
        grandTotal += itemTotal;
        if (item.paid) {
          totalPaid += itemTotal;
        } else {
          totalUnpaid += itemTotal;
        }
        totalItemsSold += item.quantity;
      }
    }

    final buyerSummaries = buyerItemsMap.entries.map((entry) {
      final buyer = entry.key;
      final bItems = entry.value;
      final total = bItems.fold<double>(
        0.0,
        (sum, i) => sum + (i.price * i.quantity),
      );
      final count = bItems.fold<int>(0, (sum, i) => sum + i.quantity);
      return BuyerOrderSummary(
        buyerName: buyer,
        buyerContact: buyerContactMap[buyer],
        items: bItems
            .map((i) => i.copyWith(heldByToken: null, soldToToken: null))
            .toList(),
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
      totalPaid: totalPaid,
      totalUnpaid: totalUnpaid,
      totalItemsSold: totalItemsSold,
      totalItems: items.length,
      generatedAt: DateTime.now().toUtc(),
    );
  }

  /// Buyer reports a room for suspicious activity, scams, or abuse.
  /// Requires a valid room code and non-empty reason of maximum 500 characters.
  Future<Report> reportRoom(
    Session session,
    String roomCode,
    String reason,
  ) async {
    final trimmedCode = roomCode.trim().toUpperCase();
    final trimmedReason = reason.trim();

    if (trimmedCode.isEmpty) {
      throw ArgumentError('Room code cannot be empty.');
    }
    if (trimmedReason.isEmpty) {
      throw ArgumentError('Report reason cannot be empty.');
    }
    if (trimmedReason.length > 500) {
      throw ArgumentError('Report reason cannot exceed 500 characters.');
    }

    final room = await Room.db.findFirstRow(
      session,
      where: (t) => t.code.equals(trimmedCode),
    );
    if (room == null) {
      throw ArgumentError('Room not found for code $trimmedCode.');
    }

    final report = Report(
      roomId: room.id!,
      reason: trimmedReason,
      createdAt: DateTime.now().toUtc(),
    );

    return await Report.db.insertRow(session, report);
  }
}
