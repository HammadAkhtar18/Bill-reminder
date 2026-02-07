import 'package:flutter/material.dart';

enum BillCategory {
  utilities,
  rent,
  subscription,
  creditCard,
  insurance,
  other,
}

enum RecurrenceType {
  oneTime,
  monthly,
  yearly,
  custom,
}

class Bill {
  Bill({
    this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.category,
    this.notes,
    this.isPaid = false,
    this.paymentDate,
    this.recurrenceType = RecurrenceType.oneTime,
    this.customIntervalDays,
  });

  final int? id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final BillCategory category;
  final String? notes;
  final bool isPaid;
  final DateTime? paymentDate;
  final RecurrenceType recurrenceType;
  final int? customIntervalDays;

  Bill copyWith({
    int? id,
    String? name,
    double? amount,
    DateTime? dueDate,
    BillCategory? category,
    String? notes,
    bool? isPaid,
    DateTime? paymentDate,
    RecurrenceType? recurrenceType,
    int? customIntervalDays,
  }) {
    return Bill(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      isPaid: isPaid ?? this.isPaid,
      paymentDate: paymentDate ?? this.paymentDate,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      customIntervalDays: customIntervalDays ?? this.customIntervalDays,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'due_date': dueDate.toIso8601String(),
      'category': category.name,
      'notes': notes,
      'is_paid': isPaid ? 1 : 0,
      'payment_date': paymentDate?.toIso8601String(),
      'recurrence_type': recurrenceType.name,
      'custom_interval_days': customIntervalDays,
    };
  }

  factory Bill.fromMap(Map<String, dynamic> map) {
    return Bill(
      id: map['id'] as int?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      category: BillCategory.values.firstWhere(
        (value) => value.name == map['category'],
        orElse: () => BillCategory.other,
      ),
      notes: map['notes'] as String?,
      isPaid: (map['is_paid'] as int) == 1,
      paymentDate: map['payment_date'] != null
          ? DateTime.parse(map['payment_date'] as String)
          : null,
      recurrenceType: RecurrenceType.values.firstWhere(
        (value) => value.name == map['recurrence_type'],
        orElse: () => RecurrenceType.oneTime,
      ),
      customIntervalDays: map['custom_interval_days'] as int?,
    );
  }

  bool get isOverdue =>
      !isPaid && dueDate.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  bool get isUpcoming =>
      !isPaid && dueDate.isAfter(DateTime.now()) &&
      dueDate.isBefore(DateTime.now().add(const Duration(days: 7)));

  String get recurrenceLabel {
    switch (recurrenceType) {
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.custom:
        return 'Every ${customIntervalDays ?? 0} days';
      case RecurrenceType.oneTime:
      default:
        return 'One-time';
    }
  }

  Color statusColor(ThemeData theme) {
    if (isPaid) {
      return Colors.green.shade600;
    }
    if (isOverdue) {
      return Colors.red.shade600;
    }
    if (isUpcoming) {
      return Colors.orange.shade600;
    }
    return theme.colorScheme.primary;
  }
}
