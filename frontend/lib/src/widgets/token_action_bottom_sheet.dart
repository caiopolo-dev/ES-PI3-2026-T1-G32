// Autor: Gustavo Alves de Siqueira Costa
// Data: 15/05/2026
// Descrição: Bottom sheet de ações sobre um token (comprar mais ou criar ordem de venda)

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

Future<String?> showTokenActionsSheet(
  BuildContext context, {
  required String startupNome,
  required int quantidade,
  required double valorAtual,
  String? logoUrl,
}) {
  return showModalBottomSheet<String>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TokenActionsContent(
      startupNome: startupNome,
      quantidade: quantidade,
      valorAtual: valorAtual,
      logoUrl: logoUrl,
    ),
  );
}

class _TokenActionsContent extends StatelessWidget {
  final String startupNome;
  final int quantidade;
  final double valorAtual;
  final String? logoUrl;

  const _TokenActionsContent({
    required this.startupNome,
    required this.quantidade,
    required this.valorAtual,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.cinza300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.azul.withValues(alpha: 0.1),
                backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                child: logoUrl == null
                    ? const Icon(Icons.business, color: AppColors.azul, size: 26)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startupNome,
                      style: const TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$quantidade tokens · ${fmt.format(valorAtual)}/un',
                      style: const TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 13,
                        color: AppColors.cinza500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'sell'),
                  icon: const Icon(Icons.arrow_upward, size: 18),
                  label: const Text('Criar ordem de venda'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.vermelho,
                    side: const BorderSide(color: AppColors.vermelho),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'buy'),
                  icon: const Icon(Icons.arrow_downward, size: 18),
                  label: const Text('Comprar mais'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
