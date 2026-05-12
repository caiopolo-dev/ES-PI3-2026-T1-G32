// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Tela de carteira do usuário

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/pages/initial_page.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;

  const WalletPage({super.key, this.usuario, this.onTabSwitch});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  double _saldo = 0;
  double _totalInvestido = 0;
  int _totalTokens = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _tokens = [];
  String _errorText = '';

  final currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialPage()),
      (_) => false,
    );
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

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario ?? {};
    final nome = (usuario['nome'] ?? usuario['name']) as String? ?? '';
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Minha Carteira',
          style: TextStyle(
            color: AppColors.preto,
            fontFamily: 'JosefinSans',
            fontSize: 20,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'perfil') {
                  widget.onTabSwitch?.call(4);
                } else if (value == 'sair') {
                  _logout();
                }
              },
              color: AppColors.branco,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.cinza200),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'perfil',
                  child: Row(children: [
                    Icon(Icons.person_outline, size: 20, color: AppColors.preto87),
                    SizedBox(width: 12),
                    Text('Meu Perfil'),
                  ]),
                ),
                PopupMenuItem<String>(
                  enabled: false,
                  height: 8,
                  padding: EdgeInsets.zero,
                  child: Divider(indent: 16, endIndent: 16, thickness: 1, height: 1, color: AppColors.cinza200),
                ),
                const PopupMenuItem(
                  value: 'sair',
                  child: Row(children: [
                    Icon(Icons.logout, size: 20, color: AppColors.vermelho),
                    SizedBox(width: 12),
                    Text('Sair', style: TextStyle(color: AppColors.vermelho)),
                  ]),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.azul,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    inherit: false,
                    color: AppColors.branco,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.azul))
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
                                const Text(
                                  'Saldo em conta',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 12,
                                    color: AppColors.cinza500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  currencyFormat.format(_saldo),
                                  style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.azul,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(height: 1, color: AppColors.cinza200),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _CardStat(
                                        label: 'Valor investido',
                                        value: currencyFormat.format(_totalInvestido),
                                        valueColor: AppColors.preto,
                                      ),
                                    ),
                                    Container(width: 1, height: 36, color: AppColors.cinza200),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 16),
                                        child: _CardStat(
                                          label: 'Valor atual',
                                          value: currencyFormat.format(_valorAtualPortfolio),
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

                                  // AQUI DEVE SER FEITA A LOGICA DE VENDA
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
                                                    '$quantidade tokens · ${currencyFormat.format(valorAtual)}/un',
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
                                                  currencyFormat.format(totalAtual),
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
                                                  currencyFormat.format(totalInvestido),
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
                                                  currencyFormat.format(totalAtual),
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
                                separatorBuilder: (_, _) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];
                                  final isCompra = tx['type'] == 'buy';
                                  final valor = ((tx['totalCents'] as num?) ?? 0).toDouble() / 100;
                                  final data = tx['createdAt'] != null
                                      ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(tx['createdAt']))
                                      : '—';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isCompra
                                          ? AppColors.verde.withValues(alpha: 0.1)
                                          : AppColors.vermelho.withValues(alpha: 0.1),
                                      child: Icon(
                                        isCompra ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isCompra ? AppColors.verde : AppColors.vermelho,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      tx['startupId'] ?? '—',
                                      style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 15),
                                    ),
                                    subtitle: Text(
                                      data,
                                      style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 12, color: AppColors.cinza500),
                                    ),
                                    trailing: Text(
                                      '${isCompra ? '-' : '+'} ${currencyFormat.format(valor)}',
                                      style: TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCompra ? AppColors.vermelho : AppColors.verde,
                                      ),
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