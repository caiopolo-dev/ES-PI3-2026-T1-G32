// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card de resumo de investimentos exibido na home

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class InvestimentoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? logoUrl;
  final int tokenQuantity;
  final NumberFormat currencyFormat;

  const InvestimentoCard({
    super.key,
    required this.data,
    required this.logoUrl,
    required this.tokenQuantity,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final precoAtual = (data['precoToken'] as num?)?.toDouble() ?? 0.0;
    final fechamento = (data['fechamentoOntemCentavos'] as num?)?.toDouble();
    final temVariacao = fechamento != null && fechamento > 0;
    final variacaoPct = temVariacao ? (precoAtual - fechamento) / fechamento * 100 : 0.0;
    final accentColor = temVariacao
        ? (variacaoPct >= 0 ? AppColors.verde : AppColors.vermelho)
        : AppColors.azul;

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
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: accentColor.withValues(alpha: 0.1),
                        backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                        child: logoUrl == null
                            ? Icon(Icons.business, color: accentColor, size: 20)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              data['nome'] as String? ?? '',
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              data['setor'] as String? ?? '',
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 12,
                                color: AppColors.cinza500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.azul.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.toll_outlined, size: 12, color: AppColors.azul),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$tokenQuantity tokens',
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.azul,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currencyFormat.format(precoAtual / 100),
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          DailyVariationBadge(
                            variacaoPct: temVariacao ? variacaoPct : null,
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
    );
  }
}