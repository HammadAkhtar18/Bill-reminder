import 'package:intl/intl.dart';

class Formatters {
  Formatters(this.currencyCode);

  final String currencyCode;

  String currency(double amount) {
    return NumberFormat.simpleCurrency(name: currencyCode).format(amount);
  }

  String date(DateTime date) {
    return DateFormat.yMMMd().format(date);
  }
}
