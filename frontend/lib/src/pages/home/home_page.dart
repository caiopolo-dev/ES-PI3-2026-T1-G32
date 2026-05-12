// Autor: Gustavo Alves de Siqueira Costa
// Data: 12/05/2026
// Descrição: Tela inicial pós-login com resumo financeiro e startups em destaque

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/startup_service.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/widgets/user_avatar_menu.dart';
import 'package:mescla_invest/src/widgets/app_loading_indicator.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const HomePage({super.key, this.usuario, this.onTabSwitch, this.isActive = false});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = true;
  double _saldo = 0;
  double _valorPortfolio = 0;
  int _totalTokens = 0;
  List<Map<String, dynamic>> _destaques = [];

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega quando a aba passa de inativa para ativa,
    // refletindo compras ou mudanças feitas em outras abas.
    if (widget.isActive && !oldWidget.isActive) _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      WalletService.getWalletData(),
      WalletService.getUserTokens(),
      StartupService.getStartups(),
    ]);

    if (!mounted) return;

    final wallet = results[0];
    if (wallet['success'] == true) {
      _saldo = wallet['saldo'] ?? 0.0;
      _totalTokens = wallet['totalTokens'] ?? 0;
    }

    final tokens = results[1];
    if (tokens['success'] == true) {
      final lista = List<Map<String, dynamic>>.from(tokens['tokens'] ?? []);
      _valorPortfolio = lista.fold(0.0, (sum, t) {
        final valorAtual = (t['valorAtual'] as num?)?.toDouble() ?? 0.0;
        final quantidade = (t['quantidade'] as num?)?.toInt() ?? 0;
        return sum + valorAtual * quantidade;
      });
    }

    final startups = results[2];
    if (startups['success'] == true) {
      final lista = List<Map<String, dynamic>>.from(startups['data'] as List);
      _destaques = lista.take(3).toList();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario ?? {};
    final nome = (usuario['nome'] ?? usuario['name']) as String? ?? '';
    final primeiroNome = nome.split(' ').first;

    return Scaffold(
      backgroundColor: AppColors.cinza100,
      appBar: AppBar(
        backgroundColor: AppColors.cinza100,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          UserAvatarMenu(
            usuario: widget.usuario,
            onPerfilTap: () => widget.onTabSwitch?.call(4),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            const SizedBox(height: 8),

            Text(
              'Olá, $primeiroNome',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'JosefinSans',
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Veja seu resumo de hoje',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.cinza500,
                fontFamily: 'JosefinSans',
              ),
            ),

            const SizedBox(height: 20),

            // Card financeiro
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
              child: _isLoading
                  ? const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator(color: AppColors.branco, strokeWidth: 2)),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo disponível',
                          style: TextStyle(color: AppColors.branco, fontFamily: 'JosefinSans', fontSize: 13),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatItem(label: 'Portfólio', value: currencyFormat.format(_valorPortfolio)),
                            _StatItem(label: 'Tokens', value: '$_totalTokens'),
                          ],
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 28),

            // Gráfico de valorização geral
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text(
                  'Valorização do portfólio',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JosefinSans',
                  ),
                ),
                Text(
                  'Em breve',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cinza500,
                    fontFamily: 'JosefinSans',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: AppColors.branco,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cinza300),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.show_chart, size: 36, color: AppColors.cinza300),
                    SizedBox(height: 8),
                    Text(
                      'Gráfico de valorização em desenvolvimento',
                      style: TextStyle(
                        fontFamily: 'JosefinSans',
                        fontSize: 12,
                        color: AppColors.cinza500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Startups em destaque
            const Text(
              'Startups em destaque',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'JosefinSans',
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              const AppLoadingIndicator()
            else if (_destaques.isEmpty)
              const Text(
                'Nenhuma startup disponível',
                style: TextStyle(color: AppColors.cinza500, fontFamily: 'JosefinSans'),
              )
            else
              ..._destaques.map((data) {
                final assets = data['assets'] as Map<String, dynamic>?;
                final photos = assets?['photos'] as Map<String, dynamic>?;
                final logoUrl = photos?['logoPhoto'] as String?;

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StartupDetailPage(
                        startupId: data['id'] as String? ?? '',
                        startupNome: data['nome'] as String? ?? '',
                        usuario: widget.usuario,
                        onTabSwitch: widget.onTabSwitch,
                      ),
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.branco,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cinza300),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.azul.withValues(alpha: 0.1),
                          backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                          child: logoUrl == null
                              ? const Icon(Icons.business, color: AppColors.azul, size: 22)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['nome'] as String? ?? '',
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                data['setor'] as String? ?? '',
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
                              'R\$ ${NumberFormat('#,##0.00', 'pt_BR').format((data['precoToken'] as num?)?.toDouble() ?? 0.0)}',
                              style: const TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.azul,
                              ),
                            ),
                            const Text(
                              '+0.00%',
                              style: TextStyle(
                                fontFamily: 'JosefinSans',
                                fontSize: 12,
                                color: AppColors.verde,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.branco, fontFamily: 'JosefinSans', fontSize: 11)),
        Text(value, style: const TextStyle(color: AppColors.branco, fontFamily: 'JosefinSans', fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

