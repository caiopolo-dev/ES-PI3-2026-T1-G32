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
          Container(
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cinza200),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(width: 5, color: AppColors.azul),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  AppColors.azul.withValues(alpha: 0.1),
                              backgroundImage: logoUrl != null
                                  ? NetworkImage(logoUrl!)
                                  : null,
                              child: logoUrl == null
                                  ? const Icon(
                                      Icons.business,
                                      color: AppColors.azul,
                                      size: 20,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    startupNome,
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.azul
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.toll_outlined,
                                          size: 13,
                                          color: AppColors.azul,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '$quantidade tokens',
                                          style: const TextStyle(
                                            fontFamily: 'JosefinSans',
                                            fontSize: 12,
                                            color: AppColors.azul,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  fmt.format(valorAtual),
                                  style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.azul,
                                  ),
                                ),
                                const Text(
                                  'preço de mercado',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 11,
                                    color: AppColors.cinza500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
