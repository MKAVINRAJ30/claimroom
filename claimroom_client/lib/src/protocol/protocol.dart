/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:claimroom_client/src/protocol/claimroom/item.dart' as _il26i9sg;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'claimroom/buyer_order_summary.dart' as _it96tugq;
import 'claimroom/claim_result.dart' as _in969j7u;
import 'claimroom/item.dart' as _idgc2c1i;
import 'claimroom/order_sheet.dart' as _ihpac1yz;
import 'claimroom/report.dart' as _ivdf4l49;
import 'claimroom/room.dart' as _iekd0e7s;
import 'claimroom/room_event.dart' as _ii05qs2r;
export 'claimroom/buyer_order_summary.dart';
export 'claimroom/claim_result.dart';
export 'claimroom/item.dart';
export 'claimroom/order_sheet.dart';
export 'claimroom/report.dart';
export 'claimroom/room.dart';
export 'claimroom/room_event.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _it96tugq.BuyerOrderSummary) {
      return _it96tugq.BuyerOrderSummary.fromJson(data) as T;
    }
    if (t == _in969j7u.ClaimResult) {
      return _in969j7u.ClaimResult.fromJson(data) as T;
    }
    if (t == _idgc2c1i.Item) {
      return _idgc2c1i.Item.fromJson(data) as T;
    }
    if (t == _ihpac1yz.OrderSheet) {
      return _ihpac1yz.OrderSheet.fromJson(data) as T;
    }
    if (t == _ivdf4l49.Report) {
      return _ivdf4l49.Report.fromJson(data) as T;
    }
    if (t == _iekd0e7s.Room) {
      return _iekd0e7s.Room.fromJson(data) as T;
    }
    if (t == _ii05qs2r.RoomEvent) {
      return _ii05qs2r.RoomEvent.fromJson(data) as T;
    }
    if (t == _isc.getType<_it96tugq.BuyerOrderSummary?>()) {
      return (data != null ? _it96tugq.BuyerOrderSummary.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_in969j7u.ClaimResult?>()) {
      return (data != null ? _in969j7u.ClaimResult.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_idgc2c1i.Item?>()) {
      return (data != null ? _idgc2c1i.Item.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihpac1yz.OrderSheet?>()) {
      return (data != null ? _ihpac1yz.OrderSheet.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ivdf4l49.Report?>()) {
      return (data != null ? _ivdf4l49.Report.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iekd0e7s.Room?>()) {
      return (data != null ? _iekd0e7s.Room.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ii05qs2r.RoomEvent?>()) {
      return (data != null ? _ii05qs2r.RoomEvent.fromJson(data) : null) as T;
    }
    if (t == List<_idgc2c1i.Item>) {
      return (data as List).map((e) => deserialize<_idgc2c1i.Item>(e)).toList()
          as T;
    }
    if (t == List<_it96tugq.BuyerOrderSummary>) {
      return (data as List)
              .map((e) => deserialize<_it96tugq.BuyerOrderSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_il26i9sg.Item>) {
      return (data as List).map((e) => deserialize<_il26i9sg.Item>(e)).toList()
          as T;
    }
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _it96tugq.BuyerOrderSummary => 'BuyerOrderSummary',
      _in969j7u.ClaimResult => 'ClaimResult',
      _idgc2c1i.Item => 'Item',
      _ihpac1yz.OrderSheet => 'OrderSheet',
      _ivdf4l49.Report => 'Report',
      _iekd0e7s.Room => 'Room',
      _ii05qs2r.RoomEvent => 'RoomEvent',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('claimroom.', '');
    }

    switch (data) {
      case _it96tugq.BuyerOrderSummary():
        return 'BuyerOrderSummary';
      case _in969j7u.ClaimResult():
        return 'ClaimResult';
      case _idgc2c1i.Item():
        return 'Item';
      case _ihpac1yz.OrderSheet():
        return 'OrderSheet';
      case _ivdf4l49.Report():
        return 'Report';
      case _iekd0e7s.Room():
        return 'Room';
      case _ii05qs2r.RoomEvent():
        return 'RoomEvent';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'BuyerOrderSummary') {
      return deserialize<_it96tugq.BuyerOrderSummary>(data['data']);
    }
    if (dataClassName == 'ClaimResult') {
      return deserialize<_in969j7u.ClaimResult>(data['data']);
    }
    if (dataClassName == 'Item') {
      return deserialize<_idgc2c1i.Item>(data['data']);
    }
    if (dataClassName == 'OrderSheet') {
      return deserialize<_ihpac1yz.OrderSheet>(data['data']);
    }
    if (dataClassName == 'Report') {
      return deserialize<_ivdf4l49.Report>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_iekd0e7s.Room>(data['data']);
    }
    if (dataClassName == 'RoomEvent') {
      return deserialize<_ii05qs2r.RoomEvent>(data['data']);
    }
    return super.deserializeByClassName(data);
  }

  @override
  String getModuleName() => 'claimroom';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
