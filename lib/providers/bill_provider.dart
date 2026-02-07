import 'package:flutter/material.dart';

import '../models/bill.dart';
import '../models/payment.dart';
import '../services/database_helper.dart';
import '../services/notification_service.dart';

class BillProvider extends ChangeNotifier {
  BillProvider() {
    loadBills();
  }

  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService.instance;

  final List<Bill> _bills = [];
  final List<Payment> _payments = [];
  bool _isLoading = false;

  List<Bill> get bills => List.unmodifiable(_bills);
  List<Payment> get payments => List.unmodifiable(_payments);
  bool get isLoading => _isLoading;

  /// Loads bills and payment history from the local database.
  Future<void> loadBills() async {
    _isLoading = true;
    notifyListeners();
    final fetchedBills = await _databaseHelper.fetchBills();
    final fetchedPayments = await _databaseHelper.fetchPayments();
    _bills
      ..clear()
      ..addAll(fetchedBills);
    _payments
      ..clear()
      ..addAll(fetchedPayments);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addBill(Bill bill) async {
    final id = await _databaseHelper.insertBill(bill);
    final created = bill.copyWith(id: id);
    _bills.add(created);
    await _notificationService.scheduleBillNotifications(created);
    notifyListeners();
  }

  Future<void> updateBill(Bill bill) async {
    await _databaseHelper.updateBill(bill);
    final index = _bills.indexWhere((existing) => existing.id == bill.id);
    if (index != -1) {
      _bills[index] = bill;
    }
    await _notificationService.scheduleBillNotifications(bill);
    notifyListeners();
  }

  Future<void> deleteBill(Bill bill) async {
    if (bill.id == null) return;
    await _databaseHelper.deleteBill(bill.id!);
    _bills.removeWhere((item) => item.id == bill.id);
    _payments.removeWhere((payment) => payment.billId == bill.id);
    await _notificationService.cancelBillNotifications(bill.id!);
    notifyListeners();
  }

  /// Records a payment and applies recurrence to generate the next due date.
  Future<void> markBillPaid(Bill bill, DateTime paymentDate) async {
    if (bill.id == null) return;
    final payment = Payment(
      billId: bill.id!,
      amount: bill.amount,
      paymentDate: paymentDate,
    );
    await _databaseHelper.insertPayment(payment);
    _payments.insert(0, payment);

    final updated = _applyRecurrence(bill, paymentDate);
    await _databaseHelper.updateBill(updated);
    final index = _bills.indexWhere((item) => item.id == bill.id);
    if (index != -1) {
      _bills[index] = updated;
    }
    await _notificationService.scheduleBillNotifications(updated);
    notifyListeners();
  }

  Bill _applyRecurrence(Bill bill, DateTime paymentDate) {
    if (bill.recurrenceType == RecurrenceType.oneTime) {
      return bill.copyWith(isPaid: true, paymentDate: paymentDate);
    }

    DateTime nextDueDate = bill.dueDate;
    switch (bill.recurrenceType) {
      case RecurrenceType.monthly:
        nextDueDate = DateTime(bill.dueDate.year, bill.dueDate.month + 1, bill.dueDate.day);
        break;
      case RecurrenceType.yearly:
        nextDueDate = DateTime(bill.dueDate.year + 1, bill.dueDate.month, bill.dueDate.day);
        break;
      case RecurrenceType.custom:
        nextDueDate = bill.dueDate.add(Duration(days: bill.customIntervalDays ?? 0));
        break;
      case RecurrenceType.oneTime:
        break;
    }

    return bill.copyWith(
      dueDate: nextDueDate,
      isPaid: false,
      paymentDate: null,
    );
  }

  List<Bill> upcomingBills() {
    final now = DateTime.now();
    final end = now.add(const Duration(days: 7));
    return _bills
        .where((bill) => bill.dueDate.isAfter(now) && bill.dueDate.isBefore(end))
        .toList();
  }

  List<Bill> overdueBills() {
    return _bills.where((bill) => bill.isOverdue).toList();
  }

  double totalDueThisMonth() {
    final now = DateTime.now();
    return _bills
        .where((bill) => bill.dueDate.year == now.year && bill.dueDate.month == now.month)
        .fold(0, (sum, bill) => sum + bill.amount);
  }
}
