// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widget de stat do header do card da carteira (label + valor colorido)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final Color labelColor;
  final bool alignEnd;

  const CardStat({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.preto,
    this.labelColor = AppColors.cinza500,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: labelColor,
            fontFamily: 'JosefinSans',
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'JosefinSans',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
