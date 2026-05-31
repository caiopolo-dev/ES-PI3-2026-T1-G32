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
    // Se não houver pelo menos dois pontos, o gráfico não tem como ser desenhado.
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
    // O intervalo do eixo Y é calculado com base na amplitude dos valores.
    final intervaloY = _calcularIntervaloY(minY, maxY);
    // O eixo X usa uma distribuição diferente quando o período selecionado é 7D.
    final intervaloX = _calcularIntervaloX();
    // No 7D, os rótulos inferiores são distribuídos para mostrar os 7 dias do intervalo.
    final rotulosDistribuidos = labelsInferiores.length == 7 && pontos.length > 1;
    // Lista de valores usados para controlar quais labels do eixo Y podem aparecer no 7D.
    final rotulosEixoY = rotulosDistribuidos
      ? _rotulosEixoYParaSeteDias(minY, maxY)
      : const <double>[];
    double? ultimoRotuloExibidoEixoY;

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
                  if (rotulosDistribuidos) {
                    final maxIndex = (pontos.length - 1).toDouble();
                    if (maxIndex <= 0) {
                      return const SizedBox.shrink();
                    }

                    final labelIndex = ((value / maxIndex) * (labelsInferiores.length - 1))
                        .round()
                        .clamp(0, labelsInferiores.length - 1);

                    if (labelIndex < 0 || labelIndex >= labelsInferiores.length) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labelsInferiores[labelIndex],
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.cinza700,
                        ),
                      ),
                    );
                  }

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
                  // No 7D, ocultamos valores muito próximos para evitar sobreposição visual.
                  if (rotulosDistribuidos) {
                    final toleranciaAlvo = (intervaloY / 2).clamp(0.04, 0.12);
                    final muitoProximoDoAnterior = ultimoRotuloExibidoEixoY != null &&
                        (value - ultimoRotuloExibidoEixoY!).abs() < (intervaloY * 0.7);
                    final ehRotuloAlvo = rotulosEixoY.any(
                      (rotulo) => (value - rotulo).abs() <= toleranciaAlvo,
                    );

                    if (!ehRotuloAlvo || muitoProximoDoAnterior) {
                      return const SizedBox.shrink();
                    }

                    ultimoRotuloExibidoEixoY = value;
                  }

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
    // Parte do primeiro ponto e procura o menor valor da série.
    double menor = pontos.first.y;

    for (final ponto in pontos) {
      if (ponto.y < menor) {
        menor = ponto.y;
      }
    }

    return menor;
  }

  double _maiorValorY() {
    // Parte do primeiro ponto e procura o maior valor da série.
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

    // Divide a amplitude em três faixas para manter alguns rótulos espaçados.
    return diferenca / 3;
  }

  List<double> _rotulosEixoYParaSeteDias(double minY, double maxY) {
    final diferenca = maxY - minY;

    if (diferenca <= 0) {
      return [double.parse(minY.toStringAsFixed(2))];
    }

    // Gera quatro referências: mínimo, 1/3, 2/3 e máximo.
    return [
      minY,
      minY + (diferenca / 3),
      minY + ((diferenca * 2) / 3),
      maxY,
    ].map((valor) => double.parse(valor.toStringAsFixed(2))).toList();
  }

  double _calcularIntervaloX() {
    // No 7D, o eixo X é distribuído ao longo dos pontos para cobrir todo o intervalo.
    if (labelsInferiores.length == 7 && pontos.length > 1) {
      return (pontos.length - 1) / (labelsInferiores.length - 1);
    }

    if (pontos.length <= 5) {
      return 1;
    }

    return (pontos.length / 4).ceilToDouble();
  }
}