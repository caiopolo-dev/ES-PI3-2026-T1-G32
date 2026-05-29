// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card de transação da carteira (compra, venda, depósito, cancelamento)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_stat.dart';
import 'package:intl/intl.dart';

class WalletTransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  final String? logoUrl;
  final bool saldoVisivel;
  final NumberFormat currencyFormat;

  const WalletTransactionCard({
    super.key,
    required this.tx,
    required this.logoUrl,
    required this.saldoVisivel,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = tx['type'] as String? ?? 'buy';
    final isDeposit = tipo == 'deposit';
    final isSell = tipo == 'sell';
    final isReturn = tipo == 'return';
    final valor = ((tx['totalCents'] as num?) ?? 0).toDouble() / 100;
    final dataStr = tx['createdAt'] != null
        ? DateFormat('dd/MM/yy · HH:mm')
            .format(DateTime.parse(tx['createdAt'] as String))
        : '—';
    final quantidade = (tx['quantity'] as num?)?.toInt() ?? 0;
    final precoPorToken =
        ((tx['pricePerTokenCents'] as num?)?.toDouble() ?? 0) / 100;
    final titulo =
        tx['startupName'] as String? ?? tx['startupId'] as String? ?? '—';

    final Color accentColor;
    final String labelTipo;
    final IconData iconeTipo;
    if (isDeposit) {
      accentColor = AppColors.verde;
      labelTipo = 'Depósito';
      iconeTipo = Icons.account_balance_wallet_outlined;
    } else if (isSell) {
      accentColor = AppColors.verde;
      labelTipo = 'Venda';
      iconeTipo = Icons.arrow_upward;
    } else if (isReturn) {
      accentColor = AppColors.vermelho;
      labelTipo = 'Ordem Cancelada';
      iconeTipo = Icons.cancel_outlined;
    } else {
      accentColor = AppColors.vermelho;
      labelTipo = 'Compra';
      iconeTipo = Icons.arrow_downward;
    }

    return Container(
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
                          CircleAvatar(
                            radius: 20,
                            backgroundColor:
                                accentColor.withValues(alpha: 0.1),
                            backgroundImage: logoUrl != null
                                ? NetworkImage(logoUrl!)
                                : null,
                            child: logoUrl == null
                                ? Icon(iconeTipo,
                                    color: accentColor, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isDeposit ? 'Depósito em conta' : titulo,
                                  style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accentColor.withValues(
                                            alpha: 0.12),
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        labelTipo,
                                        style: TextStyle(
                                          fontFamily: 'JosefinSans',
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      dataStr,
                                      style: const TextStyle(
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
                          Text(
                            isReturn
                                ? '—'
                                : saldoVisivel
                                    ? '${isSell || isDeposit ? '+' : '-'} ${currencyFormat.format(valor)}'
                                    : '••••••',
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      if (!isDeposit) ...[
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
                              label: 'Preço/token',
                              value: saldoVisivel
                                  ? currencyFormat.format(precoPorToken)
                                  : '••••',
                              alignEnd: true,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
