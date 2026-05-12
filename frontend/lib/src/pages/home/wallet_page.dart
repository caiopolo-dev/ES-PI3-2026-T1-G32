// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Tela de carteira do usuário

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/pages/initial_page.dart';
import 'package:mescla_invest/src/pages/home/balcao_page.dart';
import 'package:mescla_invest/src/pages/home/catalog_page.dart';
import 'package:mescla_invest/src/pages/home/profile_page.dart';
import 'package:intl/intl.dart';

class WalletPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const WalletPage({super.key, this.usuario});

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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => ProfilePage(usuario: widget.usuario)),
                  );
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.branco,
          border: Border(top: BorderSide(color: AppColors.cinza300)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.branco,
          elevation: 0,
          currentIndex: 2,
          selectedItemColor: AppColors.azul,
          unselectedItemColor: AppColors.cinza500,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => BalcaoNegociacaoPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => InitialCatalogPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 2) return;
            if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(usuario: widget.usuario)),
              );
              return;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
          ],
        ),
      ),
      body: RefreshIndicator(
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.azul, AppColors.preto],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.azul.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Saldo disponível',
                                  style: TextStyle(
                                    color: AppColors.branco,
                                    fontFamily: 'JosefinSans',
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(_saldo),
                                  style: const TextStyle(
                                    color: AppColors.branco,
                                    fontFamily: 'JosefinSans',
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _CardStat(
                                      label: 'Total investido',
                                      value: currencyFormat
                                          .format(_totalInvestido),
                                    ),
                                    _CardStat(
                                      label: 'Tokens',
                                      value: '$_totalTokens',
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
                              Tab(text: 'Histórico'),
                              Tab(text: 'Meus Tokens'),
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
                        _isLoading
                            ? const _LoadingDots('Carregando histórico')
                            : _transactions.isEmpty
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
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];
                                  final isCompra =
                                      tx['type'] == 'buy';
                                  final valor =
                                      ((tx['totalCents'] as num?) ?? 0)
                                          .toDouble() / 100;
                                  final data = tx['createdAt'] != null
                                      ? DateFormat('dd/MM/yyyy HH:mm')
                                          .format(DateTime.parse(
                                              tx['createdAt']))
                                      : '—';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isCompra
                                          ? AppColors.verde.withValues(alpha: 0.1)
                                          : AppColors.vermelho.withValues(alpha: 0.1),
                                      child: Icon(
                                        isCompra
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isCompra
                                            ? AppColors.verde
                                            : AppColors.vermelho,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      tx['startupId'] ?? '—',
                                      style: const TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 15,
                                      ),
                                    ),
                                    subtitle: Text(
                                      data,
                                      style: const TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 12,
                                        color: AppColors.cinza500,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${isCompra ? '-' : '+'} ${currencyFormat.format(valor)}',
                                      style: TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCompra
                                            ? AppColors.vermelho
                                            : AppColors.verde,
                                      ),
                                    ),
                                  );
                                },
                              ),

                        _isLoading
                            ? const _LoadingDots('Carregando seus tokens')
                            : _tokens.isEmpty
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
                                  final precoMedio =
                                      (token['precoMedio'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final valorAtual =
                                      (token['valorAtual'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final quantidade =
                                      token['quantidade'] ?? 0;
                                  // Variação percentual em relação ao preço médio de compra.
                                  final variacao =
                                      precoMedio > 0
                                          ? ((valorAtual - precoMedio) /
                                                  precoMedio *
                                                  100)
                                              .toStringAsFixed(2)
                                          : '0.00';
                                  final positivo =
                                      valorAtual >= precoMedio;

                                  // AQUI DEVE SER FEITA A LOGICA DE VENDA
                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: AppColors.cinza100,
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: AppColors.azul
                                              .withValues(alpha:0.1),
                                          backgroundImage:
                                              token['startupLogo'] != null
                                                  ? NetworkImage(
                                                      token['startupLogo'])
                                                  : null,
                                          child:
                                              token['startupLogo'] == null
                                                  ? const Icon(
                                                      Icons.business,
                                                      color: AppColors.azul,
                                                      size: 20,
                                                    )
                                                  : null,
                                        ),

                                        const SizedBox(width: 12),

                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                token['startupNome'] ??
                                                    '—',
                                                style: const TextStyle(
                                                  fontFamily: 'JosefinSans',
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.bold,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              currencyFormat
                                                  .format(valorAtual),
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
                                                color: positivo
                                                    ? AppColors.verde
                                                    : AppColors.vermelho,
                                              ),
                                            ),
                                          ],
                                        ),
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

class _LoadingDots extends StatefulWidget {
  final String label;
  const _LoadingDots(this.label);

  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots> {
  int _dotCount = 1;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Cicla de 1 a 3 pontos a cada 500ms: ".", "..", "..."
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotCount = (_dotCount % 3) + 1);
    });
  }

  @override
  void dispose() {
    // Timer deve ser cancelado para evitar setState após o widget ser destruído.
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        '${widget.label}${'.' * _dotCount}',
        style: const TextStyle(
          fontFamily: 'JosefinSans',
          color: AppColors.cinza500,
          fontSize: 16,
        ),
      ),
    );
  }
}

class _CardStat extends StatelessWidget {
  final String label;
  final String value;

  const _CardStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.branco,
            fontFamily: 'JosefinSans',
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.branco,
            fontFamily: 'JosefinSans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}