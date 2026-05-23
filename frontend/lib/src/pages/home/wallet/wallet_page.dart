// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Tela de carteira do usuário

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/home/wallet/wallet_cards.dart';
import 'package:mescla_invest/src/pages/home/wallet/startup_portfolio_detail_page.dart';
import 'package:intl/intl.dart';

enum _TokenSort { alfa, precoAsc, precoDesc }

enum _TxFilter { todos, deposito, compra, venda, cancelamento }

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

  _TokenSort _tokenSort = _TokenSort.alfa;
  _TxFilter _txFilter = _TxFilter.todos;
  int _selectedChartIdx = -1;
  String _selectedPeriod = '1A';

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
      case _TokenSort.alfa:
        list.sort((a, b) => (a['startupNome'] as String? ?? '')
            .compareTo(b['startupNome'] as String? ?? ''));
      case _TokenSort.precoAsc:
        list.sort((a, b) => ((a['valorAtual'] as num?) ?? 0)
            .compareTo((b['valorAtual'] as num?) ?? 0));
      case _TokenSort.precoDesc:
        list.sort((a, b) => ((b['valorAtual'] as num?) ?? 0)
            .compareTo((a['valorAtual'] as num?) ?? 0));
    }
    return list;
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    return _transactions.where((tx) {
      final tipo = tx['type'] as String? ?? 'buy';
      return switch (_txFilter) {
        _TxFilter.todos => true,
        _TxFilter.deposito => tipo == 'deposit',
        _TxFilter.compra => tipo == 'buy',
        _TxFilter.venda => tipo == 'sell',
        _TxFilter.cancelamento => tipo == 'return',
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      _totalInvestido = wallet['totalInvestido'] ?? 0.0;
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
    final purchases = _transactions
        .where((tx) =>
            tx['startupId'] == startupId &&
            ((tx['type'] as String?) == 'buy' ||
                (tx['type'] as String?) == 'return'))
        .toList();

    final refreshNeeded = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => StartupPortfolioDetailPage(
          token: token,
          purchases: purchases,
          logoUrl: _logoUrls[startupId],
          saldoVisivel: _saldoVisivel,
          usuario: widget.usuario,
          onTabSwitch: widget.onTabSwitch,
        ),
      ),
    );

    if (refreshNeeded == true && mounted) _loadAll();
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
                        _buildTokensTab(),
                        _buildChartsTab(),
                        _buildHistoryTab(),
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
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cinza300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SaldoDisplay(
                      saldo: _saldo,
                      visivel: _saldoVisivel,
                      label: 'Saldo em conta',
                      labelColor: AppColors.cinza500,
                      balanceColor: AppColors.azul,
                      eyeColor: AppColors.cinza500,
                      balanceFontSize: 24,
                      onVisibilityChanged: (v) {
                        setState(() => _saldoVisivel = v);
                        _saveVisibility(v);
                      },
                    ),
                    GestureDetector(
                      onTap: _showAddBalanceDialog,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.azul.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.add, size: 17, color: AppColors.azul),
                            SizedBox(width: 6),
                            Text(
                              'Depositar',
                              style: TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 14,
                                color: AppColors.azul,
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
                Container(height: 1, color: AppColors.cinza200),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _CardStat(
                        label: 'Valor investido',
                        value: _saldoVisivel
                            ? currencyFormat.format(_totalInvestido)
                            : '••••••',
                        valueColor: AppColors.preto,
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.cinza200),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _CardStat(
                          label: 'Portfólio',
                          value: _saldoVisivel
                              ? currencyFormat.format(_valorAtualPortfolio)
                              : '••••••',
                          valueColor: _valorAtualPortfolio >= _totalInvestido
                              ? AppColors.verde
                              : AppColors.vermelho,
                        ),
                      ),
                    ),
                    Container(width: 1, height: 36, color: AppColors.cinza200),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: _CardStat(
                          label: 'Tokens',
                          value: '$_totalTokens',
                          valueColor: AppColors.preto,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
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
              Tab(text: 'Gráficos'),
              Tab(text: 'Histórico'),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTokensTab() {
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
                  selected: _tokenSort == _TokenSort.alfa,
                  onTap: () => setState(() => _tokenSort = _TokenSort.alfa),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Menor preço',
                  icon: Icons.arrow_downward,
                  selected: _tokenSort == _TokenSort.precoAsc,
                  onTap: () =>
                      setState(() => _tokenSort = _TokenSort.precoAsc),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Maior preço',
                  icon: Icons.arrow_upward,
                  selected: _tokenSort == _TokenSort.precoDesc,
                  onTap: () =>
                      setState(() => _tokenSort = _TokenSort.precoDesc),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filteredTokens.isEmpty
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
                  itemCount: _filteredTokens.length,
                  itemBuilder: (context, index) {
                    final token = _filteredTokens[index];
                    return WalletTokenCard(
                      token: token,
                      logoUrl: _logoUrls[token['startupId'] as String? ?? ''],
                      saldoVisivel: _saldoVisivel,
                      onTap: () => _openTokenActions(token),
                      currencyFormat: currencyFormat,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChartsTab() {
    if (_tokens.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum token em carteira',
          style: TextStyle(
            fontFamily: 'JosefinSans',
            color: AppColors.cinza500,
          ),
        ),
      );
    }

    final isPortfolio = _selectedChartIdx == -1;
    final idx = isPortfolio ? 0 : _selectedChartIdx.clamp(0, _tokens.length - 1);

    final token = _tokens[idx];
    final startupId = token['startupId'] as String? ?? '';
    final nome = isPortfolio ? 'Portfólio' : (token['startupNome'] as String? ?? '—');
    final logoUrl = isPortfolio ? null : _logoUrls[startupId];
    final valorAtual = isPortfolio
        ? _valorAtualPortfolio
        : (token['valorAtual'] as num?)?.toDouble() ?? 0.0;

    // Portfolio chip: all-time return vs invested. Individual: today's daily variation.
    final double chipPct;
    final String chipLabel;
    if (isPortfolio) {
      chipPct = _totalInvestido > 0
          ? (_valorAtualPortfolio - _totalInvestido) / _totalInvestido * 100
          : 0.0;
      chipLabel = 'Retorno ${chipPct >= 0 ? '+' : ''}${chipPct.toStringAsFixed(1)}%';
    } else {
      final precoAnterior =
          (token['precoAnterior'] as num?)?.toDouble() ?? valorAtual;
      chipPct = precoAnterior > 0
          ? (valorAtual - precoAnterior) / precoAnterior * 100
          : 0.0;
      chipLabel = 'Hoje ${chipPct >= 0 ? '+' : ''}${chipPct.toStringAsFixed(1)}%';
    }
    final diariaColor =
        chipPct >= 0 ? AppColors.verde : AppColors.vermelho;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Chip "Portfólio"
                  GestureDetector(
                    onTap: () => setState(() => _selectedChartIdx = -1),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: isPortfolio ? AppColors.azul : AppColors.branco,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isPortfolio
                              ? AppColors.azul
                              : AppColors.cinza200,
                        ),
                      ),
                      child: Text(
                        'Portfólio',
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isPortfolio
                              ? AppColors.branco
                              : AppColors.cinza500,
                        ),
                      ),
                    ),
                  ),
                  ...List.generate(_tokens.length, (i) {
                    final t = _tokens[i];
                    final selected = !isPortfolio && i == idx;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedChartIdx = i),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.azul : AppColors.branco,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? AppColors.azul
                                : AppColors.cinza200,
                          ),
                        ),
                        child: Text(
                          t['startupNome'] as String? ?? '—',
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color:
                                selected ? AppColors.branco : AppColors.cinza500,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.branco,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cinza200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: diariaColor.withValues(alpha: 0.1),
                      backgroundImage:
                          logoUrl != null ? NetworkImage(logoUrl) : null,
                      child: logoUrl == null
                          ? Icon(
                              isPortfolio
                                  ? Icons.pie_chart_outline_rounded
                                  : Icons.business,
                              color: diariaColor,
                              size: 20,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            nome,
                            style: const TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormat.format(valorAtual),
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: diariaColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: diariaColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        chipLabel,
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: diariaColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: ['7D', '1M', '3M', '6M', '1A'].map((p) {
                    final sel = p == _selectedPeriod;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedPeriod = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: sel
                              ? diariaColor.withValues(alpha: 0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: sel ? diariaColor : AppColors.cinza500,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.cinza200.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.cinza200),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.show_chart_rounded,
                          size: 32, color: AppColors.cinza500),
                      SizedBox(height: 8),
                      Text(
                        'Gráfico em desenvolvimento',
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 13,
                          color: AppColors.cinza500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
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
                  selected: _txFilter == _TxFilter.todos,
                  onTap: () => setState(() => _txFilter = _TxFilter.todos),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Depósito',
                  selected: _txFilter == _TxFilter.deposito,
                  onTap: () =>
                      setState(() => _txFilter = _TxFilter.deposito),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Compra',
                  selected: _txFilter == _TxFilter.compra,
                  onTap: () => setState(() => _txFilter = _TxFilter.compra),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Venda',
                  selected: _txFilter == _TxFilter.venda,
                  onTap: () => setState(() => _txFilter = _TxFilter.venda),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Cancelamento',
                  selected: _txFilter == _TxFilter.cancelamento,
                  onTap: () =>
                      setState(() => _txFilter = _TxFilter.cancelamento),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _filteredTransactions.isEmpty
              ? Center(
                  child: Text(
                    _txFilter == _TxFilter.todos
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
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final tx = _filteredTransactions[index];
                    return WalletTransactionCard(
                      tx: tx,
                      logoUrl: _logoUrls[tx['startupId'] as String? ?? ''],
                      saldoVisivel: _saldoVisivel,
                      currencyFormat: currencyFormat,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _CardStat({
    required this.label,
    required this.value,
    this.valueColor = AppColors.preto,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.cinza500,
            fontFamily: 'JosefinSans',
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontFamily: 'JosefinSans',
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

