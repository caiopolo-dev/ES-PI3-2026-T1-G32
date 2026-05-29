// Caio Ferreira Polo - 25002823
// widget de graficos

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class GraficoLinha extends StatelessWidget {
  final List<FlSpot> pontos;
  final List<String> labelsInferiores;
  final String Function(double valor) formatarValorEsquerda;
  final Color? cor;

  const GraficoLinha({
    super.key,
    required this.pontos,
    required this.labelsInferiores,
    required this.formatarValorEsquerda,
    this.cor,
  });

  @override
  Widget build(BuildContext context) {
    if (pontos.length < 2) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cinza200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Sem dados suficientes para o gráfico',
            style: TextStyle(color: AppColors.cinza400, fontSize: 14),
          ),
        ),
      );
    }

    final minY = _menorValorY();
    final maxY = _maiorValorY();
    final intervaloY = _calcularIntervaloY(minY, maxY);
    final intervaloX = _calcularIntervaloX();

    return Container(
      height: 180,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cinza200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (pontos.length - 1).toDouble(),
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: intervaloY,
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: intervaloX,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();

                  if (index < 0 || index >= labelsInferiores.length) {
                    return const SizedBox.shrink();
                  }

                  if (index % intervaloX.toInt() != 0 &&
                      index != labelsInferiores.length - 1) {
                    return const SizedBox.shrink();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labelsInferiores[index],
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.cinza700,
                      ),
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 46,
                interval: intervaloY,
                getTitlesWidget: (value, meta) {
                  return Text(
                    formatarValorEsquerda(value),
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.cinza700,
                    ),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(color: AppColors.cinza400),
              bottom: BorderSide(color: AppColors.cinza400),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                formatarValorEsquerda(s.y),
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              )).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: pontos,
              isCurved: false,
              barWidth: 2.5,
              color: cor ?? AppColors.preto,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }

  double _menorValorY() {
    double menor = pontos.first.y;

    for (final ponto in pontos) {
      if (ponto.y < menor) {
        menor = ponto.y;
      }
    }

    return menor;
  }

  double _maiorValorY() {
    double maior = pontos.first.y;

    for (final ponto in pontos) {
      if (ponto.y > maior) {
        maior = ponto.y;
      }
    }

    return maior;
  }

  double _calcularIntervaloY(double minY, double maxY) {
    final diferenca = maxY - minY;

    if (diferenca <= 0) {
      return 1;
    }

    return diferenca / 3;
  }

  double _calcularIntervaloX() {
    if (pontos.length <= 5) {
      return 1;
    }

    return (pontos.length / 4).ceilToDouble();
  }
}