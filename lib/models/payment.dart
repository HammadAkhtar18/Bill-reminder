class Payment {
  Payment({
    this.id,
    required this.billId,
    required this.amount,
    required this.paymentDate,
  });

  final int? id;
  final int billId;
  final double amount;
  final DateTime paymentDate;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bill_id': billId,
      'amount': amount,
      'payment_date': paymentDate.toIso8601String(),
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as int?,
      billId: map['bill_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      paymentDate: DateTime.parse(map['payment_date'] as String),
    );
  }
}
