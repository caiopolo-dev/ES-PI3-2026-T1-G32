// Autor: Caio Ferreira Polo
// Descrição: Tela do balcão de negociação — listagem e compra de ofertas de tokens

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'buy_steps_page.dart';

class BalcaoNegociacaoPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const BalcaoNegociacaoPage({super.key, this.usuario, this.onTabSwitch, this.isActive = false});

  @override
  State<BalcaoNegociacaoPage> createState() => _BalcaoNegociacaoPageState();
}

class _BalcaoNegociacaoPageState extends State<BalcaoNegociacaoPage> {
  final _currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  List<dynamic> offers = [];
  bool isLoadingOffers = true;
  String? offersError;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  List<dynamic> myOffers = [];
  bool isLoadingMyOffers = true;
  String? myOffersError;
  Map<String, String?> _logoUrls = {};

  _SortMode _sortMode = _SortMode.alphabetical;

  @override
  void initState() {
    super.initState();
    if (widget.isActive) _loadAll();
  }

  @override
  void didUpdateWidget(BalcaoNegociacaoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) _loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    await Future.wait([loadOffers(), loadMyOffers()]);
    _loadLogoUrls();
  }

  Future<void> _loadLogoUrls() async {
    final names = <String>{
      for (final o in [...offers, ...myOffers])
        (o['startupName'] ?? o['startupId'] ?? '').toString(),
    }..remove('');
    final entries = await Future.wait(
      names.map((name) async {
        final url = await StorageService.getStartupAsset(name, 'logoPhoto.jpeg');
        return MapEntry(name, url);
      }),
    );
    if (!mounted) return;
    setState(() => _logoUrls = Map.fromEntries(entries));
  }

  Future<void> loadOffers() async {
    if (!mounted) return;
    setState(() { isLoadingOffers = true; offersError = null; });
    try {
      final result = await FirebaseFunctions.instance.httpsCallable('listOffers').call();
      if (!mounted) return;
      setState(() {
        offers = (result.data['data'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        isLoadingOffers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { offersError = 'Erro ao carregar ofertas'; isLoadingOffers = false; });
    }
  }

  Future<void> loadMyOffers() async {
    if (!mounted) return;
    setState(() { isLoadingMyOffers = true; myOffersError = null; });
    final result = await WalletService.listMyOffers();
    if (!mounted) return;
    setState(() {
      isLoadingMyOffers = false;
      if (result['success'] == true) {
        myOffers = List<dynamic>.from(result['offers'] ?? []);
      } else {
        myOffersError = result['message']?.toString() ?? 'Erro ao carregar suas ordens';
      }
    });
  }

  List<dynamic> get filteredOffers {
    final q = _search.trim().toLowerCase();
    var list = q.isEmpty
        ? List<dynamic>.from(offers)
        : offers.where((o) =>
            (o['startupName'] ?? o['startupId'] ?? '')
                .toString()
                .toLowerCase()
                .contains(q))
            .toList();

    switch (_sortMode) {
      case _SortMode.alphabetical:
        list.sort((a, b) =>
            (a['startupName'] ?? a['startupId'] ?? '')
                .toString()
                .compareTo((b['startupName'] ?? b['startupId'] ?? '').toString()));
      case _SortMode.priceAsc:
        list.sort((a, b) =>
            ((a['valorUnitarioCentavos'] as num?) ?? 0)
                .compareTo((b['valorUnitarioCentavos'] as num?) ?? 0));
      case _SortMode.priceDesc:
        list.sort((a, b) =>
            ((b['valorUnitarioCentavos'] as num?) ?? 0)
                .compareTo((a['valorUnitarioCentavos'] as num?) ?? 0));
    }

    return list;
  }

  Future<void> _openUserTokensForSell() async {
    final selectedToken = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _UserTokensSheet(),
    );

    if (selectedToken == null || !mounted) return;

    final pricePerTokenCents =
        (((selectedToken['valorAtual'] as num?)?.toDouble() ?? 0.0) * 100).round();

    final vendeu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyStepsPage(
          startupName: selectedToken['startupNome'] as String? ?? '',
          startupId: selectedToken['startupId'] as String? ?? '',
          availableQuantity: (selectedToken['quantidade'] as num?)?.toInt() ?? 0,
          pricePerTokenCents: pricePerTokenCents,
          isSellMode: true,
        ),
      ),
    );
    if (vendeu == true && mounted) _loadAll();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.cinza100,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openUserTokensForSell,
          backgroundColor: AppColors.azul,
          foregroundColor: AppColors.branco,
          icon: const Icon(Icons.arrow_upward),
          label: const Text(
            'Criar ordem de venda',
            style: TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.bold),
          ),
        ),
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
          bottom: const TabBar(
            labelColor: AppColors.azul,
            unselectedLabelColor: AppColors.cinza500,
            indicatorColor: AppColors.azul,
            labelStyle: TextStyle(fontFamily: 'JosefinSans', fontWeight: FontWeight.bold),
            unselectedLabelStyle: TextStyle(fontFamily: 'JosefinSans'),
            tabs: [
              Tab(text: 'Mercado'),
              Tab(text: 'Minhas ordens'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMercado(),
            _buildMinhasOrdens(),
          ],
        ),
      ),
    );
  }

  Widget _buildMercado() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: AppSearchField(
            controller: _searchController,
            hintText: 'Buscar startup…',
            onChanged: (v) => setState(() => _search = v),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                AppFilterChip(
                  label: 'A–Z',
                  selected: _sortMode == _SortMode.alphabetical,
                  onTap: () => setState(() => _sortMode = _SortMode.alphabetical),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Menor preço',
                  icon: Icons.arrow_downward,
                  selected: _sortMode == _SortMode.priceAsc,
                  onTap: () => setState(() => _sortMode = _SortMode.priceAsc),
                ),
                const SizedBox(width: 8),
                AppFilterChip(
                  label: 'Maior preço',
                  icon: Icons.arrow_upward,
                  selected: _sortMode == _SortMode.priceDesc,
                  onTap: () => setState(() => _sortMode = _SortMode.priceDesc),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: isLoadingOffers
              ? const AppLoadingIndicator()
              : offersError != null
                  ? Center(child: Text(offersError!, style: const TextStyle(fontFamily: 'JosefinSans', color: AppColors.cinza500)))
                  : offers.isEmpty
                      ? _emptyState('Nenhuma oferta disponível no momento', Icons.storefront_outlined)
                      : filteredOffers.isEmpty
                          ? _emptyState('Nenhuma oferta encontrada', Icons.search_off)
                          : RefreshIndicator(
                              onRefresh: loadOffers,
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                                itemCount: filteredOffers.length,
                                itemBuilder: (context, index) {
                                  final data = filteredOffers[index];
                                  final name = (data['startupName'] ?? data['startupId'] ?? '').toString();
                                  return _OfferCard(
                                    data: data,
                                    currency: _currency,
                                    logoUrl: _logoUrls[name],
                                    onTap: () async {
                                      final comprou = await Navigator.push<bool>(context,
                                        MaterialPageRoute(builder: (_) => BuyStepsPage(
                                          startupName: name,
                                          availableQuantity: int.tryParse((data['amount'] ?? 0).toString()) ?? 0,
                                          pricePerTokenCents: int.tryParse((data['valorUnitarioCentavos'] ?? 0).toString()) ?? 0,
                                          offerId: (data['offerId'] ?? '').toString(),
                                        )),
                                      );
                                      if (comprou == true && mounted) loadOffers();
                                    },
                                  );
                                },
                              ),
                            ),
        ),
      ],
    );
  }

  Widget _buildMinhasOrdens() {
    return isLoadingMyOffers
        ? const AppLoadingIndicator()
        : myOffersError != null
            ? Center(child: Text(myOffersError!, style: const TextStyle(fontFamily: 'JosefinSans', color: AppColors.cinza500)))
            : myOffers.isEmpty
                ? _emptyState('Você não possui ordens em aberto', Icons.receipt_long_outlined)
                : RefreshIndicator(
                    onRefresh: loadMyOffers,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                      itemCount: myOffers.length,
                      itemBuilder: (context, index) {
                        final data = myOffers[index];
                        final name = (data['startupName'] ?? data['startupId'] ?? '').toString();
                        return _MyOrderCard(
                          data: data,
                          currency: _currency,
                          logoUrl: _logoUrls[name],
                        );
                      },
                    ),
                  );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: AppColors.cinza300),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'JosefinSans', color: AppColors.cinza500, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

