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

abstract class WaitlistEntry
    implements _is.TableRow<int?>, _is.ProtocolSerialization {
  WaitlistEntry._({
    this.id,
    required this.roomId,
    required this.itemId,
    required this.buyerName,
    required this.buyerToken,
    required this.createdAt,
  });

  factory WaitlistEntry({
    int? id,
    required int roomId,
    required int itemId,
    required String buyerName,
    required String buyerToken,
    required DateTime createdAt,
  }) = _WaitlistEntryImpl;

  factory WaitlistEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return WaitlistEntry(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      itemId: jsonSerialization['itemId'] as int,
      buyerName: jsonSerialization['buyerName'] as String,
      buyerToken: jsonSerialization['buyerToken'] as String,
      createdAt: _is.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = WaitlistEntryTable();

  static const db = WaitlistEntryRepository._();

  @override
  int? id;

  int roomId;

  int itemId;

  String buyerName;

  String buyerToken;

  DateTime createdAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [WaitlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  WaitlistEntry copyWith({
    int? id,
    int? roomId,
    int? itemId,
    String? buyerName,
    String? buyerToken,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WaitlistEntry',
      if (id != null) 'id': id,
      'roomId': roomId,
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerToken': buyerToken,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'WaitlistEntry',
      if (id != null) 'id': id,
      'roomId': roomId,
      'itemId': itemId,
      'buyerName': buyerName,
      'buyerToken': buyerToken,
      'createdAt': createdAt.toJson(),
    };
  }

  static WaitlistEntryInclude include() {
    return WaitlistEntryInclude._();
  }

  static WaitlistEntryIncludeList includeList({
    _is.WhereExpressionBuilder<WaitlistEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WaitlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WaitlistEntryTable>? orderByList,
    WaitlistEntryInclude? include,
  }) {
    return WaitlistEntryIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WaitlistEntry.t),
      orderByList: orderByList?.call(WaitlistEntry.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _WaitlistEntryImpl extends WaitlistEntry {
  _WaitlistEntryImpl({
    int? id,
    required int roomId,
    required int itemId,
    required String buyerName,
    required String buyerToken,
    required DateTime createdAt,
  }) : super._(
         id: id,
         roomId: roomId,
         itemId: itemId,
         buyerName: buyerName,
         buyerToken: buyerToken,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [WaitlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  WaitlistEntry copyWith({
    Object? id = _Undefined,
    int? roomId,
    int? itemId,
    String? buyerName,
    String? buyerToken,
    DateTime? createdAt,
  }) {
    return WaitlistEntry(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      itemId: itemId ?? this.itemId,
      buyerName: buyerName ?? this.buyerName,
      buyerToken: buyerToken ?? this.buyerToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class WaitlistEntryUpdateTable extends _is.UpdateTable<WaitlistEntryTable> {
  WaitlistEntryUpdateTable(super.table);

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );

  _is.ColumnValue<int, int> itemId(int value) => _is.ColumnValue(
    table.itemId,
    value,
  );

  _is.ColumnValue<String, String> buyerName(String value) => _is.ColumnValue(
    table.buyerName,
    value,
  );

  _is.ColumnValue<String, String> buyerToken(String value) => _is.ColumnValue(
    table.buyerToken,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _is.ColumnValue(
        table.createdAt,
        value,
      );
}

class WaitlistEntryTable extends _is.Table<int?> {
  WaitlistEntryTable({super.tableRelation})
    : super(tableName: 'waitlist_entry') {
    updateTable = WaitlistEntryUpdateTable(this);
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
    itemId = _is.ColumnInt(
      'itemId',
      this,
    );
    buyerName = _is.ColumnString(
      'buyerName',
      this,
    );
    buyerToken = _is.ColumnString(
      'buyerToken',
      this,
    );
    createdAt = _is.ColumnDateTime(
      'createdAt',
      this,
    );
  }

  late final WaitlistEntryUpdateTable updateTable;

  late final _is.ColumnInt roomId;

  late final _is.ColumnInt itemId;

  late final _is.ColumnString buyerName;

  late final _is.ColumnString buyerToken;

  late final _is.ColumnDateTime createdAt;

  @override
  List<_is.Column> get columns => [
    id,
    roomId,
    itemId,
    buyerName,
    buyerToken,
    createdAt,
  ];
}

class WaitlistEntryInclude extends _is.IncludeObject {
  WaitlistEntryInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => WaitlistEntry.t;
}

class WaitlistEntryIncludeList extends _is.IncludeList {
  WaitlistEntryIncludeList._({
    _is.WhereExpressionBuilder<WaitlistEntryTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(WaitlistEntry.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => WaitlistEntry.t;
}

class WaitlistEntryRepository {
  const WaitlistEntryRepository._();

  /// Returns a list of [WaitlistEntry]s matching the given query parameters.
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
  Future<List<WaitlistEntry>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WaitlistEntryTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WaitlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WaitlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<WaitlistEntry>(
      where: where?.call(WaitlistEntry.t),
      orderBy: orderBy?.call(WaitlistEntry.t),
      orderByList: orderByList?.call(WaitlistEntry.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [WaitlistEntry] matching the given query parameters.
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
  Future<WaitlistEntry?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WaitlistEntryTable>? where,
    int? offset,
    _is.OrderByBuilder<WaitlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WaitlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<WaitlistEntry>(
      where: where?.call(WaitlistEntry.t),
      orderBy: orderBy?.call(WaitlistEntry.t),
      orderByList: orderByList?.call(WaitlistEntry.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [WaitlistEntry] by its [id] or null if no such row exists.
  Future<WaitlistEntry?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<WaitlistEntry>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [WaitlistEntry]s in the list and returns the inserted rows.
  ///
  /// The returned [WaitlistEntry]s will have their `id` fields set.
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
  Future<List<WaitlistEntry>> insert(
    _is.DatabaseSession session,
    List<WaitlistEntry> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<WaitlistEntry>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [WaitlistEntry] and returns the inserted row.
  ///
  /// The returned [WaitlistEntry] will have its `id` field set.
  Future<WaitlistEntry> insertRow(
    _is.DatabaseSession session,
    WaitlistEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<WaitlistEntry>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [WaitlistEntry]s in the list and returns the resulting rows.
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
  /// The returned [WaitlistEntry]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WaitlistEntry>> upsert(
    _is.DatabaseSession session,
    List<WaitlistEntry> rows, {
    required _is.ColumnSelections<WaitlistEntryTable> conflictColumns,
    _is.ColumnSelections<WaitlistEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<WaitlistEntryTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<WaitlistEntry>(
      rows,
      conflictColumns: conflictColumns(WaitlistEntry.t),
      updateColumns: updateColumns?.call(WaitlistEntry.t),
      updateWhere: updateWhere?.call(WaitlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [WaitlistEntry] and returns the resulting row.
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
  /// The returned [WaitlistEntry] will have its `id` field set.
  Future<WaitlistEntry?> upsertRow(
    _is.DatabaseSession session,
    WaitlistEntry row, {
    required _is.ColumnSelections<WaitlistEntryTable> conflictColumns,
    _is.ColumnSelections<WaitlistEntryTable>? updateColumns,
    _is.WhereExpressionBuilder<WaitlistEntryTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<WaitlistEntry>(
      row,
      conflictColumns: conflictColumns(WaitlistEntry.t),
      updateColumns: updateColumns?.call(WaitlistEntry.t),
      updateWhere: updateWhere?.call(WaitlistEntry.t),
      transaction: transaction,
    );
  }

  /// Updates all [WaitlistEntry]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WaitlistEntry>> update(
    _is.DatabaseSession session,
    List<WaitlistEntry> rows, {
    _is.ColumnSelections<WaitlistEntryTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<WaitlistEntry>(
      rows,
      columns: columns?.call(WaitlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [WaitlistEntry]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<WaitlistEntry> updateRow(
    _is.DatabaseSession session,
    WaitlistEntry row, {
    _is.ColumnSelections<WaitlistEntryTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<WaitlistEntry>(
      row,
      columns: columns?.call(WaitlistEntry.t),
      transaction: transaction,
    );
  }

  /// Updates a single [WaitlistEntry] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<WaitlistEntry?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<WaitlistEntryUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<WaitlistEntry>(
      id,
      columnValues: columnValues(WaitlistEntry.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [WaitlistEntry]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<WaitlistEntry>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<WaitlistEntryUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<WaitlistEntryTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<WaitlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WaitlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<WaitlistEntry>(
      columnValues: columnValues(WaitlistEntry.t.updateTable),
      where: where(WaitlistEntry.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(WaitlistEntry.t),
      orderByList: orderByList?.call(WaitlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [WaitlistEntry]s in the list and returns the deleted rows.
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
  Future<List<WaitlistEntry>> delete(
    _is.DatabaseSession session,
    List<WaitlistEntry> rows, {
    _is.OrderByBuilder<WaitlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WaitlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<WaitlistEntry>(
      rows,
      orderBy: orderBy?.call(WaitlistEntry.t),
      orderByList: orderByList?.call(WaitlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [WaitlistEntry].
  Future<WaitlistEntry> deleteRow(
    _is.DatabaseSession session,
    WaitlistEntry row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<WaitlistEntry>(
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
  Future<List<WaitlistEntry>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WaitlistEntryTable> where,
    _is.OrderByBuilder<WaitlistEntryTable>? orderBy,
    _is.OrderByListBuilder<WaitlistEntryTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<WaitlistEntry>(
      where: where(WaitlistEntry.t),
      orderBy: orderBy?.call(WaitlistEntry.t),
      orderByList: orderByList?.call(WaitlistEntry.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<WaitlistEntryTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<WaitlistEntry>(
      where: where?.call(WaitlistEntry.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [WaitlistEntry] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<WaitlistEntryTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<WaitlistEntry>(
      where: where(WaitlistEntry.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
