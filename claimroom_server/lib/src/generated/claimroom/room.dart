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

abstract class Room implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Room._({
    this.id,
    required this.code,
    required this.title,
    required this.sellerName,
    this.sellerKey,
    required this.isOpen,
    required this.createdAt,
  });

  factory Room({
    int? id,
    required String code,
    required String title,
    required String sellerName,
    String? sellerKey,
    required bool isOpen,
    required DateTime createdAt,
  }) = _RoomImpl;

  factory Room.fromJson(Map<String, dynamic> jsonSerialization) {
    return Room(
      id: jsonSerialization['id'] as int?,
      code: jsonSerialization['code'] as String,
      title: jsonSerialization['title'] as String,
      sellerName: jsonSerialization['sellerName'] as String,
      sellerKey: jsonSerialization['sellerKey'] as String?,
      isOpen: _is.BoolJsonExtension.fromJson(jsonSerialization['isOpen']),
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = RoomTable();

  static const db = RoomRepository._();

  @override
  int? id;

  String code;

  String title;

  String sellerName;

  String? sellerKey;

  bool isOpen;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Room copyWith({
    int? id,
    String? code,
    String? title,
    String? sellerName,
    String? sellerKey,
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
      if (sellerKey != null) 'sellerKey': sellerKey,
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
      if (sellerKey != null) 'sellerKey': sellerKey,
      'isOpen': isOpen,
      'createdAt': createdAt.toJson(),
    };
  }

  static RoomInclude include() {
    return RoomInclude._();
  }

  static RoomIncludeList includeList({
    _is.WhereExpressionBuilder<RoomTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomTable>? orderBy,
    _is.OrderByListBuilder<RoomTable>? orderByList,
    RoomInclude? include,
  }) {
    return RoomIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Room.t),
      orderByList: orderByList?.call(Room.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _RoomImpl extends Room {
  _RoomImpl({
    int? id,
    required String code,
    required String title,
    required String sellerName,
    String? sellerKey,
    required bool isOpen,
    required DateTime createdAt,
  }) : super._(
         id: id,
         code: code,
         title: title,
         sellerName: sellerName,
         sellerKey: sellerKey,
         isOpen: isOpen,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [Room]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Room copyWith({
    Object? id = _Undefined,
    String? code,
    String? title,
    String? sellerName,
    Object? sellerKey = _Undefined,
    bool? isOpen,
    DateTime? createdAt,
  }) {
    return Room(
      id: id is int? ? id : this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      sellerName: sellerName ?? this.sellerName,
      sellerKey: sellerKey is String? ? sellerKey : this.sellerKey,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class RoomUpdateTable extends _is.UpdateTable<RoomTable> {
  RoomUpdateTable(super.table);

  _is.ColumnValue<String, String> code(String value) => _is.ColumnValue(
    table.code,
    value,
  );

  _is.ColumnValue<String, String> title(String value) => _is.ColumnValue(
    table.title,
    value,
  );

  _is.ColumnValue<String, String> sellerName(String value) => _is.ColumnValue(
    table.sellerName,
    value,
  );

  _is.ColumnValue<String, String> sellerKey(String? value) => _is.ColumnValue(
    table.sellerKey,
    value,
  );

  _is.ColumnValue<bool, bool> isOpen(bool value) => _is.ColumnValue(
    table.isOpen,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class RoomTable extends _is.Table<int?> {
  RoomTable({super.tableRelation}) : super(tableName: 'room') {
    updateTable = RoomUpdateTable(this);
    code = _is.ColumnString(
      'code',
      this,
    );
    title = _is.ColumnString(
      'title',
      this,
    );
    sellerName = _is.ColumnString(
      'sellerName',
      this,
    );
    sellerKey = _is.ColumnString(
      'sellerKey',
      this,
    );
    isOpen = _is.ColumnBool(
      'isOpen',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final RoomUpdateTable updateTable;

  late final _is.ColumnString code;

  late final _is.ColumnString title;

  late final _is.ColumnString sellerName;

  late final _is.ColumnString sellerKey;

  late final _is.ColumnBool isOpen;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    code,
    title,
    sellerName,
    sellerKey,
    isOpen,
    createdAt,
  ];
}

class RoomInclude extends _is.IncludeObject {
  RoomInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Room.t;
}

class RoomIncludeList extends _is.IncludeList {
  RoomIncludeList._({
    _is.WhereExpressionBuilder<RoomTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Room.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Room.t;
}

class RoomRepository {
  const RoomRepository._();

  /// Returns a list of [Room]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<Room>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomTable>? orderBy,
    _is.OrderByListBuilder<RoomTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Room>(
      where: where?.call(Room.t),
      orderBy: orderBy?.call(Room.t),
      orderByList: orderByList?.call(Room.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Room] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<Room?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomTable>? where,
    int? offset,
    _is.OrderByBuilder<RoomTable>? orderBy,
    _is.OrderByListBuilder<RoomTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Room>(
      where: where?.call(Room.t),
      orderBy: orderBy?.call(Room.t),
      orderByList: orderByList?.call(Room.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Room] by its [id] or null if no such row exists.
  Future<Room?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Room>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Room]s in the list and returns the inserted rows.
  ///
  /// The returned [Room]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  ///
  /// If [noReturn] is set to `true`, the inserted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Room>> insert(
    _is.DatabaseSession session,
    List<Room> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Room>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Room] and returns the inserted row.
  ///
  /// The returned [Room] will have its `id` field set.
  Future<Room> insertRow(
    _is.DatabaseSession session,
    Room row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Room>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Room]s in the list and returns the resulting rows.
  ///
  /// If a row conflicts on the given [conflictColumns], the existing row is
  /// updated with the new values. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies to rows matching the
  /// given expression. Conflicting rows that don't match are skipped and not
  /// returned, so the resulting list may be shorter than [rows].
  ///
  /// The returned [Room]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Room>> upsert(
    _is.DatabaseSession session,
    List<Room> rows, {
    required _is.ColumnSelections<RoomTable> conflictColumns,
    _is.ColumnSelections<RoomTable>? updateColumns,
    _is.WhereExpressionBuilder<RoomTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Room>(
      rows,
      conflictColumns: conflictColumns(Room.t),
      updateColumns: updateColumns?.call(Room.t),
      updateWhere: updateWhere?.call(Room.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Room] and returns the resulting row.
  ///
  /// If the row conflicts on the given [conflictColumns], the existing row is
  /// updated. Otherwise, a new row is inserted.
  ///
  /// If [updateColumns] is provided, only those columns will be updated on
  /// conflict. If null, all non-conflict, non-id columns are updated.
  ///
  /// If [updateWhere] is provided, the update only applies when the existing
  /// row matches the expression. Returns `null` if no row was affected — for
  /// example when [updateWhere] does not match the conflicting row.
  ///
  /// The returned [Room] will have its `id` field set.
  Future<Room?> upsertRow(
    _is.DatabaseSession session,
    Room row, {
    required _is.ColumnSelections<RoomTable> conflictColumns,
    _is.ColumnSelections<RoomTable>? updateColumns,
    _is.WhereExpressionBuilder<RoomTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Room>(
      row,
      conflictColumns: conflictColumns(Room.t),
      updateColumns: updateColumns?.call(Room.t),
      updateWhere: updateWhere?.call(Room.t),
      transaction: transaction,
    );
  }

  /// Updates all [Room]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Room>> update(
    _is.DatabaseSession session,
    List<Room> rows, {
    _is.ColumnSelections<RoomTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Room>(
      rows,
      columns: columns?.call(Room.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Room]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Room> updateRow(
    _is.DatabaseSession session,
    Room row, {
    _is.ColumnSelections<RoomTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Room>(
      row,
      columns: columns?.call(Room.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Room] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Room?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<RoomUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Room>(
      id,
      columnValues: columnValues(Room.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Room]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Room>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<RoomUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<RoomTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<RoomTable>? orderBy,
    _is.OrderByListBuilder<RoomTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Room>(
      columnValues: columnValues(Room.t.updateTable),
      where: where(Room.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Room.t),
      orderByList: orderByList?.call(Room.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Room]s in the list and returns the deleted rows.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Room>> delete(
    _is.DatabaseSession session,
    List<Room> rows, {
    _is.OrderByBuilder<RoomTable>? orderBy,
    _is.OrderByListBuilder<RoomTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Room>(
      rows,
      orderBy: orderBy?.call(Room.t),
      orderByList: orderByList?.call(Room.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Room].
  Future<Room> deleteRow(
    _is.DatabaseSession session,
    Room row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Room>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  ///
  /// To specify the order of the returned rows use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// If [noReturn] is set to `true`, the deleted rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Room>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RoomTable> where,
    _is.OrderByBuilder<RoomTable>? orderBy,
    _is.OrderByListBuilder<RoomTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Room>(
      where: where(Room.t),
      orderBy: orderBy?.call(Room.t),
      orderByList: orderByList?.call(Room.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<RoomTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Room>(
      where: where?.call(Room.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Room] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<RoomTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Room>(
      where: where(Room.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
