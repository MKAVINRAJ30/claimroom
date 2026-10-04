/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _ida;
import 'package:claimroom_client/src/protocol/claimroom/claim_result.dart'
    as _i64ozq20;
import 'package:claimroom_client/src/protocol/claimroom/item.dart' as _il26i9sg;
import 'package:claimroom_client/src/protocol/claimroom/order_sheet.dart'
    as _i9f5dsxj;
import 'package:claimroom_client/src/protocol/claimroom/report.dart'
    as _i824jgjh;
import 'package:claimroom_client/src/protocol/claimroom/room.dart' as _if1qb44m;
import 'package:claimroom_client/src/protocol/claimroom/room_event.dart'
    as _i0ir7zxv;
import 'package:claimroom_client/src/protocol/claimroom/waitlist_position.dart'
    as _if63lzm7;
import 'package:http/http.dart' as _i85jenna;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// {@category Endpoint}
class EndpointRoom extends _isc.EndpointRef {
  EndpointRoom(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'room';

  /// Seller creates a room and gets back its join code and unique sellerKey.
  _ida.Future<_if1qb44m.Room> createRoom(
    String title,
    String sellerName,
  ) => caller.callServerEndpoint<_if1qb44m.Room>(
    'room',
    'createRoom',
    {
      'title': title,
      'sellerName': sellerName,
    },
  );

  /// Buyers use this to join with a code.
  /// sellerKey is stripped to ensure buyers never receive it.
  _ida.Future<_if1qb44m.Room?> getRoomByCode(String code) =>
      caller.callServerEndpoint<_if1qb44m.Room?>(
        'room',
        'getRoomByCode',
        {'code': code},
      );

  /// Returning sellers use this to verify their sellerKey and rejoin the room.
  _ida.Future<_if1qb44m.Room?> verifySellerKey(
    String code,
    String sellerKey,
  ) => caller.callServerEndpoint<_if1qb44m.Room?>(
    'room',
    'verifySellerKey',
    {
      'code': code,
      'sellerKey': sellerKey,
    },
  );

  /// Get room by its ID. sellerKey is stripped for safety.
  _ida.Future<_if1qb44m.Room?> getRoom(int roomId) =>
      caller.callServerEndpoint<_if1qb44m.Room?>(
        'room',
        'getRoom',
        {'roomId': roomId},
      );

  /// Seller can open or close claiming in the room. Requires sellerKey.
  _ida.Future<_if1qb44m.Room> toggleRoomStatus(
    int roomId,
    String sellerKey,
    bool isOpen,
  ) => caller.callServerEndpoint<_if1qb44m.Room>(
    'room',
    'toggleRoomStatus',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
      'isOpen': isOpen,
    },
  );

