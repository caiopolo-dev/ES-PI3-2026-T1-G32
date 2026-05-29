// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Tela do catálogo das startups, com filtros funcionais

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/services/startup_service.dart';
import 'package:mescla_invest/src/services/wallet_service.dart';
import 'package:mescla_invest/src/pages/private/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/pages/private/catalog/widgets/startup_card.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class InitialCatalogPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const InitialCatalogPage({super.key, this.usuario, this.onTabSwitch, this.isActive = false});

  @override
  State<InitialCatalogPage> createState() => _InitialCatalogPageState();
}

class _InitialCatalogPageState extends State<InitialCatalogPage> {
  int selectedFilter = 0;
  List<Map<String, dynamic>> startups = [];
  Map<String, String?> _bannerUrls = {};
  Map<String, int> _userTokens = {};
  bool isLoading = true;
  String? error;
  int _requestId = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showOnlyInvested = false;

  final List<String> filters = ["Todas", "Novas", "Em operação", "Em expansão"];
  final List<String?> filterValues = [null, "nova", "em_operacao", "em_expansao"];

  @override
  void didUpdateWidget(InitialCatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) fetchStartups();
  }

  @override
  void initState() {
    super.initState();
    if (widget.isActive) fetchStartups();
  }

  @override
  void dispose() {
    // Libera o controller para evitar memory leak.
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchStartups() async {
    // Guard contra race condition: se o usuário troca o filtro rapidamente,
    // descartamos respostas de requisições antigas que chegarem depois.
    // Cada chamada recebe um ID único; se outro fetchStartups iniciou depois,
    // o ID atual já não será o mais recente e a resposta é descartada.
    final requestId = ++_requestId;

    setState(() {
      isLoading = true;
      error = null;
    });

    final responses = await Future.wait([
      StartupService.getStartups(
        estagio: filterValues[selectedFilter],
        includeDailyVariation: true,
      ),
      WalletService.getUserTokens(),
    ]);

    if (requestId != _requestId) return;
    if (!mounted) return;

    final result = responses[0];
    final tokensResult = responses[1];

    final Map<String, int> tokenMap = {};
    if (tokensResult['success'] == true) {
      for (final t in (tokensResult['tokens'] as List? ?? [])) {
        final id = t['startupId'] as String? ?? '';
        final qty = ((t['quantidade'] as num?)?.toInt() ?? 0);
        if (id.isNotEmpty && qty > 0) tokenMap[id] = qty;
      }
    }

    setState(() {
      isLoading = false;
      _userTokens = tokenMap;
      if (result['success'] as bool) {
        startups = List<Map<String, dynamic>>.from(result['data'] as List);
      } else {
        error = result['message'] as String?;
      }
    });
    _loadBannerUrls();
  }

  Future<void> _loadBannerUrls() async {
    final entries = await Future.wait(
      startups.map((data) async {
        final id = data['id'] as String? ?? '';
        final url = await StorageService.getStartupAsset(
          data['nome'] as String? ?? '', 'bannerPhoto.png');
        return MapEntry(id, url);
      }),
    );
    if (!mounted) return;
    setState(() => _bannerUrls = Map.fromEntries(entries));
  }

  // Filtra a lista de startups pelo texto digitado na barra de busca.
  // A busca é feita localmente sobre os dados já carregados — sem nova chamada à API.
  List<Map<String, dynamic>> get _filteredStartups {
    return startups.where((s) {
      final id = s['id'] as String? ?? '';
      if (_showOnlyInvested && (_userTokens[id] ?? 0) <= 0) return false;
      if (_searchQuery.isEmpty) return true;
      final nome = (s['nome'] as String? ?? '').toLowerCase();
      final setor = (s['setor'] as String? ?? '').toLowerCase();
      return nome.contains(_searchQuery) || setor.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              AppSearchField(
                controller: _searchController,
                hintText: 'Buscar startup',
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
              ),

              const SizedBox(height: 20),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppFilterChip(
                        label: filters[index],
                        selected: selectedFilter == index,
                        onTap: () {
                          setState(() => selectedFilter = index);
                          fetchStartups();
                        },
                      ),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 10),

              GestureDetector(
                onTap: () => setState(() => _showOnlyInvested = !_showOnlyInvested),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _showOnlyInvested ? AppColors.azul : AppColors.cinza200,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.preto.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showOnlyInvested
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        size: 13,
                        color: _showOnlyInvested ? AppColors.branco : AppColors.cinza700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Somente investidas',
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _showOnlyInvested ? AppColors.branco : AppColors.cinza700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Lista de startups
              Expanded(
                child: isLoading
                    ? const AppLoadingIndicator()
                    : error != null
                        ? Center(child: Text("Erro: $error"))
                        : _filteredStartups.isEmpty
                            ? const Center(child: Text("Nenhuma startup encontrada"))
                            : RefreshIndicator(
                                onRefresh: fetchStartups,
                                child: ListView.builder(
                                itemCount: _filteredStartups.length,
                                itemBuilder: (context, index) {
                                                  final data = _filteredStartups[index];
                                  final id = data['id'] as String? ?? '';
                                  final bannerUrl = _bannerUrls[id];

                                  return GestureDetector(
                                    onTap: () async {
                                      final comprou = await Navigator.push<bool>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => StartupDetailPage(
                                            startupId: data['id'] as String? ?? '',
                                            startupNome: data['nome'] as String? ?? '',
                                            usuario: widget.usuario,
                                            onTabSwitch: widget.onTabSwitch,
                                          ),
                                        ),
                                      );
                                      if (comprou == true && mounted) fetchStartups();
                                    },
                                    child: StartupCard(
                                      nome: data['nome'] as String? ?? '',
                                      setor: data['setor'] as String? ?? '',
                                      estagio: data['estagio'] as String? ?? '',
                                      precoToken: ((data['precoToken'] as num?)?.toDouble() ?? 0.0) / 100,
                                      totalTokens: (data['tokensDisponiveis'] as num?)?.toInt() ?? 0,
                                      fechamentoOntem: ((data['fechamentoOntemCentavos'] as num?)?.toDouble() ?? 0.0) / 100,
                                      logoUrl: bannerUrl,
                                      quantidadeToken: _userTokens[id],
                                    ),
                                  );
                                },
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
