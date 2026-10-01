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

abstract class Report
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Report._({
    this.id,
    required this.roomId,
    required this.reason,
    required this.createdAt,
  });

  factory Report({
    int? id,
    required int roomId,
    required String reason,
    required DateTime createdAt,
  }) = _ReportImpl;

  factory Report.fromJson(Map<String, dynamic> jsonSerialization) {
    return Report(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      reason: jsonSerialization['reason'] as String,
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

  String reason;

  DateTime createdAt;

  /// Returns a shallow copy of this [Report]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Report copyWith({
    int? id,
    int? roomId,
    String? reason,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Report',
      if (id != null) 'id': id,
      'roomId': roomId,
      'reason': reason,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Report',
      if (id != null) 'id': id,
      'roomId': roomId,
      'reason': reason,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReportImpl extends Report {
  _ReportImpl({
    int? id,
    required int roomId,
    required String reason,
    required DateTime createdAt,
  }) : super._(
         id: id,
         roomId: roomId,
         reason: reason,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Report]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Report copyWith({
    Object? id = _Undefined,
    int? roomId,
    String? reason,
    DateTime? createdAt,
  }) {
    return Report(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      reason: reason ?? this.reason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
