import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class RoomEndpoint extends Endpoint {
  static const _letters = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _newCode() {
    final rnd = Random.secure();
    return List.generate(5, (_) => _letters[rnd.nextInt(_letters.length)])
        .join();
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
          title: title,
          sellerName: sellerName,
          isOpen: true,
          createdAt: DateTime.now(),
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
      where: (t) => t.code.equals(code.toUpperCase()),
    );
  }

  /// Seller adds one product to a room.
  Future<Item> addItem(
    Session session,
    int roomId,
    String name,
    double price,
  ) async {
    final item = Item(
      roomId: roomId,
      name: name,
      price: price,
      quantity: 1,
      status: 'available',
    );
    return await Item.db.insertRow(session, item);
  }

  /// Everyone in the room reads the current items.
  Future<List<Item>> listItems(Session session, int roomId) async {
    return await Item.db.find(
      session,
      where: (t) => t.roomId.equals(roomId),
      orderBy: (t) => t.id,
    );
  }
}