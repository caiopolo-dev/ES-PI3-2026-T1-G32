// Autor: Gustavo Alves de Siqueira Costa
// Data: 14/05/2026
// Descrição: Widget reutilizável para exibir saldo com toggle de visibilidade

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SaldoDisplay extends StatelessWidget {
  final double saldo;
  final bool visivel;
  final String label;
  final Color labelColor;
  final Color balanceColor;
  final Color eyeColor;
  final double balanceFontSize;
  final ValueChanged<bool>? onVisibilityChanged;

  const SaldoDisplay({
    super.key,
    required this.saldo,
    required this.visivel,
    required this.label,
    required this.labelColor,
    required this.balanceColor,
    required this.eyeColor,
    this.balanceFontSize = 28,
    this.onVisibilityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 13,
                color: labelColor,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => onVisibilityChanged?.call(!visivel),
              child: Icon(
                visivel ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20,
                color: eyeColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          visivel ? fmt.format(saldo) : 'R\$ ••••••',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: balanceFontSize,
            fontWeight: FontWeight.bold,
            color: balanceColor,
          ),
        ),
      ],
    );
  }
}
