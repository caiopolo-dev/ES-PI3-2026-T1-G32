// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widgets auxiliares das abas do balcão

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/balcao/balcao_types.dart';

class BalcaoEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const BalcaoEmptyState({
    super.key,
    required this.message,
    required this.icon,
  });

  /// Widget simples para exibir um estado vazio nas abas do balcão.
  ///
  /// Uso típico:
  /// - Quando não há ofertas públicas disponíveis.
  /// - Quando o usuário não possui ordens abertas.
  ///
  /// Parâmetros:
  /// - `message`: texto a ser exibido abaixo do ícone.
  /// - `icon`: ícone representativo do estado (por exemplo, lupa para busca).

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.cinza300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'JosefinSans',
              color: AppColors.cinza500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class BalcaoSortChips extends StatelessWidget {
  final SortMode sortMode;
  final ValueChanged<SortMode> onChanged;
  final double topPadding;

  const BalcaoSortChips({
    super.key,
    required this.sortMode,
    required this.onChanged,
    this.topPadding = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topPadding, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            AppFilterChip(
              label: 'A–Z',
              selected: sortMode == SortMode.alphabetical,
              onTap: () => onChanged(SortMode.alphabetical),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: 'Menor preço',
              icon: Icons.arrow_downward,
              selected: sortMode == SortMode.priceAsc,
              onTap: () => onChanged(SortMode.priceAsc),
            ),
            const SizedBox(width: 8),
            AppFilterChip(
              label: 'Maior preço',
              icon: Icons.arrow_upward,
              selected: sortMode == SortMode.priceDesc,
              onTap: () => onChanged(SortMode.priceDesc),
            ),
          ],
        ),
      ),
    );
  }
}

/// Conjunto de chips que permitem ao usuário selecionar o modo de ordenação
/// das listas exibidas no balcão (alfabética, menor preço, maior preço).
///
/// `topPadding` facilita posicionamento quando o componente é usado em
/// diferentes contextos (ex: dentro de colunas com espaçamentos variados).

class BalcaoDismissBackground extends StatelessWidget {
  const BalcaoDismissBackground({super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: AppColors.vermelho,
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 24),
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.delete_outline, color: AppColors.branco, size: 26),
        SizedBox(height: 4),
        Text(
          'Cancelar',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.branco,
          ),
        ),
      ],
    ),
  );
}

/// Fundo exibido quando o usuário arrasta uma ordem para cancelar.
///
/// Projetado para ser usado como `secondaryBackground` em `Dismissible`.
/// Exibe um ícone de lixeira e o texto "Cancelar" alinhados à direita,
/// seguindo o estilo visual do app (cor de alerta `AppColors.vermelho`).
