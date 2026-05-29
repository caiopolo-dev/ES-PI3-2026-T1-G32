// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card financeiro da carteira com saldo, portfólio e total de tokens

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/card_stat.dart';

class WalletFinanceCard extends StatelessWidget {
  final double saldo;
  final bool saldoVisivel;
  final double totalInvestido;
  final double valorAtualPortfolio;
  final int totalTokens;
  final NumberFormat currencyFormat;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onDepositar;

  const WalletFinanceCard({
    super.key,
    required this.saldo,
    required this.saldoVisivel,
    required this.totalInvestido,
    required this.valorAtualPortfolio,
    required this.totalTokens,
    required this.currencyFormat,
    required this.onVisibilityChanged,
    required this.onDepositar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.azul, AppColors.preto],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.azul.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SaldoDisplay(
                saldo: saldo,
                visivel: saldoVisivel,
                label: 'Saldo em conta',
                labelColor: AppColors.branco,
                balanceColor: AppColors.branco,
                eyeColor: AppColors.branco54,
                balanceFontSize: 24,
                onVisibilityChanged: onVisibilityChanged,
              ),
              GestureDetector(
                onTap: onDepositar,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.azul800.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppColors.azul200.withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 17, color: AppColors.branco),
                      SizedBox(width: 6),
                      Text(
                        'Depositar',
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 14,
                          color: AppColors.branco,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
              height: 1,
              color: AppColors.branco.withValues(alpha: 0.15)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CardStat(
                  label: 'Valor investido',
                  value: saldoVisivel
                      ? currencyFormat.format(totalInvestido)
                      : '••••••',
                  labelColor: AppColors.branco,
                  valueColor: AppColors.branco,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: CardStat(
                    label: 'Portfólio',
                    value: saldoVisivel
                        ? currencyFormat.format(valorAtualPortfolio)
                        : '••••••',
                    labelColor: AppColors.branco,
                    valueColor: valorAtualPortfolio >= totalInvestido
                        ? AppColors.verde
                        : AppColors.vermelho,
                    alignEnd: true,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Tokens',
                        style: TextStyle(
                          color: AppColors.branco,
                          fontFamily: 'JosefinSans',
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.branco.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.toll_outlined,
                                size: 13, color: AppColors.branco),
                            const SizedBox(width: 4),
                            Text(
                              NumberFormat('#,##0', 'pt_BR').format(totalTokens),
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.branco,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
