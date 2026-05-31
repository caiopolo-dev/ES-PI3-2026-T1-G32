// Autor: Caio Ferreira Polo
// Descrição: Tela do balcão de negociação — listagem e compra de ofertas de tokens

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/private/buy_steps/buy_steps_page.dart';
import 'package:mescla_invest/src/pages/private/balcao/widgets/offer_card.dart';
import 'package:mescla_invest/src/pages/private/balcao/widgets/my_order_card.dart';
import 'package:mescla_invest/src/pages/private/balcao/widgets/user_tokens_sheet.dart';
import 'package:mescla_invest/src/pages/private/balcao/widgets/cancel_offer_dialog.dart';
import 'package:mescla_invest/src/pages/private/balcao/widgets/balcao_widgets.dart';
import 'package:mescla_invest/src/pages/private/balcao/balcao_types.dart';

/// Página principal do balcão de negociação.
///
/// Responsabilidades:
/// - Exibir o mercado de ofertas públicas (`Mercado`).
/// - Exibir as ordens do usuário (`Minhas ordens`).
/// - Expor ações para criar ordens de venda e navegar para passos de compra/venda.
///
/// A página usa `DefaultTabController` para alternar entre as abas e recebe
/// o objeto `usuario` e um callback `onTabSwitch` para navegação externa.
class BalcaoNegociacaoPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const BalcaoNegociacaoPage({
    super.key,
    this.usuario,
    this.onTabSwitch,
    this.isActive = false,
  });

  @override
  State<BalcaoNegociacaoPage> createState() => _BalcaoNegociacaoPageState();
}

