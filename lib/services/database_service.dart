// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../models/property.dart';
import '../models/unit.dart';
import '../models/tenant.dart';
import '../models/payment.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'spectrum.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE properties (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        description TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE units (
        id TEXT PRIMARY KEY,
        propertyId TEXT NOT NULL,
        unitNumber TEXT NOT NULL,
        description TEXT,
        monthlyRent REAL NOT NULL,
        paymentDueDay INTEGER NOT NULL,
        status TEXT NOT NULL,
        tenantId TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (propertyId) REFERENCES properties (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE tenants (
        id TEXT PRIMARY KEY,
        fullName TEXT NOT NULL,
        phoneNumber TEXT NOT NULL,
        email TEXT,
        nationalId TEXT,
        emergencyContact TEXT,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        unitId TEXT NOT NULL,
        tenantId TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentDate TEXT NOT NULL,
        forMonth TEXT NOT NULL,
        method TEXT NOT NULL,
        reference TEXT,
        notes TEXT,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        checkoutRequestId TEXT,
        merchantRequestId TEXT,
        resultCode INTEGER,
        failureReason TEXT,
        mpesaReceipt TEXT,
        paidAt TEXT,
        serverInvoiceId INTEGER,
        serverInvoiceNumber TEXT,
        FOREIGN KEY (unitId) REFERENCES units (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN checkoutRequestId TEXT',
      );
      await db.execute(
        'ALTER TABLE payments ADD COLUMN merchantRequestId TEXT',
      );
      await db.execute('ALTER TABLE payments ADD COLUMN resultCode INTEGER');
      await db.execute('ALTER TABLE payments ADD COLUMN failureReason TEXT');
      await db.execute('ALTER TABLE payments ADD COLUMN mpesaReceipt TEXT');
      await db.execute('ALTER TABLE payments ADD COLUMN paidAt TEXT');
    }
    if (oldV < 3) {
      await db.execute(
        'ALTER TABLE payments ADD COLUMN serverInvoiceId INTEGER',
      );
      await db.execute(
        'ALTER TABLE payments ADD COLUMN serverInvoiceNumber TEXT',
      );
    }
  }

  // Property CRUD
  Future<void> insertProperty(Property property) async {
    final db = await database;
    await db.insert('properties', property.toMap());
  }

  Future<List<Property>> getProperties() async {
    final db = await database;
    final maps = await db.query('properties', orderBy: 'createdAt DESC');
    return maps.map((m) => Property.fromMap(m)).toList();
  }

  Future<void> updateProperty(Property property) async {
    final db = await database;
    await db.update(
      'properties',
      property.toMap(),
      where: 'id = ?',
      whereArgs: [property.id],
    );
  }

  Future<void> deleteProperty(String id) async {
    final db = await database;
    await db.delete('properties', where: 'id = ?', whereArgs: [id]);
  }

  // Unit CRUD
  Future<void> insertUnit(Unit unit) async {
    final db = await database;
    await db.insert('units', unit.toMap());
  }

  Future<List<Unit>> getUnitsByProperty(String propertyId) async {
    final db = await database;
    final maps = await db.query(
      'units',
      where: 'propertyId = ?',
      whereArgs: [propertyId],
      orderBy: 'unitNumber ASC',
    );
    return maps.map((m) => Unit.fromMap(m)).toList();
  }

  Future<List<Unit>> getAllUnits() async {
    final db = await database;
    final maps = await db.query('units', orderBy: 'unitNumber ASC');
    return maps.map((m) => Unit.fromMap(m)).toList();
  }

  Future<void> updateUnit(Unit unit) async {
    final db = await database;
    await db.update(
      'units',
      unit.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<void> deleteUnit(String id) async {
    final db = await database;
    await db.delete('units', where: 'id = ?', whereArgs: [id]);
  }

  // Tenant CRUD
  Future<void> insertTenant(Tenant tenant) async {
    final db = await database;
    await db.insert('tenants', tenant.toMap());
  }

  Future<List<Tenant>> getTenants() async {
    final db = await database;
    final maps = await db.query('tenants', orderBy: 'fullName ASC');
    return maps.map((m) => Tenant.fromMap(m)).toList();
  }

  Future<Tenant?> getTenantById(String id) async {
    final db = await database;
    final maps = await db.query(
      'tenants',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Tenant.fromMap(maps.first);
  }

  Future<void> updateTenant(Tenant tenant) async {
    final db = await database;
    await db.update(
      'tenants',
      tenant.toMap(),
      where: 'id = ?',
      whereArgs: [tenant.id],
    );
  }

  // Payment CRUD
  Future<void> insertPayment(Payment payment) async {
    final db = await database;
    await db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> getPaymentsByUnit(String unitId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'unitId = ?',
      whereArgs: [unitId],
      orderBy: 'paymentDate DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getAllPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'paymentDate DESC');
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<List<Payment>> getPaymentsByTenant(String tenantId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'tenantId = ?',
      whereArgs: [tenantId],
      orderBy: 'paymentDate DESC',
    );
    return maps.map((m) => Payment.fromMap(m)).toList();
  }

  Future<Payment?> findPaymentByCheckoutId(String checkoutId) async {
    final db = await database;
    final maps = await db.query(
      'payments',
      where: 'checkoutRequestId = ?',
      whereArgs: [checkoutId],
      limit: 1,
    );
    return maps.isEmpty ? null : Payment.fromMap(maps.first);
  }

  Future<void> updatePayment(Payment payment) async {
    final db = await database;
    await db.update(
      'payments',
      payment.toMap(),
      where: 'id = ?',
      whereArgs: [payment.id],
    );
  }

  // Full backup
  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    final props = await db.query('properties');
    final units = await db.query('units');
    final tenants = await db.query('tenants');
    final payments = await db.query('payments');
    return {
      'properties': props,
      'units': units,
      'tenants': tenants,
      'payments': payments,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('payments');
      await txn.delete('units');
      await txn.delete('properties');
      await txn.delete('tenants');

      for (final p in (data['properties'] as List)) {
        await txn.insert('properties', Map<String, dynamic>.from(p));
      }
      for (final t in (data['tenants'] as List)) {
        await txn.insert('tenants', Map<String, dynamic>.from(t));
      }
      for (final u in (data['units'] as List)) {
        await txn.insert('units', Map<String, dynamic>.from(u));
      }
      for (final pay in (data['payments'] as List)) {
        await txn.insert('payments', Map<String, dynamic>.from(pay));
      }
    });
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
