// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card de token da carteira com variação diária e preço médio

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_stat.dart';
import 'package:intl/intl.dart';

class WalletTokenCard extends StatelessWidget {
  final Map<String, dynamic> token;
  final String? logoUrl;
  final bool saldoVisivel;
  final VoidCallback onTap;
  final NumberFormat currencyFormat;

  const WalletTokenCard({
    super.key,
    required this.token,
    required this.logoUrl,
    required this.saldoVisivel,
    required this.onTap,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final precoMedio = (token['precoMedio'] as num?)?.toDouble() ?? 0.0;
    final valorAtual = (token['valorAtual'] as num?)?.toDouble() ?? 0.0;
    final precoAnteriorRaw = (token['precoAnterior'] as num?)?.toDouble() ?? 0.0;
    final quantidade = (token['quantidade'] as num?)?.toInt() ?? 0;
    final double? variacaoPct = precoAnteriorRaw > 0
        ? (valorAtual - precoAnteriorRaw) / precoAnteriorRaw * 100
        : null;
    final accentColor = variacaoPct == null
        ? AppColors.cinza400
        : variacaoPct > 0
            ? AppColors.verde
            : variacaoPct < 0
                ? AppColors.vermelho
                : AppColors.cinza400;
    final priceColor = variacaoPct == null
        ? AppColors.preto
        : variacaoPct > 0
            ? AppColors.verde
            : variacaoPct < 0
                ? AppColors.vermelho
                : AppColors.preto;
    final cardColor = accentColor;

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
                Container(width: 5, color: cardColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  cardColor.withValues(alpha: 0.1),
                              backgroundImage: logoUrl != null
                                  ? NetworkImage(logoUrl!)
                                  : null,
                              child: logoUrl == null
                                  ? Icon(Icons.business,
                                      color: cardColor, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                token['startupNome'] as String? ?? '—',
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
                                  '${currencyFormat.format(valorAtual)}/un',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: priceColor,
                                  ),
                                ),
                                DailyVariationBadge(variacaoPct: variacaoPct),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
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
                                    '${NumberFormat('#,##0', 'pt_BR').format(quantidade)} tokens',
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
                            WalletStat(
                              label: 'Preço médio pago',
                              value: saldoVisivel
                                  ? currencyFormat.format(precoMedio)
                                  : '••••',
                              alignEnd: true,
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
