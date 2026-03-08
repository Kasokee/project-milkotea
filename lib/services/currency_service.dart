import 'package:intl/intl.dart';

class CurrencyService {
  CurrencyService() : _formatter = NumberFormat.currency(locale: 'en_PH', symbol: '₱');

  final NumberFormat _formatter;

  String format(double amount) => _formatter.format(amount);
}