// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Tela de carteira do usuário

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/pages/home/buy_steps_page.dart';
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
  String _errorText = '';

  final currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void didUpdateWidget(WalletPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega saldo, tokens e histórico ao abrir a aba,
    // garantindo que compras recentes já estejam refletidas.
    if (widget.isActive && !oldWidget.isActive) _loadAll();
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
    if (mounted) setState(() => _saldoVisivel = prefs.getBool('balance_visible') ?? false);
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

    // Dispara as três chamadas em paralelo para reduzir o tempo de carregamento.
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
  _transactions = List<Map<String, dynamic>>.from(
      history['transactions'] ?? []);
  }

    if (tokens['success'] == true) {
    _tokens = List<Map<String, dynamic>>.from(
        tokens['tokens'] ?? []);
  }

  setState(() => _isLoading = false);
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
    final startupNome = token['startupNome'] as String? ?? '';
    final quantidade = (token['quantidade'] as num?)?.toInt() ?? 0;
    final valorAtual = (token['valorAtual'] as num?)?.toDouble() ?? 0.0;
    final logoUrl = token['startupLogo'] as String?;
    final pricePerTokenCents = (valorAtual * 100).round();

    if (!mounted) return;

    final action = await showTokenActionsSheet(
      context,
      startupNome: startupNome,
      quantidade: quantidade,
      valorAtual: valorAtual,
      logoUrl: logoUrl,
    );

    if (!mounted || action == null) return;

    if (action == 'buy') {
      final comprou = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => StartupDetailPage(
            startupId: startupId,
            startupNome: startupNome,
            usuario: widget.usuario,
            onTabSwitch: widget.onTabSwitch,
          ),
        ),
      );
      if (comprou == true && mounted) _loadAll();
    } else if (action == 'sell') {
      final vendeu = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => BuyStepsPage(
            startupName: startupNome,
            startupId: startupId,
            availableQuantity: quantidade,
            pricePerTokenCents: pricePerTokenCents,
            isSellMode: true,
          ),
        ),
      );
      if (vendeu == true && mounted) _loadAll();
    }
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
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          const SizedBox(height: 24),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
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
                                      balanceFontSize: 28,
                                      onVisibilityChanged: (v) { setState(() => _saldoVisivel = v); _saveVisibility(v); },
                                    ),
                                    GestureDetector(
                                      onTap: _showAddBalanceDialog,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10.5),
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
                                const SizedBox(height: 16),
                                Container(height: 1, color: AppColors.cinza200),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _CardStat(
                                        label: 'Valor investido',
                                        value: _saldoVisivel ? currencyFormat.format(_totalInvestido) : '••••••',
                                        valueColor: AppColors.preto,
                                      ),
                                    ),
                                    Container(width: 1, height: 36, color: AppColors.cinza200),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 16),
                                        child: _CardStat(
                                          label: 'Portfólio',
                                          value: _saldoVisivel ? currencyFormat.format(_valorAtualPortfolio) : '••••••',
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

                          const SizedBox(height: 24),

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

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),

                  SliverFillRemaining(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _tokens.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum token adquirido ainda',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    color: AppColors.cinza500,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                itemCount: _tokens.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final token = _tokens[index];
                                  final precoMedio = (token['precoMedio'] as num?)?.toDouble() ?? 0.0;
                                  final valorAtual = (token['valorAtual'] as num?)?.toDouble() ?? 0.0;
                                  final quantidade = (token['quantidade'] as num?)?.toInt() ?? 0;
                                  final totalAtual = valorAtual * quantidade;
                                  final totalInvestido = precoMedio * quantidade;
                                  final variacao = precoMedio > 0
                                      ? ((valorAtual - precoMedio) / precoMedio * 100).toStringAsFixed(2)
                                      : '0.00';
                                  final positivo = valorAtual >= precoMedio;
                                  final logoUrl = token['startupLogo'] as String?;

                                  return GestureDetector(
                                    onTap: () => _openTokenActions(token),
                                    child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cinza100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: AppColors.azul.withValues(alpha: 0.1),
                                              backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                                              child: logoUrl == null
                                                  ? const Icon(Icons.business, color: AppColors.azul, size: 22)
                                                  : null,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    token['startupNome'] ?? '—',
                                                    style: const TextStyle(
                                                      fontFamily: 'JosefinSans',
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    '$quantidade tokens',
                                                    style: const TextStyle(
                                                      fontFamily: 'JosefinSans',
                                                      fontSize: 12,
                                                      color: AppColors.cinza500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${currencyFormat.format(valorAtual)}/un',
                                                  style: const TextStyle(
                                                    fontFamily: 'JosefinSans',
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                Text(
                                                  '${positivo ? '+' : ''}$variacao%',
                                                  style: TextStyle(
                                                    fontFamily: 'JosefinSans',
                                                    fontSize: 12,
                                                    color: positivo ? AppColors.verde : AppColors.vermelho,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Container(height: 1, color: AppColors.cinza300),
                                        const SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Investido',
                                                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 11, color: AppColors.cinza500),
                                                ),
                                                Text(
                                                  _saldoVisivel ? currencyFormat.format(totalInvestido) : '••••••',
                                                  style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 13, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                const Text(
                                                  'Valor atual',
                                                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 11, color: AppColors.cinza500),
                                                ),
                                                Text(
                                                  _saldoVisivel ? currencyFormat.format(totalAtual) : '••••••',
                                                  style: TextStyle(
                                                    fontFamily: 'JosefinSans',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.bold,
                                                    color: positivo ? AppColors.verde : AppColors.vermelho,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  );
                                },
                              ),

                        _transactions.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhuma transação ainda',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    color: AppColors.cinza500,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, _) => const SizedBox.shrink(),
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];
                                  final tipo = tx['type'] as String? ?? 'buy';
                                  final isDeposit = tipo == 'deposit';
                                  final isSell = tipo == 'sell';

                                  final valor = ((tx['totalCents'] as num?) ?? 0).toDouble() / 100;
                                  final data = tx['createdAt'] != null
                                      ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tx['createdAt'] as String))
                                      : '—';
                                  final quantidade = (tx['quantity'] as num?)?.toInt() ?? 0;
                                  final precoPorTokenCents = (tx['pricePerTokenCents'] as num?)?.toDouble() ?? 0;
                                  final precoPorToken = precoPorTokenCents / 100;
                                  final titulo = tx['startupName'] as String?
                                      ?? tx['startupId'] as String?
                                      ?? '—';

                                  final Color corTipo;
                                  final String labelTipo;
                                  final IconData iconeTipo;
                                  if (isDeposit) {
                                    corTipo = AppColors.azul;
                                    labelTipo = 'Depósito';
                                    iconeTipo = Icons.account_balance_wallet_outlined;
                                  } else if (isSell) {
                                    corTipo = AppColors.verde;
                                    labelTipo = 'Venda';
                                    iconeTipo = Icons.arrow_upward;
                                  } else {
                                    corTipo = AppColors.vermelho;
                                    labelTipo = 'Compra';
                                    iconeTipo = Icons.arrow_downward;
                                  }

                                  return Container(
                                    margin: const EdgeInsets.symmetric(vertical: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cinza100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: corTipo.withValues(alpha: 0.1),
                                              child: Icon(iconeTipo, color: corTipo, size: 18),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    isDeposit ? 'Depósito em conta' : titulo,
                                                    style: const TextStyle(
                                                      fontFamily: 'JosefinSans',
                                                      fontSize: 15,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: corTipo.withValues(alpha: 0.12),
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          labelTipo,
                                                          style: TextStyle(
                                                            fontFamily: 'JosefinSans',
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                            color: corTipo,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        data,
                                                        style: const TextStyle(
                                                          fontFamily: 'JosefinSans',
                                                          fontSize: 11,
                                                          color: AppColors.cinza500,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _saldoVisivel
                                                  ? '${isSell || isDeposit ? '+' : '-'} ${currencyFormat.format(valor)}'
                                                  : '••••••',
                                              style: TextStyle(
                                                fontFamily: 'JosefinSans',
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: corTipo,
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (!isDeposit) ...[
                                          const SizedBox(height: 10),
                                          Container(height: 1, color: AppColors.cinza300),
                                          const SizedBox(height: 10),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              _TxStat(label: 'Quantidade', value: '$quantidade tokens'),
                                              _TxStat(
                                                label: 'Preço/token',
                                                value: _saldoVisivel ? currencyFormat.format(precoPorToken) : '••••••',
                                                alignEnd: true,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
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


class _CardStat extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _CardStat({required this.label, required this.value, this.valueColor = AppColors.preto});

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

class _TxStat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _TxStat({required this.label, required this.value, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 11,
            color: AppColors.cinza500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