/// Estado da página `BalcaoNegociacaoPage`.
///
/// Mantém os arrays de ofertas, flags de carregamento/erro, filtros de
/// pesquisa e ordenação, e um cache local de URLs de logos para melhorar
/// desempenho na renderização dos cards.
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

  /// Modo de ordenação das listas exibidas na aba de mercado.
  /// Pode ser alterado pelo usuário através dos chips de ordenação.
  SortMode _sortMode = SortMode.alphabetical;

  /// Modo de ordenação usado especificamente na aba "Minhas ordens".
  SortMode _mySortMode = SortMode.alphabetical;

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

  /// Carrega simultaneamente ofertas públicas e ordens do usuário,
  /// e em seguida inicia o carregamento dos logos para exibição.
  ///
  /// Usa `Future.wait` para paralelizar `loadOffers()` e `loadMyOffers()`.
  Future<void> _loadAll() async {
    await Future.wait([loadOffers(), loadMyOffers()]);
    _loadLogoUrls();
  }

  /// Popula o mapa `_logoUrls` com URLs de logo para as startups
  /// presentes nas listas `offers` e `myOffers`.
  ///
  /// Observações:
  /// - Remove entradas vazias antes de requisitar ao Storage.
  /// - Agrupa nomes únicos para evitar requisições duplicadas.
  Future<void> _loadLogoUrls() async {
    final names = <String>{
      for (final o in [...offers, ...myOffers])
        (o['startupName'] ?? o['startupId'] ?? '').toString(),
    }..remove('');
    final entries = await Future.wait(
      names.map((name) async {
        final url = await StorageService.getStartupAsset(
          name,
          'logoPhoto.jpeg',
        );
        return MapEntry(name, url);
      }),
    );
    if (!mounted) return;
    setState(() => _logoUrls = Map.fromEntries(entries));
  }

  Future<void> loadOffers() async {
    if (!mounted) return;
    setState(() {
      isLoadingOffers = true;
      offersError = null;
    });
    final result = await WalletService.listOffers();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() {
        offers = List<Map<String, dynamic>>.from(result['data'] ?? []);
        isLoadingOffers = false;
      });
    } else {
      setState(() {
        offersError =
            result['message'] as String? ?? 'Erro ao carregar ofertas';
        isLoadingOffers = false;
      });
    }
  }

  /// Requisita ao `WalletService` a lista de ofertas públicas do mercado.
  /// Atualiza `offers`, `isLoadingOffers` e `offersError` conforme o resultado.
  ///
  /// Observações de implementação:
  /// - Verifica `mounted` antes de chamar `setState` para evitar erros
  ///   quando o widget tiver sido descartado durante a requisição.

  Future<void> loadMyOffers() async {
    if (!mounted) return;
    setState(() {
      isLoadingMyOffers = true;
      myOffersError = null;
    });
    final result = await WalletService.listMyOffers();
    if (!mounted) return;
    setState(() {
      isLoadingMyOffers = false;
      if (result['success'] == true) {
        myOffers = List<dynamic>.from(result['offers'] ?? []);
      } else {
        myOffersError =
            result['message']?.toString() ?? 'Erro ao carregar suas ordens';
      }
    });
  }

  /// Retorna as ordens do usuário já ordenadas de acordo com `_mySortMode`.
  ///
  /// NOTA: a ordenação é aplicada sobre uma cópia da lista para evitar
  /// mutações inesperadas em `myOffers` que poderiam causar efeitos colaterais
  /// ao re-renderizar a UI.
  List<dynamic> get filteredMyOffers {
    final list = List<dynamic>.from(myOffers);
    switch (_mySortMode) {
      case SortMode.alphabetical:
        list.sort(
          (a, b) => (a['startupName'] ?? a['startupId'] ?? '')
              .toString()
              .compareTo((b['startupName'] ?? b['startupId'] ?? '').toString()),
        );
      case SortMode.priceAsc:
        list.sort(
          (a, b) => ((a['valorUnitarioCentavos'] as num?) ?? 0).compareTo(
            (b['valorUnitarioCentavos'] as num?) ?? 0,
          ),
        );
      case SortMode.priceDesc:
        list.sort(
          (a, b) => ((b['valorUnitarioCentavos'] as num?) ?? 0).compareTo(
            (a['valorUnitarioCentavos'] as num?) ?? 0,
          ),
        );
    }
    return list;
  }

  /// Retorna lista de ofertas filtrada por busca (`_search`) e ordenada por
  /// `_sortMode`.
  ///
  /// A busca é case-insensitive e compara o termo com `startupName`/`startupId`.
  List<dynamic> get filteredOffers {
    final q = _search.trim().toLowerCase();
    var list = q.isEmpty
        ? List<dynamic>.from(offers)
        : offers
              .where(
                (o) => (o['startupName'] ?? o['startupId'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(q),
              )
              .toList();

    switch (_sortMode) {
      case SortMode.alphabetical:
        list.sort(
          (a, b) => (a['startupName'] ?? a['startupId'] ?? '')
              .toString()
              .compareTo((b['startupName'] ?? b['startupId'] ?? '').toString()),
        );
      case SortMode.priceAsc:
        list.sort(
          (a, b) => ((a['valorUnitarioCentavos'] as num?) ?? 0).compareTo(
            (b['valorUnitarioCentavos'] as num?) ?? 0,
          ),
        );
      case SortMode.priceDesc:
        list.sort(
          (a, b) => ((b['valorUnitarioCentavos'] as num?) ?? 0).compareTo(
            (a['valorUnitarioCentavos'] as num?) ?? 0,
          ),
        );
    }

    return list;
  }

  Future<void> _openUserTokensForSell() async {
    // Abre o bottom sheet com tokens do usuário e inicia fluxo de venda.
    // Comentários adicionais acima foram colocados para descrever o fluxo.
    final selectedToken = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const UserTokensSheet(),
    );

    if (selectedToken == null || !mounted) return;

    final quantidade = (selectedToken['quantidade'] as num?)?.toInt() ?? 0;
    final valorAtual = (selectedToken['valorAtual'] as num?)?.toDouble() ?? 0.0;

    final vendeu = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => BuyStepsPage(
          startupName: selectedToken['startupNome'] as String? ?? '',
          startupId: selectedToken['startupId'] as String? ?? '',
          availableQuantity: quantidade,
          pricePerTokenCents: (valorAtual * 100).round(),
          isSellMode: true,
        ),
      ),
    );
    if (vendeu == true && mounted) _loadAll();
  }

  /// Mostra diálogo de confirmação e tenta cancelar a oferta via `WalletService`.
  ///
  /// Retorna `true` quando o cancelamento foi bem-sucedido; caso contrário `false`.
  Future<bool> _confirmCancelOffer(Map<String, dynamic> offer) async {
    final offerId = (offer['offerId'] ?? '').toString();

    if (offerId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID da oferta não encontrado')),
      );
      return false;
    }

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (_) => CancelOfferDialog(offer: offer, currency: _currency),
    );

    if (shouldCancel != true) return false;

    if (!mounted) return false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator(color: AppColors.azul)),
      ),
    );

    final result = await WalletService.cancelOffer(offerId);

    if (!mounted) return false;
    Navigator.of(context).pop();

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta cancelada com sucesso')),
      );
      _loadAll();
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message']?.toString() ?? 'Erro ao cancelar oferta',
          ),
        ),
      );
      return false;
    }
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
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontWeight: FontWeight.bold,
            ),
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
            labelStyle: TextStyle(
              fontFamily: 'JosefinSans',
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: TextStyle(fontFamily: 'JosefinSans'),
            tabs: [
              Tab(text: 'Mercado'),
              Tab(text: 'Minhas ordens'),
            ],
          ),
        ),
        body: TabBarView(children: [_buildMercado(), _buildMinhasOrdens()]),
      ),
    );
  }

  /// Constrói a aba "Mercado": campo de busca, chips de ordenação e lista
  /// de ofertas públicas.
  ///
  /// Lida com estados de carregamento, erro e lista vazia, exibindo os
  /// componentes visuais apropriados.
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
        BalcaoSortChips(
          sortMode: _sortMode,
          onChanged: (mode) => setState(() => _sortMode = mode),
        ),
        Expanded(
          child: isLoadingOffers
              ? const AppLoadingIndicator()
              : offersError != null
              ? Center(
                  child: Text(
                    offersError!,
                    style: const TextStyle(
                      fontFamily: 'JosefinSans',
                      color: AppColors.cinza500,
                    ),
                  ),
                )
              : offers.isEmpty
              ? BalcaoEmptyState(
                  message: 'Nenhuma oferta disponível no momento',
                  icon: Icons.storefront_outlined,
                )
              : filteredOffers.isEmpty
              ? BalcaoEmptyState(
                  message: 'Nenhuma oferta encontrada',
                  icon: Icons.search_off,
                )
              : RefreshIndicator(
                  onRefresh: loadOffers,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 100),
                    itemCount: filteredOffers.length,
                    itemBuilder: (context, index) {
                      final data = filteredOffers[index];
                        final name =
                          (data['startupName'] ?? data['startupId'] ?? '')
                            .toString();
                        // Renderiza cada oferta usando `OfferCard`, fornecendo
                        // dados, moeda formatada e URL do logo quando disponível.
                        return OfferCard(
                        data: data,
                        currency: _currency,
                        logoUrl: _logoUrls[name],
                        onTap: () async {
                          final comprou = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BuyStepsPage(
                                startupName: name,
                                availableQuantity:
                                    int.tryParse(
                                      (data['amount'] ?? 0).toString(),
                                    ) ??
                                    0,
                                pricePerTokenCents:
                                    int.tryParse(
                                      (data['valorUnitarioCentavos'] ?? 0)
                                          .toString(),
                                    ) ??
                                    0,
                                offerId: (data['offerId'] ?? '').toString(),
                              ),
                            ),
                          );
                          if (comprou == true && mounted) _loadAll();
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
    if (isLoadingMyOffers) return const AppLoadingIndicator();
    if (myOffersError != null) {
      return Center(
        child: Text(
          myOffersError!,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            color: AppColors.cinza500,
          ),
        ),
      );
    }

    return Column(
      children: [
        BalcaoSortChips(
          topPadding: 16,
          sortMode: _mySortMode,
          onChanged: (mode) => setState(() => _mySortMode = mode),
        ),
        myOffers.isEmpty
            ? Expanded(
                child: BalcaoEmptyState(
                  message: 'Você não possui ordens em aberto',
                  icon: Icons.receipt_long_outlined,
                ),
              )
            : Expanded(
                child: RefreshIndicator(
                  onRefresh: loadMyOffers,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    itemCount: filteredMyOffers.length,
                    itemBuilder: (context, index) {
                      final offer = Map<String, dynamic>.from(
                        filteredMyOffers[index] as Map,
                      );
                        final name =
                          (offer['startupName'] ?? offer['startupId'] ?? '')
                            .toString();
                        // `Dismissible` permite ao usuário cancelar a ordem
                        // arrastando a célula; `confirmDismiss` abre o diálogo
                        // que de fato executa o cancelamento via `_confirmCancelOffer`.
                        return Dismissible(
                        key: Key((offer['offerId'] ?? index).toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmCancelOffer(offer),
                        secondaryBackground: const BalcaoDismissBackground(),
                        background: const SizedBox.shrink(),
                        child: MyOrderCard(
                          data: offer,
                          currency: _currency,
                          logoUrl: _logoUrls[name],
                          onCancel: () => _confirmCancelOffer(offer),
                        ),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }
}
