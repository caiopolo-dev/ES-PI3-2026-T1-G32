// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card de startup exibido no catálogo

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:intl/intl.dart';

const Map<String, String> estagioLabels = {
  'nova': 'Nova',
  'em_operacao': 'Em Operação',
  'em_expansao': 'Em Expansão',
};

const Map<String, Color> estagioColors = {
  'nova': AppColors.verde,
  'em_operacao': AppColors.azul,
  'em_expansao': AppColors.laranja,
};

class StartupCard extends StatelessWidget {
  static final _fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  final String nome;
  final String setor;
  final String estagio;
  final double precoToken;
  final double fechamentoOntem;
  final int totalTokens;
  final String? logoUrl;
  final int? quantidadeToken;

  const StartupCard({
    super.key,
    required this.nome,
    required this.setor,
    required this.estagio,
    required this.precoToken,
    required this.fechamentoOntem,
    required this.totalTokens,
    this.logoUrl,
    this.quantidadeToken,
  });

  @override
  Widget build(BuildContext context) {
    // O `StartupCard` é responsável por apresentar informações resumidas
    // da startup no catálogo, incluindo preço atual, variação diária,
    // estágio (com cor) e se o usuário possui tokens.
    //
    // Estratégia de cor/variação:
    // - Se não houver `fechamentoOntem` (<= 0) exibimos o preço em preto
    //   sem badge de variação.
    // - Caso exista valor anterior calculamos `variacaoPct` em porcentagem
    //   e definimos `precoColor` conforme positivo (verde), negativo
    //   (vermelho) ou neutro (cinza).
    final accentColor = estagioColors[estagio] ?? AppColors.azul;
    final Color precoColor;
    final double? variacaoPct;

    if (fechamentoOntem <= 0) {
      precoColor = AppColors.preto;
      variacaoPct = null;
    } else {
      variacaoPct = (precoToken - fechamentoOntem) / fechamentoOntem * 100;
      precoColor = variacaoPct > 0
          ? AppColors.verde
          : variacaoPct < 0
          ? AppColors.vermelho
          : AppColors.cinza500;
    }

    final estagioChip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        // Rótulo legível para o estágio (ex: 'Nova', 'Em Operação').
        estagioLabels[estagio] ?? estagio,
        style: TextStyle(
          fontFamily: 'JosefinSans',
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: accentColor,
        ),
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cinza300),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: logoUrl != null
                      ? Image.network(logoUrl!, fit: BoxFit.cover)
                      : Container(color: accentColor.withValues(alpha: 0.08)),
                ),
                Positioned(top: 10, right: 10, child: estagioChip),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome,
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              setor,
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 13,
                                color: AppColors.cinza700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _fmt.format(precoToken),
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: precoColor,
                            ),
                          ),
                          if (variacaoPct != null) ...[
                            const SizedBox(height: 3),
                            DailyVariationBadge(variacaoPct: variacaoPct),
                          ] else ...[
                            const SizedBox(height: 3),
                            const Text(
                              'por token',
                              style: TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 11,
                                color: AppColors.cinza500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(height: 1, color: AppColors.cinza300),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.azul.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.toll_outlined,
                              size: 13,
                              color: AppColors.azul,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${NumberFormat('#,##0', 'pt_BR').format(totalTokens)} tokens',
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
                      if (quantidadeToken != null && quantidadeToken! > 0) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.verde.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 13,
                                color: AppColors.verde,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Você tem $quantidadeToken',
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.verde,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
