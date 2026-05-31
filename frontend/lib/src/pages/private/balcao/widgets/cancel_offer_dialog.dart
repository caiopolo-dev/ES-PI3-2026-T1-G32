// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Dialog de confirmação de cancelamento de oferta

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class CancelOfferDialog extends StatelessWidget {
  final Map<String, dynamic> offer;
  final NumberFormat currency;

  const CancelOfferDialog({
    super.key,
    required this.offer,
    required this.currency,
  });

  /// Diálogo de confirmação para cancelar uma oferta.
  ///
  /// Exibe informações resumidas da oferta (startup, quantidade e preço por
  /// token) e oferece duas ações:
  /// - `Cancelar`: fecha o diálogo sem realizar o cancelamento (retorna false)
  /// - `Confirmar`: fecha o diálogo confirmando o cancelamento (retorna true)
  ///
  /// Recebe `offer` como `Map<String, dynamic>` e `currency` para formatar
  /// valores monetários. Mantém toda a lógica de UI neste widget; a ação
  /// real de cancelamento deve ser executada pelo chamador (ex: via service).

  @override
  Widget build(BuildContext context) {
    final name = (offer['startupName'] ?? offer['startupId'] ?? '—').toString();
    final amount = (offer['amount'] as num?)?.toInt() ?? 0;
    final centavos = (offer['valorUnitarioCentavos'] as num?)?.toDouble() ?? 0;
    final preco = centavos / 100;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      backgroundColor: AppColors.branco,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.vermelho.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.remove_circle_outline,
                  color: AppColors.vermelho, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Cancelar oferta',
              style: TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cinza100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cinza200),
              ),
              child: Column(
                children: [
                  _row('Startup', name),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tokens',
                          style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 12,
                              color: AppColors.cinza500)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.azul.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.toll_outlined,
                                size: 12, color: AppColors.azul),
                            const SizedBox(width: 4),
                            Text('$amount tokens',
                                style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.azul)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _row('Preço/token', currency.format(preco)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: AppSecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.vermelho,
                      foregroundColor: AppColors.branco,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('Confirmar',
                        style: TextStyle(
                            fontFamily: 'JosefinSans', fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
        Text(label,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 12,
            color: AppColors.cinza500)),
        Text(value,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 13,
            fontWeight: FontWeight.bold)),
        ],
      );
}
