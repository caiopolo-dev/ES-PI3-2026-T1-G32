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
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

import 'package:fl_chart/fl_chart.dart';
import 'package:mescla_invest/src/widgets/graficos.dart';

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

  List<Map<String, dynamic>> _meusInvestimentos = [];
  List<Map<String, dynamic>> _portfolioHistory = [];
  Map<String, int> _tokenMap = {};
  Map<String, String?> _logoUrls = {};

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
    setState(() => _isLoading = true);

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
      debugPrint('PORTFOLIO HISTORY SUCCESS: ${portfolioHistory['success']}');
      debugPrint('PORTFOLIO HISTORY POINTS: ${_portfolioHistory.length}');
      debugPrint('PORTFOLIO HISTORY DATA: $_portfolioHistory');

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






  List<String> _labelsGraficoPortfolio() {
    return _portfolioHistory.map((item) {
      final date = DateTime.tryParse(item['date']?.toString() ?? '');

      if (date == null) return '';

      final dataLocal = date.toUtc().subtract(const Duration(hours: 3));

      return '${dataLocal.day}/${dataLocal.month}';
    }).toList();
  }


  List<FlSpot> _gerarPontosPercentuaisPortfolio() {
    if (_portfolioHistory.isEmpty) return [];

    final pontosOrdenados = List<Map<String, dynamic>>.from(_portfolioHistory)
      ..sort((a, b) {
        final da = DateTime.tryParse(a['date']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final db = DateTime.tryParse(b['date']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return da.compareTo(db);
      });

    final List<FlSpot> pontos = [];

    for (int i = 0; i < pontosOrdenados.length; i++) {
      final percentual =
          (pontosOrdenados[i]['returnPercent'] as num?)?.toDouble() ?? 0.0;

      pontos.add(FlSpot(i.toDouble(), percentual));
    }

    return pontos;
  }

  String _formatarPercentualGrafico(double valor) {
    final sinal = valor > 0 ? '+' : '';
    return '$sinal${valor.toStringAsFixed(1)}%';
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SaldoDisplay(
                              saldo: _saldo,
                              visivel: _saldoVisivel,
                              label: 'Saldo disponível',
                              labelColor: AppColors.branco,
                              balanceColor: AppColors.branco,
                              eyeColor: AppColors.branco54,
                              balanceFontSize: 32,
                              onVisibilityChanged: (v) { setState(() => _saldoVisivel = v); _saveVisibility(v); },
                            ),
                            GestureDetector(
                              onTap: _showAddBalanceDialog,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10.5),
                                decoration: BoxDecoration(
                                  color: AppColors.azul800.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.azul200.withValues(alpha: 0.5)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add, size: 16, color: AppColors.branco),
                                    SizedBox(width: 6),
                                    Text(
                                      'Depositar',
                                      style: TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 14,
                                        color: AppColors.branco,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _StatItem(label: 'Portfólio', value: _saldoVisivel ? currencyFormat.format(_valorPortfolio) : '••••••'),
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
                  'Histórico',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.cinza500,
                    fontFamily: 'JosefinSans',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            GraficoLinha(
              pontos: _gerarPontosPercentuaisPortfolio(),
              labelsInferiores: _labelsGraficoPortfolio(),
              formatarValorEsquerda: _formatarPercentualGrafico,
            ),

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
                  child: _InvestimentoCard(
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

class _InvestimentoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String? logoUrl;
  final int tokenQuantity;
  final NumberFormat currencyFormat;

  const _InvestimentoCard({
    required this.data,
    required this.logoUrl,
    required this.tokenQuantity,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final precoAtual = (data['precoToken'] as num?)?.toDouble() ?? 0.0;
    final fechamento = (data['fechamentoOntemCentavos'] as num?)?.toDouble();
    final temVariacao = fechamento != null && fechamento > 0;
    final variacaoPct = temVariacao ? (precoAtual - fechamento) / fechamento * 100 : 0.0;
    final accentColor = temVariacao
        ? (variacaoPct >= 0 ? AppColors.verde : AppColors.vermelho)
        : AppColors.azul;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cinza200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: accentColor.withValues(alpha: 0.1),
                        backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                        child: logoUrl == null
                            ? Icon(Icons.business, color: accentColor, size: 20)
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
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.verde.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.toll_outlined, size: 12, color: AppColors.verde),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$tokenQuantity tokens',
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.verde,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            currencyFormat.format(precoAtual / 100),
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (temVariacao)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.cinza200,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'hoje',
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cinza700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: accentColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        variacaoPct >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                        size: 14,
                                        color: accentColor,
                                      ),
                                      Text(
                                        '${variacaoPct.abs().toStringAsFixed(1)}%',
                                        style: TextStyle(
                                          fontFamily: 'JosefinSans',
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: accentColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

