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
import 'package:claimroom_server/src/generated/protocol.dart' as _ix13sr6n;
import 'package:serverpod/serverpod.dart' as _is;
import '../claimroom/item.dart' as _i5bdkz8n;

abstract class RoomEvent
    implements _is.SerializableModel, _is.ProtocolSerialization {
  RoomEvent._({
    required this.roomId,
    required this.type,
    this.item,
    this.message,
    required this.timestamp,
  });

  factory RoomEvent({
    required int roomId,
    required String type,
    _i5bdkz8n.Item? item,
    String? message,
    required DateTime timestamp,
  }) = _RoomEventImpl;

  factory RoomEvent.fromJson(Map<String, dynamic> jsonSerialization) {
    return RoomEvent(
      roomId: jsonSerialization['roomId'] as int,
      type: jsonSerialization['type'] as String,
      item: jsonSerialization['item'] == null
          ? null
          : _ix13sr6n.Protocol().deserialize<_i5bdkz8n.Item>(
              jsonSerialization['item'],
            ),
      message: jsonSerialization['message'] as String?,
      timestamp: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['timestamp'],
      ),
    );
  }

  int roomId;

  String type;

  _i5bdkz8n.Item? item;

  String? message;

  DateTime timestamp;

  /// Returns a shallow copy of this [RoomEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  RoomEvent copyWith({
    int? roomId,
    String? type,
    _i5bdkz8n.Item? item,
    String? message,
    DateTime? timestamp,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'RoomEvent',
      'roomId': roomId,
      'type': type,
      if (item != null) 'item': item?.toJson(),
      if (message != null) 'message': message,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'RoomEvent',
      'roomId': roomId,
      'type': type,
      if (item != null) 'item': item?.toJsonForProtocol(),
      if (message != null) 'message': message,
      'timestamp': timestamp.toJson(),
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomEventImpl extends RoomEvent {
  _RoomEventImpl({
    required int roomId,
    required String type,
    _i5bdkz8n.Item? item,
    String? message,
    required DateTime timestamp,
  }) : super._(
         roomId: roomId,
         type: type,
         item: item,
         message: message,
         timestamp: timestamp,
       );

  /// Returns a shallow copy of this [RoomEvent]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  RoomEvent copyWith({
    int? roomId,
    String? type,
    Object? item = _Undefined,
    Object? message = _Undefined,
    DateTime? timestamp,
  }) {
    return RoomEvent(
      roomId: roomId ?? this.roomId,
      type: type ?? this.type,
      item: item is _i5bdkz8n.Item? ? item : this.item?.copyWith(),
      message: message is String? ? message : this.message,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
