// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Widgets de card da carteira (token e transação)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
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
    final quantidade = (token['quantidade'] as num?)?.toInt() ?? 0;
    final totalAtual = valorAtual * quantidade;
    final totalInvestido = precoMedio * quantidade;
    final positivo = valorAtual >= precoMedio;
    final variacaoPct =
        precoMedio > 0 ? (valorAtual - precoMedio) / precoMedio * 100 : 0.0;
    final variacaoLabel =
        '${variacaoPct >= 0 ? '+' : ''}${variacaoPct.toStringAsFixed(1)}%';
    final accentColor = variacaoPct == 0
        ? AppColors.azul
        : (positivo ? AppColors.verde : AppColors.vermelho);

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
                            CircleAvatar(
                              radius: 22,
                              backgroundColor:
                                  accentColor.withValues(alpha: 0.1),
                              backgroundImage: logoUrl != null
                                  ? NetworkImage(logoUrl!)
                                  : null,
                              child: logoUrl == null
                                  ? Icon(Icons.business,
                                      color: accentColor, size: 20)
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
                                    color: accentColor,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    variacaoLabel,
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
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
                            Row(
                              children: [
                                _WalletStat(
                                  label: 'Investido',
                                  value: saldoVisivel
                                      ? currencyFormat.format(totalInvestido)
                                      : '••••',
                                ),
                                const SizedBox(width: 16),
                                _WalletStat(
                                  label: 'Atual',
                                  value: saldoVisivel
                                      ? currencyFormat.format(totalAtual)
                                      : '••••',
                                  valueColor: accentColor,
                                  alignEnd: true,
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
      accentColor = AppColors.azul;
      labelTipo = 'Depósito';
      iconeTipo = Icons.account_balance_wallet_outlined;
    } else if (isSell) {
      accentColor = AppColors.verde;
      labelTipo = 'Venda';
      iconeTipo = Icons.arrow_upward;
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
                                        color:
                                            accentColor.withValues(alpha: 0.12),
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
                            saldoVisivel
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
                            _WalletStat(
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

class _WalletStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool alignEnd;

  const _WalletStat({
    required this.label,
    required this.value,
    this.valueColor,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 11,
            color: AppColors.cinza500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
