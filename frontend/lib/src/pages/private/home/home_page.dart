// Autor: Gustavo Alves de Siqueira Costa
// Data: 12/05/2026
// Descrição: Tela inicial pós-login com resumo financeiro e startups em destaque

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/startup_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/pages/private/home/widgets/investment_card.dart';
import 'package:mescla_invest/src/pages/private/home/widgets/home_widgets.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

import 'package:fl_chart/fl_chart.dart';

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
  bool _saldoVisivel = false;
  double _saldo = 0;
  double _valorPortfolio = 0;

  int _totalTokens = 0;

  int _selectedPeriodPortfolio = 1;
  static const _periodsPortfolio = ['7D', '1M', '6M', 'YTD', 'Tudo'];

  List<Map<String, dynamic>> _meusInvestimentos = [];
  List<Map<String, dynamic>> _portfolioHistory = [];
  Map<String, String?> _logoUrls = {};
  Map<String, int> _tokenMap = {};

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadVisibility();
    if (widget.isActive) _loadData();
  }

  Future<void> _loadVisibility() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _saldoVisivel = prefs.getBool('balance_visible') ?? false);
  }

  Future<void> _saveVisibility(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('balance_visible', value);
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega quando a aba passa de inativa para ativa,
    // refletindo compras ou mudanças feitas em outras abas.
    if (widget.isActive && !oldWidget.isActive) _loadData();
  }

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
      _loadData();
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erro ao depositar')),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _portfolioHistory = [];
    });

    final results = await Future.wait([
      WalletService.getWalletData(),
      WalletService.getUserTokens(),
      StartupService.getStartups(includeDailyVariation: true),
      WalletService.getPortfolioHistory(),
    ]);

    if (!mounted) return;

    final wallet = results[0];
    if (wallet['success'] == true) {
      _saldo = wallet['saldo'] ?? 0.0;
      _totalTokens = wallet['totalTokens'] ?? 0;
    }

    final tokens = results[1];
    final Map<String, int> tokenMap = {};
    if (tokens['success'] == true) {
      final lista = List<Map<String, dynamic>>.from(tokens['tokens'] ?? []);
      _valorPortfolio = lista.fold(0.0, (sum, t) {
        final valorAtual = (t['valorAtual'] as num?)?.toDouble() ?? 0.0;
        final quantidade = (t['quantidade'] as num?)?.toInt() ?? 0;
        return sum + valorAtual * quantidade;
      });

      for (final t in lista) {
        final id = t['startupId'] as String? ?? '';
        final qty = (t['quantidade'] as num?)?.toInt() ?? 0;
        if (id.isNotEmpty && qty > 0) tokenMap[id] = qty;
      }
    }

    final startups = results[2];
    if (startups['success'] == true) {
      final lista = List<Map<String, dynamic>>.from(startups['data'] as List);
      _meusInvestimentos = lista
          .where((s) => tokenMap.containsKey(s['id'] as String? ?? ''))
          .toList();
      _tokenMap = tokenMap;
    }

    final portfolioHistory = results[3];
    if (portfolioHistory['success'] == true) {
      _portfolioHistory = List<Map<String, dynamic>>.from(
        portfolioHistory['points'] ?? [],
      );
    }

    setState(() => _isLoading = false);
    _loadLogoUrls();
  }

  Future<void> _loadLogoUrls() async {
    final entries = await Future.wait(
      _meusInvestimentos.map((data) async {
        final id = data['id'] as String? ?? '';
        final url = await StorageService.getStartupAsset(
          data['nome'] as String? ?? '', 'logoPhoto.jpeg');
        return MapEntry(id, url);
      }),
    );
    if (!mounted) return;
    setState(() => _logoUrls = Map.fromEntries(entries));
  }






  List<Map<String, dynamic>> _portfolioHistoricoFiltrado() {
    if (_portfolioHistory.isEmpty) return [];
    final agora = DateTime.now();
    DateTime? dataInicial;
    switch (_selectedPeriodPortfolio) {
      case 0: dataInicial = agora.subtract(const Duration(days: 7)); break;
      case 1: dataInicial = agora.subtract(const Duration(days: 30)); break;
      case 2: dataInicial = agora.subtract(const Duration(days: 180)); break;
      case 3: dataInicial = DateTime(agora.year, 1, 1); break;
      default: dataInicial = null;
    }
    if (dataInicial == null) return _portfolioHistory;
    return _portfolioHistory.where((item) {
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      if (date == null) return false;
      return date.isAfter(dataInicial!);
    }).toList();
  }

  List<String> _labelsGraficoPortfolio() {
    const meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];
    return _portfolioHistoricoFiltrado().map((item) {
      final date = DateTime.tryParse(item['date']?.toString() ?? '');
      if (date == null) return '';
      if (_selectedPeriodPortfolio >= 2) return meses[date.month - 1];
      return '${date.day}/${date.month}';
    }).toList();
  }

  List<FlSpot> _gerarPontosPercentuaisPortfolio() {
    final filtrado = _portfolioHistoricoFiltrado();
    return List.generate(filtrado.length, (i) {
      final pct = (filtrado[i]['returnPercent'] as num?)?.toDouble() ?? 0.0;
      return FlSpot(i.toDouble(), pct);
    });
  }

  Color _corGraficoPortfolio() {
    final filtrado = _portfolioHistoricoFiltrado();
    if (filtrado.length < 2) return AppColors.cinza400;
    final primeiro = (filtrado.first['returnPercent'] as num?)?.toDouble() ?? 0.0;
    final ultimo = (filtrado.last['returnPercent'] as num?)?.toDouble() ?? 0.0;
    if (ultimo > primeiro) return AppColors.verde;
    if (ultimo < primeiro) return AppColors.vermelho;
    return AppColors.cinza400;
  }

  String _formatarPercentualGrafico(double valor) {
    final sinal = valor > 0 ? '+' : '';
    return '$sinal${valor.toStringAsFixed(2)}%';
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
            HomeFinanceCard(
              saldo: _saldo,
              saldoVisivel: _saldoVisivel,
              valorPortfolio: _valorPortfolio,
              totalTokens: _totalTokens,
              isLoading: _isLoading,
              currencyFormat: currencyFormat,
              onVisibilityChanged: (v) {
                setState(() => _saldoVisivel = v);
                _saveVisibility(v);
              },
              onDepositar: _showAddBalanceDialog,
            ),

            if (!_isLoading) ...[
            const SizedBox(height: 28),

            PortfolioChartSection(
              pontos: _gerarPontosPercentuaisPortfolio(),
              labels: _labelsGraficoPortfolio(),
              cor: _corGraficoPortfolio(),
              periods: _periodsPortfolio,
              selectedPeriod: _selectedPeriodPortfolio,
              onPeriodChanged: (i) => setState(() => _selectedPeriodPortfolio = i),
              formatLabel: _formatarPercentualGrafico,
              portfolioHistory: _portfolioHistory,
              valorPortfolio: _valorPortfolio,
            ),

            ], // end if (!_isLoading)

            const SizedBox(height: 28),

            // Meus investimentos
            const Text(
              'Meus investimentos',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'JosefinSans',
              ),
            ),

            const SizedBox(height: 12),

            if (_isLoading)
              const AppLoadingIndicator()
            else if (_meusInvestimentos.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.branco,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cinza200),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.business_center_outlined, size: 32, color: AppColors.cinza300),
                      SizedBox(height: 8),
                      Text(
                        'Você ainda não investiu em nenhuma startup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 13,
                          color: AppColors.cinza500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._meusInvestimentos.map((data) {
                final id = data['id'] as String? ?? '';
                return GestureDetector(
                  onTap: () async {
                    final comprou = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StartupDetailPage(
                          startupId: id,
                          startupNome: data['nome'] as String? ?? '',
                          usuario: widget.usuario,
                          onTabSwitch: widget.onTabSwitch,
                          activeTabIndex: 0,
                        ),
                      ),
                    );
                    if (comprou == true && mounted) _loadData();
                  },
                  child: InvestimentoCard(
                    data: data,
                    logoUrl: _logoUrls[id],
                    tokenQuantity: _tokenMap[id] ?? 0,
                    currencyFormat: currencyFormat,
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



