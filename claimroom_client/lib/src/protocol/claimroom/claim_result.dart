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

abstract class ClaimResult
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ClaimResult._({
    required this.success,
    required this.message,
    this.item,
  });

  factory ClaimResult({
    required bool success,
    required String message,
    _i5bdkz8n.Item? item,
  }) = _ClaimResultImpl;

  factory ClaimResult.fromJson(Map<String, dynamic> jsonSerialization) {
    return ClaimResult(
      success: _isc.BoolJsonExtension.fromJson(jsonSerialization['success']),
      message: jsonSerialization['message'] as String,
      item: jsonSerialization['item'] == null
          ? null
          : _i805zd29.Protocol().deserialize<_i5bdkz8n.Item>(
              jsonSerialization['item'],
            ),
    );
  }

  bool success;

  String message;

  _i5bdkz8n.Item? item;

  /// Returns a shallow copy of this [ClaimResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ClaimResult copyWith({
    bool? success,
    String? message,
    _i5bdkz8n.Item? item,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ClaimResult',
      'success': success,
      'message': message,
      if (item != null) 'item': item?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ClaimResult',
      'success': success,
      'message': message,
      if (item != null) 'item': item?.toJsonForProtocol(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ClaimResultImpl extends ClaimResult {
  _ClaimResultImpl({
    required bool success,
    required String message,
    _i5bdkz8n.Item? item,
  }) : super._(
         success: success,
         message: message,
         item: item,
       );

  /// Returns a shallow copy of this [ClaimResult]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ClaimResult copyWith({
    bool? success,
    String? message,
    Object? item = _Undefined,
  }) {
    return ClaimResult(
      success: success ?? this.success,
      message: message ?? this.message,
      item: item is _i5bdkz8n.Item? ? item : this.item?.copyWith(),
    );
  }
}