  /// Seller adds one product to a room. Requires sellerKey.
  _ida.Future<_il26i9sg.Item> addItem(
    int roomId,
    String sellerKey,
    String name,
    double price,
    int quantity, {
    String? imageUrl,
  }) => caller.callServerEndpoint<_il26i9sg.Item>(
    'room',
    'addItem',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
      'name': name,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
    },
  );

  /// Seller removes an available item. Requires sellerKey.
  /// Wrapped in a transaction with LockMode.forUpdate to prevent race conditions.
  _ida.Future<bool> deleteItem(
    int itemId,
    String sellerKey,
  ) => caller.callServerEndpoint<bool>(
    'room',
    'deleteItem',
    {
      'itemId': itemId,
      'sellerKey': sellerKey,
    },
  );

  /// Seller marks an item as paid/unpaid in the order sheet. Requires sellerKey.
  _ida.Future<_il26i9sg.Item> markPaid(
    int itemId,
    String sellerKey,
    bool paid,
  ) => caller.callServerEndpoint<_il26i9sg.Item>(
    'room',
    'markPaid',
    {
      'itemId': itemId,
      'sellerKey': sellerKey,
      'paid': paid,
    },
  );

  /// Seller ends the live sale: closes the room, automatically releases any
  /// unconfirmed holds, and broadcasts sale_ended. Requires sellerKey.
  /// Performed inside a single database transaction with LockMode.forUpdate on held items.
  _ida.Future<_if1qb44m.Room> endSale(
    int roomId,
    String sellerKey,
  ) => caller.callServerEndpoint<_if1qb44m.Room>(
    'room',
    'endSale',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
    },
  );

  /// Everyone in the room reads the current items.
  /// Sweeps expired holds first, then returns items with private contact fields sanitized.
  _ida.Future<List<_il26i9sg.Item>> listItems(int roomId) =>
      caller.callServerEndpoint<List<_il26i9sg.Item>>(
        'room',
        'listItems',
        {'roomId': roomId},
      );

  /// Real-time event stream for the room.
  /// Clients subscribe to this stream to receive instant updates when
  /// items are added, claimed, held, confirmed, released, or paid.
  _ida.Stream<_i0ir7zxv.RoomEvent> streamRoom(int roomId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i0ir7zxv.RoomEvent>,
        _i0ir7zxv.RoomEvent
      >(
        'room',
        'streamRoom',
        {'roomId': roomId},
        {},
      );

  /// Atomic claim: Buyer taps "Claim".
  /// Uses a database transaction with LockMode.forUpdate to eliminate race conditions.
  /// If two buyers claim simultaneously, PostgreSQL row-level locks ensure only
  /// one succeeds.
  /// Expired holds are treated as available and reset automatically.
  /// Enforces a maximum of 3 simultaneously active holds per buyer token in this room.
  _ida.Future<_i64ozq20.ClaimResult> claimItem(
    int itemId,
    String buyerName,
    String? buyerContact,
    String buyerToken,
  ) => caller.callServerEndpoint<_i64ozq20.ClaimResult>(
    'room',
    'claimItem',
    {
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerContact': buyerContact,
      'buyerToken': buyerToken,
    },
  );

  /// Buyer confirms their claim within the 60-second hold period.
  /// Converts hold state to permanent sold state.
  /// Enforces token match so only the buyer session that held the item can confirm it.
  _ida.Future<_i64ozq20.ClaimResult> confirmClaim(
    int itemId,
    String buyerToken,
  ) => caller.callServerEndpoint<_i64ozq20.ClaimResult>(
    'room',
    'confirmClaim',
    {
      'itemId': itemId,
      'buyerToken': buyerToken,
    },
  );

  /// Buyer cancels or releases a held item back to the room before expiry.
  /// Enforces token match so only the buyer session that held the item can release it.
  /// If waitlisted buyers exist, automatically hands over to the next eligible buyer.
  _ida.Future<_i64ozq20.ClaimResult> releaseClaim(
    int itemId,
    String buyerToken,
  ) => caller.callServerEndpoint<_i64ozq20.ClaimResult>(
    'room',
    'releaseClaim',
    {
      'itemId': itemId,
      'buyerToken': buyerToken,
    },
  );

  /// Seller forces the release of an abandoned hold back to the room before the 60s timer expires.
  /// Requires a valid sellerKey.
  /// Wrapped in a database transaction with LockMode.forUpdate to prevent race conditions.
  /// If waitlisted buyers exist, automatically hands over to the next eligible buyer.
  _ida.Future<_il26i9sg.Item> releaseHoldAsSeller(
    int itemId,
    String sellerKey,
  ) => caller.callServerEndpoint<_il26i9sg.Item>(
    'room',
    'releaseHoldAsSeller',
    {
      'itemId': itemId,
      'sellerKey': sellerKey,
    },
  );

  /// Buyer joins the waitlist for an item currently held or sold by another buyer.
  /// Returns the buyer's 1-indexed position in the waitlist.
  _ida.Future<int> joinWaitlist(
    int roomId,
    int itemId,
    String buyerName,
    String buyerToken,
  ) => caller.callServerEndpoint<int>(
    'room',
    'joinWaitlist',
    {
      'roomId': roomId,
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerToken': buyerToken,
    },
  );

  /// Buyer leaves the waitlist for an item.
  _ida.Future<bool> leaveWaitlist(
    int roomId,
    int itemId,
    String buyerToken,
  ) => caller.callServerEndpoint<bool>(
    'room',
    'leaveWaitlist',
    {
      'roomId': roomId,
      'itemId': itemId,
      'buyerToken': buyerToken,
    },
  );

  /// Returns items and waitlist queue positions for the specified buyer token only.
  _ida.Future<List<_if63lzm7.WaitlistPosition>> getMyWaitlist(
    int roomId,
    String buyerToken,
  ) => caller.callServerEndpoint<List<_if63lzm7.WaitlistPosition>>(
    'room',
    'getMyWaitlist',
    {
      'roomId': roomId,
      'buyerToken': buyerToken,
    },
  );

  /// Generates the complete order sheet for the seller. Requires sellerKey.
  /// Aggregates all confirmed (sold) items grouped by buyer name.
  /// Quantity math: price is per unit, total = price * quantity.
  /// Computes grandTotal, totalPaid, and totalUnpaid.
  _ida.Future<_i9f5dsxj.OrderSheet> getOrderSheet(
    int roomId,
    String sellerKey,
  ) => caller.callServerEndpoint<_i9f5dsxj.OrderSheet>(
    'room',
    'getOrderSheet',
    {
      'roomId': roomId,
      'sellerKey': sellerKey,
    },
  );

  /// Buyer reports a room for suspicious activity, scams, or abuse.
  /// Requires a valid room code and non-empty reason of maximum 500 characters.
  _ida.Future<_i824jgjh.Report> reportRoom(
    String roomCode,
    String reason,
  ) => caller.callServerEndpoint<_i824jgjh.Report>(
    'room',
    'reportRoom',
    {
      'roomCode': roomCode,
      'reason': reason,
    },
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    room = EndpointRoom(this);
    modules = Modules(this);
  }

  late final EndpointRoom room;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {'room': room};

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
