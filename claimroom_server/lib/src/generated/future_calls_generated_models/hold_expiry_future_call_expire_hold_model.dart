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
import 'package:serverpod/serverpod.dart' as _is;

abstract class HoldExpiryFutureCallExpireHoldModel
    implements _is.SerializableModel, _is.ProtocolSerialization {
  HoldExpiryFutureCallExpireHoldModel._({required this.itemId});

  factory HoldExpiryFutureCallExpireHoldModel({required int itemId}) =
      _HoldExpiryFutureCallExpireHoldModelImpl;

  factory HoldExpiryFutureCallExpireHoldModel.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return HoldExpiryFutureCallExpireHoldModel(
      itemId: jsonSerialization['itemId'] as int,
    );
  }

  int itemId;

  /// Returns a shallow copy of this [HoldExpiryFutureCallExpireHoldModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  HoldExpiryFutureCallExpireHoldModel copyWith({int? itemId});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'HoldExpiryFutureCallExpireHoldModel',
      'itemId': itemId,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _HoldExpiryFutureCallExpireHoldModelImpl
    extends HoldExpiryFutureCallExpireHoldModel {
  _HoldExpiryFutureCallExpireHoldModelImpl({required int itemId})
    : super._(itemId: itemId);

  /// Returns a shallow copy of this [HoldExpiryFutureCallExpireHoldModel]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  HoldExpiryFutureCallExpireHoldModel copyWith({int? itemId}) {
    return HoldExpiryFutureCallExpireHoldModel(itemId: itemId ?? this.itemId);
  }
}
