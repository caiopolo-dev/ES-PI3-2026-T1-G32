// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Tabs de tokens e histórico da tela de carteira

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/wallet/wallet_types.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_token_card.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_transaction_card.dart';

class WalletTokensTab extends StatelessWidget {
  final List<Map<String, dynamic>> tokens;
  final Map<String, String?> logoUrls;
  final bool saldoVisivel;
  final TokenSort tokenSort;
  final ValueChanged<TokenSort> onSortChanged;
  final void Function(Map<String, dynamic>) onTokenTap;
  final NumberFormat currencyFormat;

  const WalletTokensTab({
    super.key,
    required this.tokens,
    required this.logoUrls,
    required this.saldoVisivel,
    required this.tokenSort,
    required this.onSortChanged,
    required this.onTokenTap,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChip(
                  label: 'A-Z',
                  selected: tokenSort == TokenSort.alfa,
                  onTap: () => onSortChanged(TokenSort.alfa),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Menor preço',
                  icon: Icons.arrow_downward,
                  selected: tokenSort == TokenSort.precoAsc,
                  onTap: () => onSortChanged(TokenSort.precoAsc),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Maior preço',
                  icon: Icons.arrow_upward,
                  selected: tokenSort == TokenSort.precoDesc,
                  onTap: () => onSortChanged(TokenSort.precoDesc),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: tokens.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum token adquirido ainda',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      color: AppColors.cinza500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: tokens.length,
                  itemBuilder: (context, index) {
                    final token = tokens[index];
                    return WalletTokenCard(
                      token: token,
                      logoUrl: logoUrls[token['startupId'] as String? ?? ''],
                      saldoVisivel: saldoVisivel,
                      onTap: () => onTokenTap(token),
                      currencyFormat: currencyFormat,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class WalletHistoryTab extends StatelessWidget {
  final List<Map<String, dynamic>> transactions;
  final Map<String, String?> logoUrls;
  final bool saldoVisivel;
  final TxFilter txFilter;
  final ValueChanged<TxFilter> onFilterChanged;
  final NumberFormat currencyFormat;

  const WalletHistoryTab({
    super.key,
    required this.transactions,
    required this.logoUrls,
    required this.saldoVisivel,
    required this.txFilter,
    required this.onFilterChanged,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChip(
                  label: 'Todos',
                  selected: txFilter == TxFilter.todos,
                  onTap: () => onFilterChanged(TxFilter.todos),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Depósito',
                  selected: txFilter == TxFilter.deposito,
                  onTap: () => onFilterChanged(TxFilter.deposito),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Compra',
                  selected: txFilter == TxFilter.compra,
                  onTap: () => onFilterChanged(TxFilter.compra),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Venda',
                  selected: txFilter == TxFilter.venda,
                  onTap: () => onFilterChanged(TxFilter.venda),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Cancelamento',
                  selected: txFilter == TxFilter.cancelamento,
                  onTap: () => onFilterChanged(TxFilter.cancelamento),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: transactions.isEmpty
              ? Center(
                  child: Text(
                    txFilter == TxFilter.todos
                        ? 'Nenhuma transação ainda'
                        : 'Nenhuma transação encontrada',
                    style: const TextStyle(
                      fontFamily: 'JosefinSans',
                      color: AppColors.cinza500,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    return WalletTransactionCard(
                      tx: tx,
                      logoUrl: logoUrls[tx['startupId'] as String? ?? ''],
                      saldoVisivel: saldoVisivel,
                      currencyFormat: currencyFormat,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
