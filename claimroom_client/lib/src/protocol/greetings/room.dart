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

abstract class Room
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  Room._({
    this.id,
    required this.code,
    required this.title,
    required this.sellerName,
    required this.isOpen,
    required this.createdAt,
  });

  factory Room({
    int? id,
    required String code,
    required String title,
    required String sellerName,
    required bool isOpen,
    required DateTime createdAt,
  }) = _RoomImpl;

  factory Room.fromJson(Map<String, dynamic> jsonSerialization) {
    return Room(
      id: jsonSerialization['id'] as int?,
      code: jsonSerialization['code'] as String,
      title: jsonSerialization['title'] as String,
      sellerName: jsonSerialization['sellerName'] as String,
      isOpen: _isc.BoolJsonExtension.fromJson(jsonSerialization['isOpen']),
      createdAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  String code;

  String title;

  String sellerName;

  bool isOpen;

  DateTime createdAt;

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  Room copyWith({
    int? id,
    String? code,
    String? title,
    String? sellerName,
    bool? isOpen,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Room',
      if (id != null) 'id': id,
      'code': code,
      'title': title,
      'sellerName': sellerName,
      'isOpen': isOpen,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Room',
      if (id != null) 'id': id,
      'code': code,
      'title': title,
      'sellerName': sellerName,
      'isOpen': isOpen,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomImpl extends Room {
  _RoomImpl({
    int? id,
    required String code,
    required String title,
    required String sellerName,
    required bool isOpen,
    required DateTime createdAt,
  }) : super._(
         id: id,
         code: code,
         title: title,
         sellerName: sellerName,
         isOpen: isOpen,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  Room copyWith({
    Object? id = _Undefined,
    String? code,
    String? title,
    String? sellerName,
    bool? isOpen,
    DateTime? createdAt,
  }) {
    return Room(
      id: id is int? ? id : this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      sellerName: sellerName ?? this.sellerName,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
