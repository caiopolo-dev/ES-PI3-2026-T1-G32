// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Tela do catálogo das startups, com filtros funcionais

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:mescla_invest/src/services/storage_service.dart';
import 'package:mescla_invest/src/services/startup_service.dart';
import 'package:mescla_invest/src/pages/home/startup_detail/startup_detail_page.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

const Map<String, String> _estagioLabels = {
  'nova': 'Nova',
  'em_operacao': 'Em Operação',
  'em_expansao': 'Em Expansão',
};

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
  bool isLoading = true;
  String? error;
  int _requestId = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> filters = ["Todas", "Novas", "Em operação", "Em expansão"];
  final List<String?> filterValues = [null, "nova", "em_operacao", "em_expansao"];

  @override
  void didUpdateWidget(InitialCatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega o catálogo ao voltar para esta aba,
    // refletindo novas startups ou mudanças de estoque.
    if (widget.isActive && !oldWidget.isActive) fetchStartups();
  }

  @override
  void initState() {
    super.initState();
    // Carrega o catálogo completo na primeira visita à aba.
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

    final result = await StartupService.getStartups(
      estagio: filterValues[selectedFilter],
      includeDailyVariation: true,
    );

    // Se outro filtro foi selecionado enquanto aguardávamos a resposta, aborta.
    if (requestId != _requestId) return;
    if (!mounted) return;

    setState(() {
      isLoading = false;
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
    if (_searchQuery.isEmpty) return startups;
    return startups.where((s) {
      final nome = (s['nome'] as String? ?? '').toLowerCase();
      final setor = (s['setor'] as String? ?? '').toLowerCase();
      // Retorna a startup se o nome ou o setor contiver o texto buscado.
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

              const SizedBox(height: 20),

              // Lista de startups
              Expanded(
                child: isLoading
                    ? const AppLoadingIndicator()
                    : error != null
                        ? Center(child: Text("Erro: $error"))
                        : _filteredStartups.isEmpty
                            ? const Center(child: Text("Nenhuma startup encontrada"))
                            : ListView.builder(
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
                                    ),
                                  );
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const Map<String, Color> _estagioColors = {
  'nova': AppColors.verde,
  'em_operacao': AppColors.azul,
  'em_expansao': AppColors.laranja,
};

class StartupCard extends StatelessWidget {
  final String nome;
  final String setor;
  final String estagio;
  final double precoToken;
  final double fechamentoOntem;
  final int totalTokens;
  final String? logoUrl;

  const StartupCard({
    super.key,
    required this.nome,
    required this.setor,
    required this.estagio,
    required this.precoToken,
    required this.fechamentoOntem,
    required this.totalTokens,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final accentColor = _estagioColors[estagio] ?? AppColors.azul;
    final Color precoColor;
    final String? variacaoStr;
    if (fechamentoOntem <= 0) {
      precoColor = AppColors.azul;
      variacaoStr = null;
    } else {
      final pct = (precoToken - fechamentoOntem) / fechamentoOntem * 100;
      variacaoStr =
          '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(1)}% · hoje';
      precoColor = pct > 0
          ? AppColors.verde
          : pct < 0
              ? AppColors.vermelho
              : AppColors.azul;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.branco,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.cinza300),
        image: logoUrl != null
            ? DecorationImage(
                image: NetworkImage(logoUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  AppColors.branco.withValues(alpha: 0.82),
                  BlendMode.srcOver,
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              nome,
              style: const TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              setor,
              style: const TextStyle(
                fontFamily: 'JosefinSans',
                fontSize: 13,
                color: AppColors.cinza700,
              ),
            ),
            const SizedBox(height: 12),
            Container(height: 1, color: AppColors.cinza300),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Preço por token',
                  style: TextStyle(
                    fontFamily: 'JosefinSans',
                    fontSize: 12,
                    color: AppColors.cinza700,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: precoColor, width: 1.5),
                      ),
                      child: Text(
                        fmt.format(precoToken),
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: precoColor,
                        ),
                      ),
                    ),
                    if (variacaoStr != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        variacaoStr,
                        style: TextStyle(
                          fontFamily: 'JosefinSans',
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: precoColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.azul.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.toll_outlined,
                          size: 13, color: AppColors.azul),
                      const SizedBox(width: 4),
                      Text(
                        '${NumberFormat('#,##0', 'pt_BR').format(totalTokens)} tokens',
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
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _estagioLabels[estagio] ?? estagio,
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
      ),
    );
  }
}