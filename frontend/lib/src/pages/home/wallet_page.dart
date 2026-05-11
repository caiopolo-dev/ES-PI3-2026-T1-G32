// Autor: Henrique Leite de Camargo 25005997
// Data: 10/05/2026
// Descrição: Tela de carteira do usuário

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Minha Carteira',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'JosefinSans',
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
    ? const Center(child: CircularProgressIndicator())
    : _errorText.isNotEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _errorText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'JosefinSans',
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loadAll,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            ),
          )
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
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF013593), Color(0xFF080B11)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Saldo disponível',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontFamily: 'JosefinSans',
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormat.format(_saldo),
                                  style: const TextStyle(
                                    color: Colors.white,
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

                          const SizedBox(height: 24),

                          TabBar(
                            controller: _tabController,
                            labelColor: const Color(0xFF013593),
                            unselectedLabelColor: Colors.black38,
                            indicatorColor: const Color(0xFF013593),
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
                        _transactions.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhuma transação ainda',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    color: Colors.black38,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                itemCount: _transactions.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final tx = _transactions[index];
                                  final isCompra =
                                      tx['tipo'] == 'compra';
                                  final valor =
                                      (tx['valorTotal'] as num?)
                                              ?.toDouble() ??
                                          0.0;
                                  final data = tx['createdAt'] != null
                                      ? DateFormat('dd/MM/yyyy HH:mm')
                                          .format(DateTime.parse(
                                              tx['createdAt']))
                                      : '—';

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: isCompra
                                          ? Colors.green.withOpacity(0.1)
                                          : Colors.red.withOpacity(0.1),
                                      child: Icon(
                                        isCompra
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isCompra
                                            ? Colors.green
                                            : Colors.red,
                                        size: 20,
                                      ),
                                    ),
                                    title: Text(
                                      tx['startupNome'] ?? '—',
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
                                        color: Colors.black38,
                                      ),
                                    ),
                                    trailing: Text(
                                      '${isCompra ? '-' : '+'} ${currencyFormat.format(valor)}',
                                      style: TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isCompra
                                            ? Colors.red
                                            : Colors.green,
                                      ),
                                    ),
                                  );
                                },
                              ),

                        _tokens.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nenhum token adquirido ainda',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    color: Colors.black38,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24),
                                itemCount: _tokens.length,
                                separatorBuilder: (_, __) =>
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
                                  final variacao =
                                      precoMedio > 0
                                          ? ((valorAtual - precoMedio) /
                                                  precoMedio *
                                                  100)
                                              .toStringAsFixed(2)
                                          : '0.00';
                                  final positivo =
                                      valorAtual >= precoMedio;

                                  return Container(
                                    margin: const EdgeInsets.symmetric(
                                        vertical: 6),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundColor: Colors.blue
                                              .withOpacity(0.1),
                                          backgroundImage:
                                              token['startupLogo'] != null
                                                  ? NetworkImage(
                                                      token['startupLogo'])
                                                  : null,
                                          child:
                                              token['startupLogo'] == null
                                                  ? const Icon(
                                                      Icons.business,
                                                      color: Colors.blue,
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
                                                  color: Colors.black45,
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
                                                    ? Colors.green
                                                    : Colors.red,
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
          style: const TextStyle(
            color: Colors.white60,
            fontFamily: 'JosefinSans',
            fontSize: 11,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'JosefinSans',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}