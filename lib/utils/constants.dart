import 'package:flutter/material.dart';

import '../models/bill.dart';

const appTitle = 'Bill Reminder';

const Map<BillCategory, String> categoryLabels = {
  BillCategory.utilities: 'Utilities',
  BillCategory.rent: 'Rent',
  BillCategory.subscription: 'Subscription',
  BillCategory.creditCard: 'Credit Card',
  BillCategory.insurance: 'Insurance',
  BillCategory.other: 'Other',
};

const Map<RecurrenceType, String> recurrenceLabels = {
  RecurrenceType.oneTime: 'One-time',
  RecurrenceType.monthly: 'Monthly',
  RecurrenceType.yearly: 'Yearly',
  RecurrenceType.custom: 'Custom',
};

const List<String> supportedCurrencies = [
  'USD',
  'EUR',
  'GBP',
  'JPY',
  'CAD',
  'AUD',
];

ColorScheme buildColorScheme(Brightness brightness) {
  const seed = Color(0xFF1B5E7A);
  return ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
}
