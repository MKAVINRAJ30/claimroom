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
import 'package:claimroom_server/src/generated/greetings/item.dart'
    as _if796r8c;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'claimroom/buyer_order_summary.dart' as _it96tugq;
import 'claimroom/claim_result.dart' as _in969j7u;
import 'claimroom/order_sheet.dart' as _ihpac1yz;
import 'claimroom/room_event.dart' as _ii05qs2r;
import 'future_calls_generated_models/hold_expiry_future_call_expire_hold_model.dart'
    as _inu78a98;
import 'greetings/greeting.dart' as _izw8z7ou;
import 'greetings/item.dart' as _i1g1fq7w;
import 'greetings/room.dart' as _ihwvtgor;
export 'claimroom/buyer_order_summary.dart';
export 'claimroom/claim_result.dart';
export 'claimroom/order_sheet.dart';
export 'claimroom/room_event.dart';
export 'greetings/greeting.dart';
export 'greetings/item.dart';
export 'greetings/room.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'item',
      dartName: 'Item',
      schema: 'public',
      module: 'claimroom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'roomId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'name',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'price',
          columnType: _isp.ColumnType.doublePrecision,
          isNullable: false,
          dartType: 'double',
        ),
        _isp.ColumnDefinition(
          name: 'quantity',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'heldBy',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'heldByContact',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'holdExpiresAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'soldTo',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'soldToContact',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'soldAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'item_room_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'roomId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'room',
      dartName: 'Room',
      schema: 'public',
      module: 'claimroom',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'code',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'sellerName',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'isOpen',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'room_code_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'code',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
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
    if (t == _ihpac1yz.OrderSheet) {
      return _ihpac1yz.OrderSheet.fromJson(data) as T;
    }
    if (t == _ii05qs2r.RoomEvent) {
      return _ii05qs2r.RoomEvent.fromJson(data) as T;
    }
    if (t == _inu78a98.HoldExpiryFutureCallExpireHoldModel) {
      return _inu78a98.HoldExpiryFutureCallExpireHoldModel.fromJson(data) as T;
    }
    if (t == _izw8z7ou.Greeting) {
      return _izw8z7ou.Greeting.fromJson(data) as T;
    }
    if (t == _i1g1fq7w.Item) {
      return _i1g1fq7w.Item.fromJson(data) as T;
    }
    if (t == _ihwvtgor.Room) {
      return _ihwvtgor.Room.fromJson(data) as T;
    }
    if (t == _is.getType<_it96tugq.BuyerOrderSummary?>()) {
      return (data != null ? _it96tugq.BuyerOrderSummary.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_in969j7u.ClaimResult?>()) {
      return (data != null ? _in969j7u.ClaimResult.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihpac1yz.OrderSheet?>()) {
      return (data != null ? _ihpac1yz.OrderSheet.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ii05qs2r.RoomEvent?>()) {
      return (data != null ? _ii05qs2r.RoomEvent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_inu78a98.HoldExpiryFutureCallExpireHoldModel?>()) {
      return (data != null
              ? _inu78a98.HoldExpiryFutureCallExpireHoldModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_izw8z7ou.Greeting?>()) {
      return (data != null ? _izw8z7ou.Greeting.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1g1fq7w.Item?>()) {
      return (data != null ? _i1g1fq7w.Item.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihwvtgor.Room?>()) {
      return (data != null ? _ihwvtgor.Room.fromJson(data) : null) as T;
    }
    if (t == List<_i1g1fq7w.Item>) {
      return (data as List).map((e) => deserialize<_i1g1fq7w.Item>(e)).toList()
          as T;
    }
    if (t == List<_it96tugq.BuyerOrderSummary>) {
      return (data as List)
              .map((e) => deserialize<_it96tugq.BuyerOrderSummary>(e))
              .toList()
          as T;
    }
    if (t == List<_if796r8c.Item>) {
      return (data as List).map((e) => deserialize<_if796r8c.Item>(e)).toList()
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _it96tugq.BuyerOrderSummary => 'BuyerOrderSummary',
      _in969j7u.ClaimResult => 'ClaimResult',
      _ihpac1yz.OrderSheet => 'OrderSheet',
      _ii05qs2r.RoomEvent => 'RoomEvent',
      _inu78a98.HoldExpiryFutureCallExpireHoldModel =>
        'HoldExpiryFutureCallExpireHoldModel',
      _izw8z7ou.Greeting => 'Greeting',
      _i1g1fq7w.Item => 'Item',
      _ihwvtgor.Room => 'Room',
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
      case _ihpac1yz.OrderSheet():
        return 'OrderSheet';
      case _ii05qs2r.RoomEvent():
        return 'RoomEvent';
      case _inu78a98.HoldExpiryFutureCallExpireHoldModel():
        return 'HoldExpiryFutureCallExpireHoldModel';
      case _izw8z7ou.Greeting():
        return 'Greeting';
      case _i1g1fq7w.Item():
        return 'Item';
      case _ihwvtgor.Room():
        return 'Room';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
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
    if (dataClassName == 'OrderSheet') {
      return deserialize<_ihpac1yz.OrderSheet>(data['data']);
    }
    if (dataClassName == 'RoomEvent') {
      return deserialize<_ii05qs2r.RoomEvent>(data['data']);
    }
    if (dataClassName == 'HoldExpiryFutureCallExpireHoldModel') {
      return deserialize<_inu78a98.HoldExpiryFutureCallExpireHoldModel>(
        data['data'],
      );
    }
    if (dataClassName == 'Greeting') {
      return deserialize<_izw8z7ou.Greeting>(data['data']);
    }
    if (dataClassName == 'Item') {
      return deserialize<_i1g1fq7w.Item>(data['data']);
    }
    if (dataClassName == 'Room') {
      return deserialize<_ihwvtgor.Room>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('claimroom', this);
    _iacs.Protocol().registerHostProtocol('claimroom', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i1g1fq7w.Item:
        return _i1g1fq7w.Item.t;
      case _ihwvtgor.Room:
        return _ihwvtgor.Room.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
    try {
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
