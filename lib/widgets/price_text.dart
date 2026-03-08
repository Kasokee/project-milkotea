import 'package:flutter/material.dart';

import '../services/currency_service.dart';

class PriceText extends StatelessWidget {
  const PriceText(this.amount, {super.key, this.style});

  final double amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final formatter = CurrencyService();
    return Text(formatter.format(amount), style: style);
  }
}