enum _SortMode { alphabetical, priceAsc, priceDesc }

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final VoidCallback onTap;
  final String? logoUrl;

  const _OfferCard({required this.data, required this.currency, required this.onTap, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final name = (data['startupName'] ?? data['startupId'] ?? '—').toString();
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final centavos = (data['valorUnitarioCentavos'] as num?)?.toDouble() ?? 0;
    final preco = centavos / 100;
    final mercadoCentavos = (data['precoMercadoCentavos'] as num?)?.toDouble() ?? 0;
    final temMercado = mercadoCentavos > 0;
    final abaixo = temMercado && centavos < mercadoCentavos;
    final acima = temMercado && centavos > mercadoCentavos;

    final accentColor = abaixo
        ? AppColors.verde
        : acima
            ? AppColors.vermelho
            : AppColors.azul;

    final double diffPct = temMercado && mercadoCentavos > 0
        ? ((centavos - mercadoCentavos) / mercadoCentavos * 100)
        : 0;
    final diffLabel = diffPct == 0
        ? 'No mercado'
        : '${diffPct > 0 ? '+' : ''}${diffPct.toStringAsFixed(1)}%';

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
                // Borda colorida lateral
                Container(width: 5, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Linha superior: logo + nome + preço
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: accentColor.withValues(alpha: 0.1),
                              backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                              child: logoUrl == null
                                  ? Icon(Icons.business, color: accentColor, size: 20)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currency.format(preco),
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: accentColor,
                                  ),
                                ),
                                const Text(
                                  'por token',
                                  style: TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 10,
                                    color: AppColors.cinza500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Container(height: 1, color: AppColors.cinza200),
                        const SizedBox(height: 10),

                        // Linha inferior: quantidade + referência de mercado
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Quantidade em destaque
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.azul.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.toll_outlined, size: 13, color: AppColors.azul),
                                  const SizedBox(width: 4),
                                  Text(
                                    NumberFormat('#,##0', 'pt_BR').format(amount),
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.azul,
                                    ),
                                  ),
                                  const Text(
                                    ' tokens',
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 12,
                                      color: AppColors.azul,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Referência de mercado
                            if (temMercado)
                              Row(
                                children: [
                                  Text(
                                    'Mercado ${currency.format(mercadoCentavos / 100)}',
                                    style: const TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 11,
                                      color: AppColors.cinza500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: accentColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      diffLabel,
                                      style: TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: accentColor,
                                      ),
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
      ),
    );
  }
}

