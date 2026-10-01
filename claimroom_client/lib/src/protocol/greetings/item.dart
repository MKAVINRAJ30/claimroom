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
    bool? paid,
    this.imageUrl,
    this.heldBy,
    this.heldByContact,
    this.heldByToken,
    this.holdExpiresAt,
    this.soldTo,
    this.soldToContact,
    this.soldToToken,
    this.soldAt,
  }) : paid = paid ?? false;

  factory Item({
    int? id,
    required int roomId,
    required String name,
    required double price,
    required int quantity,
    required String status,
    bool? paid,
    String? imageUrl,
    String? heldBy,
    String? heldByContact,
    String? heldByToken,
    DateTime? holdExpiresAt,
    String? soldTo,
    String? soldToContact,
    String? soldToToken,
    DateTime? soldAt,
  }) = _ItemImpl;

  factory Item.fromJson(Map<String, dynamic> jsonSerialization) {
    return Item(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      name: jsonSerialization['name'] as String,
      price: (jsonSerialization['price'] as num).toDouble(),
      quantity: jsonSerialization['quantity'] as int,
      status: jsonSerialization['status'] as String,
      paid: jsonSerialization['paid'] == null
          ? null
          : _isc.BoolJsonExtension.fromJson(jsonSerialization['paid']),
      imageUrl: jsonSerialization['imageUrl'] as String?,
      heldBy: jsonSerialization['heldBy'] as String?,
      heldByContact: jsonSerialization['heldByContact'] as String?,
      heldByToken: jsonSerialization['heldByToken'] as String?,
      holdExpiresAt: jsonSerialization['holdExpiresAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(
              jsonSerialization['holdExpiresAt'],
            ),
      soldTo: jsonSerialization['soldTo'] as String?,
      soldToContact: jsonSerialization['soldToContact'] as String?,
      soldToToken: jsonSerialization['soldToToken'] as String?,
      soldAt: jsonSerialization['soldAt'] == null
          ? null
          : _isc.DateTimeJsonExtension.fromJson(jsonSerialization['soldAt']),
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

  bool paid;

  String? imageUrl;

  String? heldBy;

  String? heldByContact;

  String? heldByToken;

  DateTime? holdExpiresAt;

  String? soldTo;

  String? soldToContact;

  String? soldToToken;

  DateTime? soldAt;

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
    bool? paid,
    String? imageUrl,
    String? heldBy,
    String? heldByContact,
    String? heldByToken,
    DateTime? holdExpiresAt,
    String? soldTo,
    String? soldToContact,
    String? soldToToken,
    DateTime? soldAt,
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
      'paid': paid,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (heldBy != null) 'heldBy': heldBy,
      if (heldByContact != null) 'heldByContact': heldByContact,
      if (heldByToken != null) 'heldByToken': heldByToken,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt?.toJson(),
      if (soldTo != null) 'soldTo': soldTo,
      if (soldToContact != null) 'soldToContact': soldToContact,
      if (soldToToken != null) 'soldToToken': soldToToken,
      if (soldAt != null) 'soldAt': soldAt?.toJson(),
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
      'paid': paid,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (heldBy != null) 'heldBy': heldBy,
      if (heldByContact != null) 'heldByContact': heldByContact,
      if (heldByToken != null) 'heldByToken': heldByToken,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt?.toJson(),
      if (soldTo != null) 'soldTo': soldTo,
      if (soldToContact != null) 'soldToContact': soldToContact,
      if (soldToToken != null) 'soldToToken': soldToToken,
      if (soldAt != null) 'soldAt': soldAt?.toJson(),
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
    bool? paid,
    String? imageUrl,
    String? heldBy,
    String? heldByContact,
    String? heldByToken,
    DateTime? holdExpiresAt,
    String? soldTo,
    String? soldToContact,
    String? soldToToken,
    DateTime? soldAt,
  }) : super._(
         id: id,
         roomId: roomId,
         name: name,
         price: price,
         quantity: quantity,
         status: status,
         paid: paid,
         imageUrl: imageUrl,
         heldBy: heldBy,
         heldByContact: heldByContact,
         heldByToken: heldByToken,
         holdExpiresAt: holdExpiresAt,
         soldTo: soldTo,
         soldToContact: soldToContact,
         soldToToken: soldToToken,
         soldAt: soldAt,
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
    bool? paid,
    Object? imageUrl = _Undefined,
    Object? heldBy = _Undefined,
    Object? heldByContact = _Undefined,
    Object? heldByToken = _Undefined,
    Object? holdExpiresAt = _Undefined,
    Object? soldTo = _Undefined,
    Object? soldToContact = _Undefined,
    Object? soldToToken = _Undefined,
    Object? soldAt = _Undefined,
  }) {
    return Item(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      paid: paid ?? this.paid,
      imageUrl: imageUrl is String? ? imageUrl : this.imageUrl,
      heldBy: heldBy is String? ? heldBy : this.heldBy,
      heldByContact: heldByContact is String?
          ? heldByContact
          : this.heldByContact,
      heldByToken: heldByToken is String? ? heldByToken : this.heldByToken,
      holdExpiresAt: holdExpiresAt is DateTime?
          ? holdExpiresAt
          : this.holdExpiresAt,
      soldTo: soldTo is String? ? soldTo : this.soldTo,
      soldToContact: soldToContact is String?
          ? soldToContact
          : this.soldToContact,
      soldToToken: soldToToken is String? ? soldToToken : this.soldToToken,
      soldAt: soldAt is DateTime? ? soldAt : this.soldAt,
    );
  }
}
