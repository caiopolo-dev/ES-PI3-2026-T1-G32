// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widgets primitivos compartilhados do fluxo de compra e venda

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class StepProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final Color color;

  const StepProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(totalSteps, (i) => Expanded(
          child: Container(
            margin: EdgeInsets.only(
              left: i > 0 ? 4 : 0,
              right: i < totalSteps - 1 ? 4 : 0,
            ),
            height: 3,
            decoration: BoxDecoration(
              color: i <= currentStep ? color : AppColors.cinza200,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
      ),
    );
  }
}

class StepButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const StepButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          fixedSize: const Size(44, 44),
          padding: EdgeInsets.zero,
          foregroundColor: AppColors.preto,
          side: const BorderSide(color: AppColors.cinza300),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      );
}

class ConfirmDivider extends StatelessWidget {
  const ConfirmDivider({super.key});

  @override
  Widget build(BuildContext context) =>
      Container(height: 1, color: AppColors.cinza200,
          margin: const EdgeInsets.symmetric(vertical: 12));
}

class ConfirmRow extends StatelessWidget {
  final String label;
  final String value;
  const ConfirmRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 13,
                  color: AppColors.cinza500)),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      );
}

class ConfirmRowTokens extends StatelessWidget {
  final int quantity;
  const ConfirmRowTokens({super.key, required this.quantity});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Tokens',
              style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 13,
                  color: AppColors.cinza500)),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.azul.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.toll_outlined,
                    size: 13, color: AppColors.azul),
                const SizedBox(width: 4),
                Text(
                  '$quantity tokens',
                  style: const TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.azul,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}
