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

abstract class Item
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Item._({
    this.id,
    required this.roomId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.status,
    this.heldBy,
    this.holdExpiresAt,
  });

  factory Item({
    int? id,
    required int roomId,
    required String name,
    required double price,
    required int quantity,
    required String status,
    String? heldBy,
    DateTime? holdExpiresAt,
  }) = _ItemImpl;

  factory Item.fromJson(Map<String, dynamic> jsonSerialization) {
    return Item(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      name: jsonSerialization['name'] as String,
      price: (jsonSerialization['price'] as num).toDouble(),
      quantity: jsonSerialization['quantity'] as int,
      status: jsonSerialization['status'] as String,
      heldBy: jsonSerialization['heldBy'] as String?,
      holdExpiresAt: jsonSerialization['holdExpiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['holdExpiresAt'],
            ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int roomId;

  String name;

  double price;

  int quantity;

  String status;

  String? heldBy;

  DateTime? holdExpiresAt;

  /// Returns a shallow copy of this [Item]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Item copyWith({
    int? id,
    int? roomId,
    String? name,
    double? price,
    int? quantity,
    String? status,
    String? heldBy,
    DateTime? holdExpiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Item',
      if (id != null) 'id': id,
      'roomId': roomId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
      if (heldBy != null) 'heldBy': heldBy,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Item',
      if (id != null) 'id': id,
      'roomId': roomId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
      if (heldBy != null) 'heldBy': heldBy,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt?.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ItemImpl extends Item {
  _ItemImpl({
    int? id,
    required int roomId,
    required String name,
    required double price,
    required int quantity,
    required String status,
    String? heldBy,
    DateTime? holdExpiresAt,
  }) : super._(
         id: id,
         roomId: roomId,
         name: name,
         price: price,
         quantity: quantity,
         status: status,
         heldBy: heldBy,
         holdExpiresAt: holdExpiresAt,
       );

  /// Returns a shallow copy of this [Item]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Item copyWith({
    Object? id = _Undefined,
    int? roomId,
    String? name,
    double? price,
    int? quantity,
    String? status,
    Object? heldBy = _Undefined,
    Object? holdExpiresAt = _Undefined,
  }) {
    return Item(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      heldBy: heldBy is String? ? heldBy : this.heldBy,
      holdExpiresAt: holdExpiresAt is DateTime?
          ? holdExpiresAt
          : this.holdExpiresAt,
    );
  }
}
