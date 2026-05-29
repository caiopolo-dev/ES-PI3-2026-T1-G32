// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Tela de carteira do usuário

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_tabs.dart';
import 'package:mescla_invest/src/pages/private/wallet/startup_portfolio_detail_page.dart';
import 'package:mescla_invest/src/pages/private/wallet/widgets/wallet_finance_card.dart';
import 'package:mescla_invest/src/pages/private/wallet/wallet_types.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const WalletPage({super.key, this.usuario, this.onTabSwitch, this.isActive = false});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _saldoVisivel = false;
  double _saldo = 0;
  double _totalInvestido = 0;
  int _totalTokens = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _tokens = [];
  Map<String, String?> _logoUrls = {};
  String _errorText = '';

  TokenSort _tokenSort = TokenSort.alfa;
  TxFilter _txFilter = TxFilter.todos;

  final currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void didUpdateWidget(WalletPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _loadVisibility();
      _loadAll();
    }
  }

  List<Map<String, dynamic>> get _filteredTokens {
    var list = List<Map<String, dynamic>>.from(_tokens);
    switch (_tokenSort) {
      case TokenSort.alfa:
        list.sort((a, b) => (a['startupNome'] as String? ?? '')
            .compareTo(b['startupNome'] as String? ?? ''));
      case TokenSort.precoAsc:
        list.sort((a, b) => ((a['valorAtual'] as num?) ?? 0)
            .compareTo((b['valorAtual'] as num?) ?? 0));
      case TokenSort.precoDesc:
        list.sort((a, b) => ((b['valorAtual'] as num?) ?? 0)
            .compareTo((a['valorAtual'] as num?) ?? 0));
    }
    return list;
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((tx) {
      final tipo = tx['type'] as String? ?? 'buy';
      return switch (_txFilter) {
        TxFilter.todos => true,
        TxFilter.deposito => tipo == 'deposit',
        TxFilter.compra => tipo == 'buy',
        TxFilter.venda => tipo == 'sell',
        TxFilter.cancelamento => tipo == 'return',
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadVisibility();
    if (widget.isActive) _loadAll();
  }

  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _saldoVisivel = prefs.getBool('balance_visible') ?? false);
    }
  }

  Future<void> _saveVisibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', value);
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _errorText = '';
      _saldo = 0;
      _totalTokens = 0;
      _totalInvestido = 0;
      _tokens = [];
      _transactions = [];
    });

    final results = await Future.wait([
      WalletService.getWalletData(),
      WalletService.getTransactionHistory(),
      WalletService.getUserTokens(),
    ]);

    if (!mounted) return;

    final wallet = results[0];
    final history = results[1];
    final tokens = results[2];

    if (wallet['success'] == true) {
      _saldo = wallet['saldo'] ?? 0.0;
      _totalTokens = wallet['totalTokens'] ?? 0;
    } else {
      _errorText = wallet['message'] ?? 'Erro ao carregar carteira';
    }

    if (history['success'] == true) {
      _transactions =
          List<Map<String, dynamic>>.from(history['transactions'] ?? []);
    }

    if (tokens['success'] == true) {
      _tokens = List<Map<String, dynamic>>.from(tokens['tokens'] ?? []);
      _totalInvestido = _tokens.fold(0.0, (sum, t) {
        final precoMedio = (t['precoMedio'] as num?)?.toDouble() ?? 0.0;
        final quantidade = (t['quantidade'] as num?)?.toInt() ?? 0;
        return sum + precoMedio * quantidade;
      });
    }

    setState(() => _isLoading = false);
    _loadLogoUrls();
  }

  Future<void> _loadLogoUrls() async {
    final Map<String, String> idToNome = {};
    for (final t in _tokens) {
      final id = t['startupId'] as String? ?? '';
      final nome = t['startupNome'] as String? ?? '';
      if (id.isNotEmpty && nome.isNotEmpty) idToNome[id] = nome;
    }
    for (final tx in _transactions) {
      final id = tx['startupId'] as String? ?? '';
      final nome = tx['startupName'] as String? ?? '';
      if (id.isNotEmpty && nome.isNotEmpty && !idToNome.containsKey(id)) {
        idToNome[id] = nome;
      }
    }
    final entries = await Future.wait(
      idToNome.entries.map((e) async {
        final url =
            await StorageService.getStartupAsset(e.value, 'logoPhoto.jpeg');
        return MapEntry(e.key, url);
      }),
    );
    if (!mounted) return;
    setState(() => _logoUrls = Map.fromEntries(entries));
  }

  double get _valorAtualPortfolio => _tokens.fold(0.0, (sum, t) {
        final valorAtual = (t['valorAtual'] as num?)?.toDouble() ?? 0.0;
        final quantidade = (t['quantidade'] as num?)?.toInt() ?? 0;
        return sum + valorAtual * quantidade;
      });

  Future<void> _showAddBalanceDialog() async {
    final amountCents = await showDialog<int>(
      context: context,
      builder: (_) => const DepositDialog(),
    );
    if (!mounted || amountCents == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _isLoading = true);
    });

    final result = await WalletService.addBalance(amountCents);
    if (!mounted) return;
    if (result['success'] == true) {
      _loadAll();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erro ao depositar')),
      );
    }
  }

  Future<void> _openTokenActions(Map<String, dynamic> token) async {
    final startupId = token['startupId'] as String? ?? '';
    await showStartupPortfolioCard(
      context: context,
      token: token,
      logoUrl: _logoUrls[startupId],
      saldoVisivel: _saldoVisivel,
      usuario: widget.usuario,
      onTabSwitch: widget.onTabSwitch,
      onRefresh: () { if (mounted) _loadAll(); },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          UserAvatarMenu(
            usuario: widget.usuario,
            onPerfilTap: () => widget.onTabSwitch?.call(4),
          ),
        ],
      ),
      body: _isLoading
          ? const AppLoadingIndicator()
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _buildHeader()),
                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        WalletTokensTab(
                          tokens: _filteredTokens,
                          logoUrls: _logoUrls,
                          saldoVisivel: _saldoVisivel,
                          tokenSort: _tokenSort,
                          onSortChanged: (sort) => setState(() => _tokenSort = sort),
                          onTokenTap: _openTokenActions,
                          currencyFormat: currencyFormat,
                        ),
                        WalletHistoryTab(
                          transactions: _filteredTransactions,
                          logoUrls: _logoUrls,
                          saldoVisivel: _saldoVisivel,
                          txFilter: _txFilter,
                          onFilterChanged: (filter) => setState(() => _txFilter = filter),
                          currencyFormat: currencyFormat,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 12),
          WalletFinanceCard(
            saldo: _saldo,
            saldoVisivel: _saldoVisivel,
            totalInvestido: _totalInvestido,
            valorAtualPortfolio: _valorAtualPortfolio,
            totalTokens: _totalTokens,
            currencyFormat: currencyFormat,
            onVisibilityChanged: (v) {
              setState(() => _saldoVisivel = v);
              _saveVisibility(v);
            },
            onDepositar: _showAddBalanceDialog,
          ),
          if (_errorText.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    size: 14, color: AppColors.laranja),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorText,
                    style: const TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 12,
                      color: AppColors.laranja,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 14),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.azul,
            unselectedLabelColor: AppColors.cinza500,
            indicatorColor: AppColors.azul,
            labelStyle: const TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Meus Tokens'),
              Tab(text: 'Histórico'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}


