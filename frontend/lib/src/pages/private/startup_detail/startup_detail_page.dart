// Autor: Gustavo Alves de Siqueira Costa
// Data: 30/04/2026
// Descrição: Tela de detalhes de uma startup

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/startup_service.dart';
import 'package:mescla_invest/src/services/faq_service.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/startup_detail_content.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/widgets/startup_detail_widgets.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/widgets/startup_detail_faq.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/startup_detail_types.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/buy_steps_page.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';

class StartupDetailPage extends StatefulWidget {
  final String startupId;
  final String startupNome;
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final int activeTabIndex;

  const StartupDetailPage({
    super.key,
    required this.startupId,
    required this.startupNome,
    this.usuario,
    this.onTabSwitch,
    this.activeTabIndex = 2,
  });

  @override
  State<StartupDetailPage> createState() => _StartupDetailPageState();
}

class _StartupDetailPageState extends State<StartupDetailPage> {
  Map<String, dynamic>? startup;
  bool isLoading = true;
  String? error;
  bool _houvePurchase = false;
  int _userTokenQuantity = 0;
  String? _videoUrl;
  String? _summaryUrl;
  PriceHistoryPeriod _selectedPeriod = PriceHistoryPeriod.sixMonths;
  StartupDetailSection _selectedSection = StartupDetailSection.chart;
  List<Map<String, dynamic>> _faqs = [];
  bool _faqsLoading = false;
  FaqFilter _faqFilter = FaqFilter.todas;
  bool _priceHistoryLoading = false;
  double _valorizacaoPercentual = 0.0;
  List<Map<String, dynamic>> _priceHistory = [];
  List<Map<String, dynamic>> _offers = [];
  bool _offersLoading = false;
  String? _offersError;

  final List<String> _periods = ['1D', '7D', '1M', '6M', 'YTD', 'Tudo'];
  final List<String> _faqFilters = ['Todas', 'Públicas', 'Privadas'];

  @override
  void initState() {
    super.initState();
    _initPage();
    _loadFaqs();
    _loadPriceHistory();
    _loadOffers();
  }

  Future<void> _initPage() async {
    final results = await Future.wait([
      StartupService.getStartupById(widget.startupId),
      WalletService.getUserTokens(),
    ]);
    if (!mounted) return;

    final startupResult = results[0];
    final tokensResult = results[1];
    final tokens = tokensResult['success'] == true
        ? List<Map<String, dynamic>>.from(tokensResult['tokens'] ?? [])
        : <Map<String, dynamic>>[];
    final match = tokens.where((t) => t['startupId'] == widget.startupId);

    setState(() {
      isLoading = false;
      if (startupResult['success'] as bool) {
        startup = startupResult['data'] as Map<String, dynamic>;
        _valorizacaoPercentual =
            (startup?['variacaoHojePercentual'] as num?)?.toDouble() ?? 0.0;
      } else {
        error = startupResult['message'] as String?;
      }
      _userTokenQuantity = match.isNotEmpty
          ? (match.first['quantidade'] as num?)?.toInt() ?? 0
          : 0;
    });
    if (startup != null) {
      _loadStorageAssets(startup!['nome'] as String? ?? '');
    }
  }

  Future<void> _loadStorageAssets(String nome) async {
    final results = await Future.wait([
      StorageService.getStartupAsset(nome, 'video.mp4'),
      StorageService.getStartupAsset(nome, 'summary.pdf'),
    ]);
    if (!mounted) return;
    setState(() {
      _videoUrl = results[0];
      _summaryUrl = results[1];
    });
  }

  Future<void> _loadPriceHistory() async {
    setState(() => _priceHistoryLoading = true);
    final result = await StartupService.getPriceHistory(widget.startupId);
    if (!mounted) return;
    if (result['success'] == true) {
      final history = List<Map<String, dynamic>>.from(result['data'] ?? []);
      history.sort((a, b) {
        final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return dateA.compareTo(dateB);
      });
      setState(() {
        _priceHistory = history;
        _priceHistoryLoading = false;
      });
    } else {
      setState(() => _priceHistoryLoading = false);
    }
  }

