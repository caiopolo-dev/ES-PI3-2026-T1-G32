// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widgets da tela inicial — card financeiro e seção do gráfico de portfólio

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class HomeFinanceCard extends StatelessWidget {
  final double saldo;
  final bool saldoVisivel;
  final double valorPortfolio;
  final int totalTokens;
  final bool isLoading;
  final NumberFormat currencyFormat;
  final ValueChanged<bool> onVisibilityChanged;
  final VoidCallback onDepositar;

  const HomeFinanceCard({
    super.key,
    required this.saldo,
    required this.saldoVisivel,
    required this.valorPortfolio,
    required this.totalTokens,
    required this.isLoading,
    required this.currencyFormat,
    required this.onVisibilityChanged,
    required this.onDepositar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
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
      child: isLoading
          ? const SizedBox(
              height: 80,
              child: Center(
                child: CircularProgressIndicator(
                    color: AppColors.branco, strokeWidth: 2),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SaldoDisplay(
                      saldo: saldo,
                      visivel: saldoVisivel,
                      label: 'Saldo disponível',
                      labelColor: AppColors.branco,
                      balanceColor: AppColors.branco,
                      eyeColor: AppColors.branco54,
                      balanceFontSize: 32,
                      onVisibilityChanged: onVisibilityChanged,
                    ),
                    GestureDetector(
                      onTap: onDepositar,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10.5),
                        decoration: BoxDecoration(
                          color: AppColors.azul800.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.azul200.withValues(alpha: 0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add, size: 16, color: AppColors.branco),
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
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Portfólio',
                            style: TextStyle(
                                color: AppColors.branco,
                                fontFamily: 'JosefinSans',
                                fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          saldoVisivel
                              ? currencyFormat.format(valorPortfolio)
                              : '••••••',
                          style: const TextStyle(
                              color: AppColors.branco,
                              fontFamily: 'JosefinSans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tokens',
                            style: TextStyle(
                                color: AppColors.branco,
                                fontFamily: 'JosefinSans',
                                fontSize: 11)),
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
                                NumberFormat('#,##0', 'pt_BR')
                                    .format(totalTokens),
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
                  ],
                ),
              ],
            ),
    );
  }
}

class PortfolioChartSection extends StatelessWidget {
  final List<FlSpot> pontos;
  final List<String> labels;
  final Color cor;
  final List<String> periods;
  final int selectedPeriod;
  final ValueChanged<int> onPeriodChanged;
  final String Function(double) formatLabel;
  final List<Map<String, dynamic>> portfolioHistory;

  const PortfolioChartSection({
    super.key,
    required this.pontos,
    required this.labels,
    required this.cor,
    required this.periods,
    required this.selectedPeriod,
    required this.onPeriodChanged,
    required this.formatLabel,
    required this.portfolioHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Valorização do portfólio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'JosefinSans',
              ),
            ),
            if (portfolioHistory.isNotEmpty)
              Builder(builder: (_) {
                final pct = (portfolioHistory.last['returnPercent'] as num?)
                        ?.toDouble() ??
                    0.0;
                final isPos = pct > 0.05;
                final isNeg = pct < -0.05;
                final cor = isPos
                    ? AppColors.verde
                    : isNeg
                        ? AppColors.vermelho
                        : AppColors.cinza400;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${isPos ? '+' : ''}${pct.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: cor,
                    ),
                  ),
                );
              }),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(periods.length, (i) {
              final selected = selectedPeriod == i;
              return Padding(
                padding:
                    EdgeInsets.only(right: i < periods.length - 1 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => onPeriodChanged(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color:
                          selected ? AppColors.azul : AppColors.transparente,
                      border: Border.all(
                          color: selected
                              ? AppColors.azul
                              : AppColors.cinza400),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      periods[i],
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 12,
                        color: selected ? AppColors.branco : AppColors.preto,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        GraficoLinha(
          pontos: pontos,
          labelsInferiores: labels,
          formatarValorEsquerda: formatLabel,
          cor: cor,
        ),
      ],
    );
  }
}
