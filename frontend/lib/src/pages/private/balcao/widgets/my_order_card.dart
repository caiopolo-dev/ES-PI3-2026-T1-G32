// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Card de ordem própria exibido em Minhas Ofertas no balcão

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class MyOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final String? logoUrl;
  final VoidCallback? onCancel;

  const MyOrderCard({
    super.key,
    required this.data,
    required this.currency,
    this.logoUrl,
    this.onCancel,
  });

  /// Card que representa uma ordem do próprio usuário na aba "Minhas ordens".
  ///
  /// Props:
  /// - `data`: mapa com campos da ordem (startupName/startupId, amount,
  ///   valorUnitarioCentavos, offerId, etc.).
  /// - `currency`: `NumberFormat` usado para formatar valores monetários.
  /// - `logoUrl`: URL opcional da logo da startup para exibir no avatar.
  /// - `onCancel`: callback acionado quando o usuário toca em "Cancelar".
  ///
  /// Observações de UX/implementação:
  /// - Exibe um indicador visual de estado (barra verde à esquerda e
  ///   badge "Em aberto").
  /// - Mostra preço por token e total (preço * quantidade).
  /// - O botão "Cancelar" é um `GestureDetector` que delega a ação para
  ///   quem construiu o card — geralmente a tela chamará um diálogo de
  ///   confirmação antes de executar a remoção no backend.

  @override
  Widget build(BuildContext context) {
    final name = (data['startupName'] ?? data['startupId'] ?? '—').toString();
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final centavos = (data['valorUnitarioCentavos'] as num?)?.toDouble() ?? 0;
    final preco = centavos / 100;

    // Normaliza e calcula valores a serem exibidos:
    // - `preco` representa o valor por token em reais (centavos/100).

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
              Container(width: 5, color: AppColors.verde),
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
                            backgroundColor: AppColors.amarelo.withValues(alpha: 0.15),
                            backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                            child: logoUrl == null
                                ? const Icon(Icons.arrow_upward, color: AppColors.amarelo, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.amarelo.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Em aberto',
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.amarelo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(preco),
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azul,
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
                              const SizedBox(height: 2),
                              Text(
                                'Total ${currency.format(preco * amount)}',
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.cinza700,
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
                                  '${NumberFormat('#,##0', 'pt_BR').format(amount)} tokens',
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
                          GestureDetector(
                            onTap: onCancel,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.vermelho.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.vermelho.withValues(alpha: 0.3)),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.vermelho,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.close, size: 13, color: AppColors.vermelho),
                                ],
                              ),
                            ),
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