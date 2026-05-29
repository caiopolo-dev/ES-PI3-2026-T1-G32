// Autor: Gustavo Alves de Siqueira Costa
// Data: 28/05/2026
// Descrição: Botões padronizados reutilizáveis do app (primary, secondary, outline)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool elevated;
  final double verticalPadding;
  final double fontSize;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.elevated = false,
    this.verticalPadding = 14,
    this.fontSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.azul,
        foregroundColor: AppColors.branco,
        elevation: elevated ? 6 : 0,
        shadowColor:
            elevated ? AppColors.azul.withValues(alpha: 0.4) : null,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: elevated
              ? const BorderSide(color: AppColors.azul800, width: 0.25)
              : BorderSide.none,
        ),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.branco,
              ),
            )
          : Text(
              label,
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: fontSize,
              ),
            ),
    );
  }
}

class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double verticalPadding;

  const AppSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.verticalPadding = 10,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cinza200,
        foregroundColor: AppColors.preto,
        elevation: 0,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        side: const BorderSide(color: AppColors.cinza400),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
      ),
    );
  }
}

class AppOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double borderRadius;
  final double verticalPadding;

  const AppOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.cinza400,
    this.borderRadius = 24,
    this.verticalPadding = 14,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        side: BorderSide(color: color),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
      ),
    );
  }
}
