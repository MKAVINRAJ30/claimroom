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
import 'package:claimroom_client/src/protocol/protocol.dart' as _i805zd29;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../claimroom/item.dart' as _i5bdkz8n;

abstract class BuyerOrderSummary
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  BuyerOrderSummary._({
    required this.buyerName,
    this.buyerContact,
    required this.items,
    required this.totalAmount,
    required this.itemCount,
  });

  factory BuyerOrderSummary({
    required String buyerName,
    String? buyerContact,
    required List<_i5bdkz8n.Item> items,
    required double totalAmount,
    required int itemCount,
  }) = _BuyerOrderSummaryImpl;

  factory BuyerOrderSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return BuyerOrderSummary(
      buyerName: jsonSerialization['buyerName'] as String,
      buyerContact: jsonSerialization['buyerContact'] as String?,
      items: _i805zd29.Protocol().deserialize<List<_i5bdkz8n.Item>>(
        jsonSerialization['items'],
      ),
      totalAmount: (jsonSerialization['totalAmount'] as num).toDouble(),
      itemCount: jsonSerialization['itemCount'] as int,
    );
  }

  String buyerName;

  String? buyerContact;

  List<_i5bdkz8n.Item> items;

  double totalAmount;

  int itemCount;

  /// Returns a shallow copy of this [BuyerOrderSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  BuyerOrderSummary copyWith({
    String? buyerName,
    String? buyerContact,
    List<_i5bdkz8n.Item>? items,
    double? totalAmount,
    int? itemCount,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'BuyerOrderSummary',
      'buyerName': buyerName,
      if (buyerContact != null) 'buyerContact': buyerContact,
      'items': items.toJson(valueToJson: (v) => v.toJson()),
      'totalAmount': totalAmount,
      'itemCount': itemCount,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'BuyerOrderSummary',
      'buyerName': buyerName,
      if (buyerContact != null) 'buyerContact': buyerContact,
      'items': items.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'totalAmount': totalAmount,
      'itemCount': itemCount,
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BuyerOrderSummaryImpl extends BuyerOrderSummary {
  _BuyerOrderSummaryImpl({
    required String buyerName,
    String? buyerContact,
    required List<_i5bdkz8n.Item> items,
    required double totalAmount,
    required int itemCount,
  }) : super._(
         buyerName: buyerName,
         buyerContact: buyerContact,
         items: items,
         totalAmount: totalAmount,
         itemCount: itemCount,
       );

  /// Returns a shallow copy of this [BuyerOrderSummary]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  BuyerOrderSummary copyWith({
    String? buyerName,
    Object? buyerContact = _Undefined,
    List<_i5bdkz8n.Item>? items,
    double? totalAmount,
    int? itemCount,
  }) {
    return BuyerOrderSummary(
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact is String? ? buyerContact : this.buyerContact,
      items: items ?? this.items.map((e0) => e0.copyWith()).toList(),
      totalAmount: totalAmount ?? this.totalAmount,
      itemCount: itemCount ?? this.itemCount,
    );
  }
}
