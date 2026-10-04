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
import 'package:serverpod_client/serverpod_client.dart' as _isc;

abstract class WaitlistEntry
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  WaitlistEntry._({
    this.id,
    required this.roomId,
    required this.itemId,
    required this.buyerName,
    required this.buyerToken,
    required this.createdAt,
  });

  factory WaitlistEntry({
    int? id,
    required int roomId,
    required int itemId,
    required String buyerName,
    required String buyerToken,
    required DateTime createdAt,
  }) = _WaitlistEntryImpl;

  factory WaitlistEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return WaitlistEntry(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      itemId: jsonSerialization['itemId'] as int,
      buyerName: jsonSerialization['buyerName'] as String,
      buyerToken: jsonSerialization['buyerToken'] as String,
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  int itemId;

  String buyerName;

  String buyerToken;

  DateTime createdAt;

  /// Returns a shallow copy of this [WaitlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  WaitlistEntry copyWith({
    int? id,
    int? roomId,
    int? itemId,
    String? buyerName,
    String? buyerToken,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WaitlistEntry',
      if (id != null) 'id': id,
      'roomId': roomId,
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerToken': buyerToken,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WaitlistEntry',
      if (id != null) 'id': id,
      'roomId': roomId,
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerToken': buyerToken,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WaitlistEntryImpl extends WaitlistEntry {
  _WaitlistEntryImpl({
    int? id,
    required int roomId,
    required int itemId,
    required String buyerName,
    required String buyerToken,
    required DateTime createdAt,
  }) : super._(
         id: id,
         roomId: roomId,
         itemId: itemId,
         buyerName: buyerName,
         buyerToken: buyerToken,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WaitlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  WaitlistEntry copyWith({
    Object? id = _Undefined,
    int? roomId,
    int? itemId,
    String? buyerName,
    String? buyerToken,
    DateTime? createdAt,
  }) {
    return WaitlistEntry(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      itemId: itemId ?? this.itemId,
      buyerName: buyerName ?? this.buyerName,
      buyerToken: buyerToken ?? this.buyerToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