  Future<void> _loadOffers() async {
    if (!mounted) return;
    setState(() {
      _offersLoading = true;
      _offersError = null;
    });
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('listOffers')
          .call();
      if (!mounted) return;
      final list = (result.data['data'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .where((o) => (o['startupId'] ?? '').toString() == widget.startupId)
          .where((o) {
            final amount = (o['amount'] as num?)?.toInt() ?? 0;
            final unitCents = (o['valorUnitarioCentavos'] as num?)?.toInt() ?? 0;
            final offerId = (o['offerId'] ?? '').toString();
            return amount > 0 && unitCents > 0 && offerId.isNotEmpty;
          })
          .toList();
      setState(() {
        _offers = list;
        _offersLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _offersError = 'Erro ao carregar ofertas';
        _offersLoading = false;
      });
    }
  }

  Future<void> _loadUserTokens() async {
    final result = await WalletService.getUserTokens();
    if (!mounted || result['success'] != true) return;
    final tokens = List<Map<String, dynamic>>.from(result['tokens'] ?? []);
    final match = tokens.where((t) => t['startupId'] == widget.startupId);
    final qty = match.isNotEmpty
        ? (match.first['quantidade'] as num?)?.toInt() ?? 0
        : 0;
    setState(() {
      _userTokenQuantity = qty;
      if (qty == 0 && _faqFilter == FaqFilter.privadas) _faqFilter = FaqFilter.todas;
    });
  }

  Future<void> _openSellSteps() async {
    final data = startup;
    if (data == null) return;
    final pricePerTokenCents = (data['precoToken'] as num?)?.toInt() ?? 0;
    final vendeu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyStepsPage(
          startupName: data['nome'] as String? ?? widget.startupNome,
          startupId: widget.startupId,
          availableQuantity: _userTokenQuantity,
          pricePerTokenCents: pricePerTokenCents,
          isSellMode: true,
        ),
      ),
    );
    if (!mounted) return;
    if (vendeu == true) {
      _houvePurchase = true;
      _loadUserTokens();
      _loadFaqs();
      _fetchDetail();
      _loadPriceHistory();
    }
  }

  Future<void> _refresh() => Future.wait([
        _initPage(),
        _loadPriceHistory(),
        _loadFaqs(),
        _loadOffers(),
      ]);

  void _handleOfferPurchase() {
    _houvePurchase = true;
    _loadUserTokens();
    _loadFaqs();
    _fetchDetail();
    _loadPriceHistory();
    _loadOffers();
  }

  // O backend filtra FAQs privadas: o usuário só vê as próprias — as de outros são excluídas.
  Future<void> _loadFaqs() async {
    setState(() => _faqsLoading = true);
    final result = await FaqService.getFaqs(widget.startupId);
    if (!mounted) return;
    setState(() {
      _faqsLoading = false;
      if (result['success'] as bool) {
        _faqs = List<Map<String, dynamic>>.from(result['data'] as List);
      }
    });
  }

  Future<void> _showFaqDialog() async {
    final result = await showDialog<FaqResult>(
      context: context,
      builder: (_) => FaqDialog(startupId: widget.startupId, temTokens: _userTokenQuantity > 0),
    );
    // addPostFrameCallback evita chamar setState durante a fase de build após o pop do dialog.
    if (result != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadFaqs());
    }
  }

  Future<void> _fetchDetail() async {
    final result = await StartupService.getStartupById(widget.startupId);
    if (!mounted) return;
    setState(() {
      isLoading = false;
      if (result['success'] as bool) {
        startup = result['data'] as Map<String, dynamic>;
        _valorizacaoPercentual =
            (startup?['variacaoHojePercentual'] as num?)?.toDouble() ?? 0.0;
      } else {
        error = result['message'] as String?;
      }
    });
  }

  Future<void> _openBuyStepsFromStartup() async {
    final data = startup;
    if (data == null) return;
    final startupName = data['nome'] as String? ?? widget.startupNome;
    final pricePerTokenCents = (data['precoToken'] as num?)?.toInt() ?? 0;
    final availableQuantity = (data['tokensDisponiveis'] as num?)?.toInt() ?? 0;

    if (availableQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Essa startup não possui tokens disponíveis.')),
      );
      return;
    }
    if (pricePerTokenCents <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preço do token inválido.')),
      );
      return;
    }

    final comprou = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyStepsPage(
          startupName: startupName,
          startupId: widget.startupId,
          availableQuantity: availableQuantity,
          pricePerTokenCents: pricePerTokenCents,
          isStartupFlow: true,
        ),
      ),
    );
    if (!mounted) return;
    if (comprou == true) {
      _houvePurchase = true;
      _loadUserTokens();
      _loadFaqs();
      _fetchDetail();
      _loadPriceHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.preto),
          onPressed: () => Navigator.pop(context, _houvePurchase),
        ),
        title: Text(
          startup?['nome'] as String? ?? widget.startupNome,
          style: const TextStyle(color: AppColors.preto, fontSize: 22, fontWeight: FontWeight.w400),
        ),
        centerTitle: true,
        actions: [
          UserAvatarMenu(
            usuario: widget.usuario,
            onPerfilTap: () {
              Navigator.pop(context);
              widget.onTabSwitch?.call(4);
            },
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(5, (i) => Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 2.5,
                color: widget.activeTabIndex == i ? AppColors.azul : AppColors.cinza200,
              ),
            )),
          ),
          BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.branco,
            elevation: 0,
            currentIndex: widget.activeTabIndex,
            selectedItemColor: AppColors.azul,
            unselectedItemColor: AppColors.cinza500,
            onTap: (index) {
              Navigator.pop(context, _houvePurchase);
              widget.onTabSwitch?.call(index);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Início'),
              BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Mercado'),
              BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Catálogo'),
              BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Carteira'),
              BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Perfil'),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const AppLoadingIndicator()
          : error != null
              ? Center(child: Text('Erro: $error'))
              : Column(
                  children: [
                    Expanded(
                      child: StartupDetailContent(
                        startup: startup!,
                        priceHistoryLoading: _priceHistoryLoading,
                        priceHistory: _priceHistory,
                        selectedPeriod: _selectedPeriod,
                        selectedSection: _selectedSection,
                        offers: _offers,
                        offersLoading: _offersLoading,
                        offersError: _offersError,
                        videoUrl: _videoUrl,
                        summaryUrl: _summaryUrl,
                        userTokenQuantity: _userTokenQuantity,
                        faqsLoading: _faqsLoading,
                        faqs: _faqs,
                        faqFilter: _faqFilter,
                        valorizacaoPercentual: _valorizacaoPercentual,
                        periods: _periods,
                        faqFilterLabels: _faqFilters,
                        onFaqDialogOpen: _showFaqDialog,
                        onPeriodChanged: (i) => setState(() => _selectedPeriod = PriceHistoryPeriod.values[i]),
                        onFaqFilterChanged: (i) => setState(() => _faqFilter = FaqFilter.values[i]),
                        onSectionChanged: (section) => setState(() => _selectedSection = section),
                        onOffersRefresh: _loadOffers,
                        onOfferPurchased: _handleOfferPurchase,
                        onRefresh: _refresh,
                      ),
                    ),
                    BottomActionBar(
                      onComprar: _openBuyStepsFromStartup,
                      onVender: _openSellSteps,
                      temTokens: _userTokenQuantity > 0,
                    ),
                  ],
                ),
    );
  }
}
