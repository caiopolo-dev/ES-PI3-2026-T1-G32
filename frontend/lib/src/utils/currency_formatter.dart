// Autor: Gustavo Alves de Siqueira Costa
// Data: 28/05/2026
// Descrição: Formatador de entrada de texto para valores monetários em reais

import 'package:flutter/services.dart';

class CurrencyFormatter extends TextInputFormatter {
  static const int _maxCents = 5000000;

  static String formatCents(int cents) {
    final c = cents.clamp(0, _maxCents);
    final reais = c ~/ 100;
    final centavos = (c % 100).toString().padLeft(2, '0');
    final reaisStr = reais.toString();
    final buf = StringBuffer();
    for (int i = 0; i < reaisStr.length; i++) {
      if (i > 0 && (reaisStr.length - i) % 3 == 0) buf.write('.');
      buf.write(reaisStr[i]);
    }
    return '${buf.toString()},$centavos';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return newValue.copyWith(
          text: '', selection: const TextSelection.collapsed(offset: 0));
    }
    int cents = int.tryParse(digits) ?? 0;
    if (cents > _maxCents) cents = _maxCents;
    final formatted = formatCents(cents);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}