// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widget de stat (label + valor) reutilizado nos cards da carteira

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const WalletStat({
    super.key,
    required this.label,
    required this.value,
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
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 11,
            color: AppColors.cinza500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
