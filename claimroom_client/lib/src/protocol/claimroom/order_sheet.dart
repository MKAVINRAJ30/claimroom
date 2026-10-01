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
import '../claimroom/buyer_order_summary.dart' as _iwmvbw5m;

abstract class OrderSheet
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  OrderSheet._({
    required this.roomId,
    required this.roomTitle,
    required this.sellerName,
    required this.buyers,
    required this.grandTotal,
    double? totalPaid,
    double? totalUnpaid,
    required this.totalItemsSold,
    required this.totalItems,
    required this.generatedAt,
  }) : totalPaid = totalPaid ?? 0.0,
       totalUnpaid = totalUnpaid ?? 0.0;

  factory OrderSheet({
    required int roomId,
    required String roomTitle,
    required String sellerName,
    required List<_iwmvbw5m.BuyerOrderSummary> buyers,
    required double grandTotal,
    double? totalPaid,
    double? totalUnpaid,
    required int totalItemsSold,
    required int totalItems,
    required DateTime generatedAt,
  }) = _OrderSheetImpl;

  factory OrderSheet.fromJson(Map<String, dynamic> jsonSerialization) {
    return OrderSheet(
      roomId: jsonSerialization['roomId'] as int,
      roomTitle: jsonSerialization['roomTitle'] as String,
      sellerName: jsonSerialization['sellerName'] as String,
      buyers: _i805zd29.Protocol()
          .deserialize<List<_iwmvbw5m.BuyerOrderSummary>>(
            jsonSerialization['buyers'],
          ),
      grandTotal: (jsonSerialization['grandTotal'] as num).toDouble(),
      totalPaid: (jsonSerialization['totalPaid'] as num?)?.toDouble(),
      totalUnpaid: (jsonSerialization['totalUnpaid'] as num?)?.toDouble(),
      totalItemsSold: jsonSerialization['totalItemsSold'] as int,
      totalItems: jsonSerialization['totalItems'] as int,
      generatedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['generatedAt'],
      ),
    );
  }

  int roomId;

  String roomTitle;

  String sellerName;

  List<_iwmvbw5m.BuyerOrderSummary> buyers;

  double grandTotal;

  double totalPaid;

  double totalUnpaid;

  int totalItemsSold;

  int totalItems;

  DateTime generatedAt;

  /// Returns a shallow copy of this [OrderSheet]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  OrderSheet copyWith({
    int? roomId,
    String? roomTitle,
    String? sellerName,
    List<_iwmvbw5m.BuyerOrderSummary>? buyers,
    double? grandTotal,
    double? totalPaid,
    double? totalUnpaid,
    int? totalItemsSold,
    int? totalItems,
    DateTime? generatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'OrderSheet',
      'roomId': roomId,
      'roomTitle': roomTitle,
      'sellerName': sellerName,
      'buyers': buyers.toJson(valueToJson: (v) => v.toJson()),
      'grandTotal': grandTotal,
      'totalPaid': totalPaid,
      'totalUnpaid': totalUnpaid,
      'totalItemsSold': totalItemsSold,
      'totalItems': totalItems,
      'generatedAt': generatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'OrderSheet',
      'roomId': roomId,
      'roomTitle': roomTitle,
      'sellerName': sellerName,
      'buyers': buyers.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      'grandTotal': grandTotal,
      'totalPaid': totalPaid,
      'totalUnpaid': totalUnpaid,
      'totalItemsSold': totalItemsSold,
      'totalItems': totalItems,
      'generatedAt': generatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _OrderSheetImpl extends OrderSheet {
  _OrderSheetImpl({
    required int roomId,
    required String roomTitle,
    required String sellerName,
    required List<_iwmvbw5m.BuyerOrderSummary> buyers,
    required double grandTotal,
    double? totalPaid,
    double? totalUnpaid,
    required int totalItemsSold,
    required int totalItems,
    required DateTime generatedAt,
  }) : super._(
         roomId: roomId,
         roomTitle: roomTitle,
         sellerName: sellerName,
         buyers: buyers,
         grandTotal: grandTotal,
         totalPaid: totalPaid,
         totalUnpaid: totalUnpaid,
         totalItemsSold: totalItemsSold,
         totalItems: totalItems,
         generatedAt: generatedAt,
       );

  /// Returns a shallow copy of this [OrderSheet]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  OrderSheet copyWith({
    int? roomId,
    String? roomTitle,
    String? sellerName,
    List<_iwmvbw5m.BuyerOrderSummary>? buyers,
    double? grandTotal,
    double? totalPaid,
    double? totalUnpaid,
    int? totalItemsSold,
    int? totalItems,
    DateTime? generatedAt,
  }) {
    return OrderSheet(
      roomId: roomId ?? this.roomId,
      roomTitle: roomTitle ?? this.roomTitle,
      sellerName: sellerName ?? this.sellerName,
      buyers: buyers ?? this.buyers.map((e0) => e0.copyWith()).toList(),
      grandTotal: grandTotal ?? this.grandTotal,
      totalPaid: totalPaid ?? this.totalPaid,
      totalUnpaid: totalUnpaid ?? this.totalUnpaid,
      totalItemsSold: totalItemsSold ?? this.totalItemsSold,
      totalItems: totalItems ?? this.totalItems,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
