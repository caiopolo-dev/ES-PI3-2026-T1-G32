// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Badge de variação diária ("hoje" + seta + %)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class DailyVariationBadge extends StatelessWidget {
  final double? variacaoPct;

  const DailyVariationBadge({super.key, required this.variacaoPct});

  @override
  Widget build(BuildContext context) {
    if (variacaoPct == null) return const SizedBox.shrink();

    final pct = variacaoPct!;
    final color = pct > 0
        ? AppColors.verde
        : pct < 0
            ? AppColors.vermelho
            : AppColors.cinza500;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.cinza200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'hoje',
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.cinza700,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pct >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: 14,
                color: color,
              ),
              Text(
                '${pct.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