class _MyOrderCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final NumberFormat currency;
  final String? logoUrl;

  const _MyOrderCard({required this.data, required this.currency, this.logoUrl});

  @override
  Widget build(BuildContext context) {
    final name = (data['startupName'] ?? data['startupId'] ?? '—').toString();
    final amount = (data['amount'] as num?)?.toInt() ?? 0;
    final centavos = (data['valorUnitarioCentavos'] as num?)?.toDouble() ?? 0;
    final preco = centavos / 100;
    final total = preco * amount;

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
              Container(width: 5, color: AppColors.amarelo),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.amarelo.withValues(alpha: 0.15),
                            backgroundImage: logoUrl != null ? NetworkImage(logoUrl!) : null,
                            child: logoUrl == null
                                ? const Icon(Icons.arrow_upward, color: AppColors.amarelo, size: 20)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.amarelo.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Em aberto',
                                    style: TextStyle(
                                      fontFamily: 'JosefinSans',
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.amarelo,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                currency.format(preco),
                                style: const TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.azul,
                                ),
                              ),
                              const Text(
                                'por token',
                                style: TextStyle(
                                  fontFamily: 'JosefinSans',
                                  fontSize: 10,
                                  color: AppColors.cinza500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(height: 1, color: AppColors.cinza200),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.azul.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.toll_outlined, size: 13, color: AppColors.azul),
                                const SizedBox(width: 4),
                                Text(
                                  '${NumberFormat('#,##0', 'pt_BR').format(amount)} tokens',
                                  style: const TextStyle(
                                    fontFamily: 'JosefinSans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.azul,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _Stat(
                            label: 'Total da ordem',
                            value: currency.format(total),
                            alignEnd: true,
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

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _Stat({required this.label, required this.value, this.alignEnd = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 11, color: AppColors.cinza500)),
        Text(value, style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _UserTokensSheet extends StatefulWidget {
  const _UserTokensSheet();

  @override
  State<_UserTokensSheet> createState() => _UserTokensSheetState();
}

class _UserTokensSheetState extends State<_UserTokensSheet> {
  List<Map<String, dynamic>> _tokens = [];
  bool _isLoading = true;
  Map<String, String?> _logoUrls = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await WalletService.getUserTokens();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result['success'] == true) {
        _tokens = List<Map<String, dynamic>>.from(result['tokens'] ?? []);
      }
    });
    _loadLogoUrls();
  }

  Future<void> _loadLogoUrls() async {
    final entries = await Future.wait(
      _tokens.map((t) async {
        final nome = (t['startupNome'] as String?) ?? '';
        final url = await StorageService.getStartupAsset(nome, 'logoPhoto.jpeg');
        return MapEntry(nome, url);
      }),
    );
    if (!mounted) return;
    setState(() => _logoUrls = Map.fromEntries(entries));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.cinza300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Meus tokens',
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const AppLoadingIndicator()
                : _tokens.isEmpty
                    ? const Center(
                        child: Text(
                          'Você não possui tokens',
                          style: TextStyle(fontFamily: 'JosefinSans', color: AppColors.cinza500),
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _tokens.length,
                        itemBuilder: (context, index) {
                          final token = _tokens[index];
                          final logoUrl = _logoUrls[token['startupNome'] as String? ?? ''];
                          final quantidade = (token['quantidade'] as num?)?.toInt() ?? 0;
                          final valorAtual = (token['valorAtual'] as num?)?.toDouble() ?? 0.0;

                          return GestureDetector(
                            onTap: () => Navigator.pop(context, token),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cinza100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.cinza300),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: AppColors.azul.withValues(alpha: 0.1),
                                    backgroundImage: logoUrl != null ? NetworkImage(logoUrl) : null,
                                    child: logoUrl == null
                                        ? const Icon(Icons.business, color: AppColors.azul, size: 20)
                                        : null,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text(
                                      token['startupNome'] as String? ?? '—',
                                      style: const TextStyle(
                                        fontFamily: 'JosefinSans',
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '$quantidade tokens',
                                        style: const TextStyle(
                                          fontFamily: 'JosefinSans',
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'R\$ ${valorAtual.toStringAsFixed(2).replaceAll('.', ',')}/un',
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
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
