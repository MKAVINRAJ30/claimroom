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
import '../greetings/item.dart' as _iz9csdid;

abstract class BuyerOrderSummary
    implements _is.SerializableModel, _is.ProtocolSerialization {
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
    required List<_iz9csdid.Item> items,
    required double totalAmount,
    required int itemCount,
  }) = _BuyerOrderSummaryImpl;

  factory BuyerOrderSummary.fromJson(Map<String, dynamic> jsonSerialization) {
    return BuyerOrderSummary(
      buyerName: jsonSerialization['buyerName'] as String,
      buyerContact: jsonSerialization['buyerContact'] as String?,
      items: _ix13sr6n.Protocol().deserialize<List<_iz9csdid.Item>>(
        jsonSerialization['items'],
      ),
      totalAmount: (jsonSerialization['totalAmount'] as num).toDouble(),
      itemCount: jsonSerialization['itemCount'] as int,
    );
  }

  String buyerName;

  String? buyerContact;

  List<_iz9csdid.Item> items;

  double totalAmount;

  int itemCount;

  /// Returns a shallow copy of this [BuyerOrderSummary]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  BuyerOrderSummary copyWith({
    String? buyerName,
    String? buyerContact,
    List<_iz9csdid.Item>? items,
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
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _BuyerOrderSummaryImpl extends BuyerOrderSummary {
  _BuyerOrderSummaryImpl({
    required String buyerName,
    String? buyerContact,
    required List<_iz9csdid.Item> items,
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
  @_is.useResult
  @override
  BuyerOrderSummary copyWith({
    String? buyerName,
    Object? buyerContact = _Undefined,
    List<_iz9csdid.Item>? items,
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
