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

abstract class WaitlistPosition
    implements _is.SerializableModel, _is.ProtocolSerialization {
  WaitlistPosition._({
    required this.itemId,
    required this.position,
  });

  factory WaitlistPosition({
    required int itemId,
    required int position,
  }) = _WaitlistPositionImpl;

  factory WaitlistPosition.fromJson(Map<String, dynamic> jsonSerialization) {
    return WaitlistPosition(
      itemId: jsonSerialization['itemId'] as int,
      position: jsonSerialization['position'] as int,
    );
  }

  int itemId;

  int position;

  /// Returns a shallow copy of this [WaitlistPosition]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WaitlistPosition copyWith({
    int? itemId,
    int? position,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WaitlistPosition',
      'itemId': itemId,
      'position': position,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WaitlistPosition',
      'itemId': itemId,
      'position': position,
    };
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _WaitlistPositionImpl extends WaitlistPosition {
  _WaitlistPositionImpl({
    required int itemId,
    required int position,
  }) : super._(
         itemId: itemId,
         position: position,
       );

  /// Returns a shallow copy of this [WaitlistPosition]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WaitlistPosition copyWith({
    int? itemId,
    int? position,
  }) {
    return WaitlistPosition(
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
    );
  }
}
