// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_items_dao.dart';

// ignore_for_file: type=lint
mixin _$InvoiceItemsDaoMixin on DatabaseAccessor<AppDatabase> {
  $StoresTable get stores => attachedDatabase.stores;
  $UsersTable get users => attachedDatabase.users;
  $InvoicesTable get invoices => attachedDatabase.invoices;
  $ProductsTable get products => attachedDatabase.products;
  $InvoiceItemsTable get invoiceItems => attachedDatabase.invoiceItems;
  InvoiceItemsDaoManager get managers => InvoiceItemsDaoManager(this);
}

class InvoiceItemsDaoManager {
  final _$InvoiceItemsDaoMixin _db;
  InvoiceItemsDaoManager(this._db);
  $$StoresTableTableManager get stores =>
      $$StoresTableTableManager(_db.attachedDatabase, _db.stores);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db.attachedDatabase, _db.users);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db.attachedDatabase, _db.invoices);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db.attachedDatabase, _db.invoiceItems);
}
