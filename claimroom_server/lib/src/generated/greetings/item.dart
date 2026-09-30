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

abstract class Item implements _is.TableRow<int?>, _is.ProtocolSerialization {
  Item._({
    this.id,
    required this.roomId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.status,
    this.heldBy,
    this.holdExpiresAt,
  });

  factory Item({
    int? id,
    required int roomId,
    required String name,
    required double price,
    required int quantity,
    required String status,
    String? heldBy,
    DateTime? holdExpiresAt,
  }) = _ItemImpl;

  factory Item.fromJson(Map<String, dynamic> jsonSerialization) {
    return Item(
      id: jsonSerialization['id'] as int?,
      roomId: jsonSerialization['roomId'] as int,
      name: jsonSerialization['name'] as String,
      price: (jsonSerialization['price'] as num).toDouble(),
      quantity: jsonSerialization['quantity'] as int,
      status: jsonSerialization['status'] as String,
      heldBy: jsonSerialization['heldBy'] as String?,
      holdExpiresAt: jsonSerialization['holdExpiresAt'] == null
          ? null
          : _is.DateTimeJsonExtension.fromJson(
              jsonSerialization['holdExpiresAt'],
            ),
    );
  }

  static final t = ItemTable();

  static const db = ItemRepository._();

  @override
  int? id;

  int roomId;

  String name;

  double price;

  int quantity;

  String status;

  String? heldBy;

  DateTime? holdExpiresAt;

  @override
  _is.Table<int?> get table => t;

