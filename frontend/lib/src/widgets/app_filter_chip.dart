// Autor: Gustavo Alves de Siqueira Costa
// Data: 21/05/2026
// Descrição: Chip de filtro/ordenação reutilizável com estado selecionado

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class AppFilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const AppFilterChip({
    super.key,
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.azul : AppColors.cinza200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? AppColors.branco : AppColors.cinza700,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.branco : AppColors.cinza700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
