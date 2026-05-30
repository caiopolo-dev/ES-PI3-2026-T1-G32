// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card de oferta de token exibido no balcão de negociação

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class OfferCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final VoidCallback onTap;
  final String? logoUrl;
  final bool showLogo;

  const OfferCard({
    super.key,
    required this.data,
    required this.currency,
    required this.onTap,
    this.logoUrl,
    this.showLogo = true,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['startupName'] ?? data['startupId'] ?? '—').toString();
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final centavos = (data['valorUnitarioCentavos'] as num?)?.toDouble() ?? 0;
    final preco = centavos / 100;
    final mercadoCentavos = (data['precoMercadoCentavos'] as num?)?.toDouble() ?? 0;
    final temMercado = mercadoCentavos > 0;
    final abaixo = temMercado && centavos < mercadoCentavos;
    final acima = temMercado && centavos > mercadoCentavos;

    final accentColor = acima ? AppColors.vermelho : AppColors.verde;

    final double diffPct = temMercado && mercadoCentavos > 0
        ? ((centavos - mercadoCentavos) / mercadoCentavos * 100).abs()
        : 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
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
                Container(width: 5, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (showLogo) ...[
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: accentColor.withValues(alpha: 0.1),
                                backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                                child: logoUrl == null
                                    ? Icon(Icons.business, color: accentColor, size: 20)
                                    : null,
                              ),
                              const SizedBox(width: 12),
                            ],
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currency.format(preco),
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                const Text(
                                  'por token',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 10,
                                    color: AppColors.cinza500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Container(height: 1, color: AppColors.cinza200),
                        const SizedBox(height: 10),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.azul.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.toll_outlined, size: 13, color: AppColors.azul),
                                  const SizedBox(width: 4),
                                  Text(
                                    NumberFormat('#,##0', 'pt_BR').format(amount),
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.azul,
                                    ),
                                  ),
                                  const Text(
                                    ' tokens',
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.azul,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            if (temMercado)
                              Row(
                                children: [
                                  Text(
                                    'Mercado ${currency.format(mercadoCentavos / 100)}',
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 11,
                                      color: AppColors.cinza500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: !temMercado || diffPct == 0
                                        ? Text(
                                            'No mercado',
                                            style: TextStyle(
                                              fontFamily: 'JosefinSans',
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: accentColor,
                                            ),
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                abaixo ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                                                size: 14,
                                                color: accentColor,
                                              ),
                                              Text(
                                                '${diffPct.toStringAsFixed(2)}%',
                                                style: TextStyle(
                                                  fontFamily: 'JosefinSans',
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
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
    );
  }
}