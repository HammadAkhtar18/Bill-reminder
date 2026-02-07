import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/bill.dart';
import '../models/payment.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();

  DatabaseHelper._internal();

  static const _databaseName = 'bill_reminder.db';
  static const _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    return openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  /// Build the initial schema for bills and payment history.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE bills(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date TEXT NOT NULL,
        category TEXT NOT NULL,
        notes TEXT,
        is_paid INTEGER NOT NULL,
        payment_date TEXT,
        recurrence_type TEXT NOT NULL,
        custom_interval_days INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bill_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_date TEXT NOT NULL,
        FOREIGN KEY (bill_id) REFERENCES bills(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertBill(Bill bill) async {
    final db = await database;
    return db.insert('bills', bill.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> updateBill(Bill bill) async {
    final db = await database;
    return db.update('bills', bill.toMap(), where: 'id = ?', whereArgs: [bill.id]);
  }

  Future<int> deleteBill(int id) async {
    final db = await database;
    await db.delete('payments', where: 'bill_id = ?', whereArgs: [id]);
    return db.delete('bills', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Bill>> fetchBills() async {
    final db = await database;
    final maps = await db.query('bills', orderBy: 'due_date ASC');
    return maps.map((map) => Bill.fromMap(map)).toList();
  }

  Future<int> insertPayment(Payment payment) async {
    final db = await database;
    return db.insert('payments', payment.toMap());
  }

  Future<List<Payment>> fetchPayments() async {
    final db = await database;
    final maps = await db.query('payments', orderBy: 'payment_date DESC');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }

  Future<List<Payment>> fetchPaymentsForBill(int billId) async {
    final db = await database;
    final maps = await db.query('payments',
        where: 'bill_id = ?', whereArgs: [billId], orderBy: 'payment_date DESC');
    return maps.map((map) => Payment.fromMap(map)).toList();
  }
}