  /// Returns a shallow copy of this [Item]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  Item copyWith({
    int? id,
    int? roomId,
    String? name,
    double? price,
    int? quantity,
    String? status,
    String? heldBy,
    DateTime? holdExpiresAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Item',
      if (id != null) 'id': id,
      'roomId': roomId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
      if (heldBy != null) 'heldBy': heldBy,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt?.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'Item',
      if (id != null) 'id': id,
      'roomId': roomId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'status': status,
      if (heldBy != null) 'heldBy': heldBy,
      if (holdExpiresAt != null) 'holdExpiresAt': holdExpiresAt?.toJson(),
    };
  }

  static ItemInclude include() {
    return ItemInclude._();
  }

  static ItemIncludeList includeList({
    _is.WhereExpressionBuilder<ItemTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemTable>? orderBy,
    _is.OrderByListBuilder<ItemTable>? orderByList,
    ItemInclude? include,
  }) {
    return ItemIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Item.t),
      orderByList: orderByList?.call(Item.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _is.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ItemImpl extends Item {
  _ItemImpl({
    int? id,
    required int roomId,
    required String name,
    required double price,
    required int quantity,
    required String status,
    String? heldBy,
    DateTime? holdExpiresAt,
  }) : super._(
         id: id,
         roomId: roomId,
         name: name,
         price: price,
         quantity: quantity,
         status: status,
         heldBy: heldBy,
         holdExpiresAt: holdExpiresAt,
       );

  /// Returns a shallow copy of this [Item]
  /// with some or all fields replaced by the given arguments.
  @_is.useResult
  @override
  Item copyWith({
    Object? id = _Undefined,
    int? roomId,
    String? name,
    double? price,
    int? quantity,
    String? status,
    Object? heldBy = _Undefined,
    Object? holdExpiresAt = _Undefined,
  }) {
    return Item(
      id: id is int? ? id : this.id,
      roomId: roomId ?? this.roomId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      status: status ?? this.status,
      heldBy: heldBy is String? ? heldBy : this.heldBy,
      holdExpiresAt: holdExpiresAt is DateTime?
          ? holdExpiresAt
          : this.holdExpiresAt,
    );
  }
}

class ItemUpdateTable extends _is.UpdateTable<ItemTable> {
  ItemUpdateTable(super.table);

  _is.ColumnValue<int, int> roomId(int value) => _is.ColumnValue(
    table.roomId,
    value,
  );

  _is.ColumnValue<String, String> name(String value) => _is.ColumnValue(
    table.name,
    value,
  );

  _is.ColumnValue<double, double> price(double value) => _is.ColumnValue(
    table.price,
    value,
  );

  _is.ColumnValue<int, int> quantity(int value) => _is.ColumnValue(
    table.quantity,
    value,
  );

  _is.ColumnValue<String, String> status(String value) => _is.ColumnValue(
    table.status,
    value,
  );

  _is.ColumnValue<String, String> heldBy(String? value) => _is.ColumnValue(
    table.heldBy,
    value,
  );

  _is.ColumnValue<DateTime, DateTime> holdExpiresAt(DateTime? value) =>
      _is.ColumnValue(
        table.holdExpiresAt,
        value,
      );
}

class ItemTable extends _is.Table<int?> {
  ItemTable({super.tableRelation}) : super(tableName: 'item') {
    updateTable = ItemUpdateTable(this);
    roomId = _is.ColumnInt(
      'roomId',
      this,
    );
    name = _is.ColumnString(
      'name',
      this,
    );
    price = _is.ColumnDouble(
      'price',
      this,
    );
    quantity = _is.ColumnInt(
      'quantity',
      this,
    );
    status = _is.ColumnString(
      'status',
      this,
    );
    heldBy = _is.ColumnString(
      'heldBy',
      this,
    );
    holdExpiresAt = _is.ColumnDateTime(
      'holdExpiresAt',
      this,
    );
  }

  late final ItemUpdateTable updateTable;

  late final _is.ColumnInt roomId;

  late final _is.ColumnString name;

  late final _is.ColumnDouble price;

  late final _is.ColumnInt quantity;

  late final _is.ColumnString status;

  late final _is.ColumnString heldBy;

  late final _is.ColumnDateTime holdExpiresAt;

  @override
  List<_is.Column> get columns => [
    id,
    roomId,
    name,
    price,
    quantity,
    status,
    heldBy,
    holdExpiresAt,
  ];
}

class ItemInclude extends _is.IncludeObject {
  ItemInclude._();

  @override
  Map<String, _is.Include?> get includes => {};

  @override
  _is.Table<int?> get table => Item.t;
}

class ItemIncludeList extends _is.IncludeList {
  ItemIncludeList._({
    _is.WhereExpressionBuilder<ItemTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(Item.t);
  }

  @override
  Map<String, _is.Include?> get includes => include?.includes ?? {};

  @override
  _is.Table<int?> get table => Item.t;
}

class ItemRepository {
  const ItemRepository._();

  /// Returns a list of [Item]s matching the given query parameters.
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
  Future<List<Item>> find(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemTable>? where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemTable>? orderBy,
    _is.OrderByListBuilder<ItemTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<Item>(
      where: where?.call(Item.t),
      orderBy: orderBy?.call(Item.t),
      orderByList: orderByList?.call(Item.t),
      limit: limit,
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [Item] matching the given query parameters.
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
  Future<Item?> findFirstRow(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemTable>? where,
    int? offset,
    _is.OrderByBuilder<ItemTable>? orderBy,
    _is.OrderByListBuilder<ItemTable>? orderByList,
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<Item>(
      where: where?.call(Item.t),
      orderBy: orderBy?.call(Item.t),
      orderByList: orderByList?.call(Item.t),
      offset: offset,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [Item] by its [id] or null if no such row exists.
  Future<Item?> findById(
    _is.DatabaseSession session,
    int id, {
    _is.Transaction? transaction,
    _is.LockMode? lockMode,
    _is.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<Item>(
      id,
      transaction: transaction,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [Item]s in the list and returns the inserted rows.
  ///
  /// The returned [Item]s will have their `id` fields set.
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
  Future<List<Item>> insert(
    _is.DatabaseSession session,
    List<Item> rows, {
    _is.Transaction? transaction,
    bool ignoreConflicts = false,
    bool noReturn = false,
  }) async {
    return session.db.insert<Item>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
      noReturn: noReturn,
    );
  }

  /// Inserts a single [Item] and returns the inserted row.
  ///
  /// The returned [Item] will have its `id` field set.
  Future<Item> insertRow(
    _is.DatabaseSession session,
    Item row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.insertRow<Item>(
      row,
      transaction: transaction,
    );
  }

  /// Upserts all [Item]s in the list and returns the resulting rows.
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
  /// The returned [Item]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails,
  /// none of the rows will be affected.
  ///
  /// If [noReturn] is set to `true`, the resulting rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Item>> upsert(
    _is.DatabaseSession session,
    List<Item> rows, {
    required _is.ColumnSelections<ItemTable> conflictColumns,
    _is.ColumnSelections<ItemTable>? updateColumns,
    _is.WhereExpressionBuilder<ItemTable>? updateWhere,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.upsert<Item>(
      rows,
      conflictColumns: conflictColumns(Item.t),
      updateColumns: updateColumns?.call(Item.t),
      updateWhere: updateWhere?.call(Item.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Upserts a single [Item] and returns the resulting row.
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
  /// The returned [Item] will have its `id` field set.
  Future<Item?> upsertRow(
    _is.DatabaseSession session,
    Item row, {
    required _is.ColumnSelections<ItemTable> conflictColumns,
    _is.ColumnSelections<ItemTable>? updateColumns,
    _is.WhereExpressionBuilder<ItemTable>? updateWhere,
    _is.Transaction? transaction,
  }) async {
    return session.db.upsertRow<Item>(
      row,
      conflictColumns: conflictColumns(Item.t),
      updateColumns: updateColumns?.call(Item.t),
      updateWhere: updateWhere?.call(Item.t),
      transaction: transaction,
    );
  }

  /// Updates all [Item]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Item>> update(
    _is.DatabaseSession session,
    List<Item> rows, {
    _is.ColumnSelections<ItemTable>? columns,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.update<Item>(
      rows,
      columns: columns?.call(Item.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Updates a single [Item]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<Item> updateRow(
    _is.DatabaseSession session,
    Item row, {
    _is.ColumnSelections<ItemTable>? columns,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateRow<Item>(
      row,
      columns: columns?.call(Item.t),
      transaction: transaction,
    );
  }

  /// Updates a single [Item] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<Item?> updateById(
    _is.DatabaseSession session,
    int id, {
    required _is.ColumnValueListBuilder<ItemUpdateTable> columnValues,
    _is.Transaction? transaction,
  }) async {
    return session.db.updateById<Item>(
      id,
      columnValues: columnValues(Item.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [Item]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  ///
  /// If [noReturn] is set to `true`, the updated rows are not read back from
  /// the database and an empty list is returned. This avoids the overhead of
  /// transferring and deserializing the rows when the result is not needed.
  Future<List<Item>> updateWhere(
    _is.DatabaseSession session, {
    required _is.ColumnValueListBuilder<ItemUpdateTable> columnValues,
    required _is.WhereExpressionBuilder<ItemTable> where,
    int? limit,
    int? offset,
    _is.OrderByBuilder<ItemTable>? orderBy,
    _is.OrderByListBuilder<ItemTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.updateWhere<Item>(
      columnValues: columnValues(Item.t.updateTable),
      where: where(Item.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(Item.t),
      orderByList: orderByList?.call(Item.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes all [Item]s in the list and returns the deleted rows.
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
  Future<List<Item>> delete(
    _is.DatabaseSession session,
    List<Item> rows, {
    _is.OrderByBuilder<ItemTable>? orderBy,
    _is.OrderByListBuilder<ItemTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.delete<Item>(
      rows,
      orderBy: orderBy?.call(Item.t),
      orderByList: orderByList?.call(Item.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Deletes a single [Item].
  Future<Item> deleteRow(
    _is.DatabaseSession session,
    Item row, {
    _is.Transaction? transaction,
  }) async {
    return session.db.deleteRow<Item>(
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
  Future<List<Item>> deleteWhere(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ItemTable> where,
    _is.OrderByBuilder<ItemTable>? orderBy,
    _is.OrderByListBuilder<ItemTable>? orderByList,
    _is.Transaction? transaction,
    bool noReturn = false,
  }) async {
    return session.db.deleteWhere<Item>(
      where: where(Item.t),
      orderBy: orderBy?.call(Item.t),
      orderByList: orderByList?.call(Item.t),
      transaction: transaction,
      noReturn: noReturn,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _is.DatabaseSession session, {
    _is.WhereExpressionBuilder<ItemTable>? where,
    int? limit,
    _is.Transaction? transaction,
  }) async {
    return session.db.count<Item>(
      where: where?.call(Item.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [Item] rows matching the [where] expression.
  Future<void> lockRows(
    _is.DatabaseSession session, {
    required _is.WhereExpressionBuilder<ItemTable> where,
    required _is.LockMode lockMode,
    required _is.Transaction transaction,
    _is.LockBehavior lockBehavior = _is.LockBehavior.wait,
  }) async {
    return session.db.lockRows<Item>(
      where: where(Item.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}
