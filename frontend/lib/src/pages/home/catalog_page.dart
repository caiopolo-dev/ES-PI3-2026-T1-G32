// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Tela do catálogo das startups, com filtros funcionais

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:intl/intl.dart';
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
    // Atualiza _searchQuery a cada keystroke para filtrar a lista em tempo real.
    _searchController.addListener(() {
      if (!mounted) return;
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
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

              // Barra de busca
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Buscar startup",
                  prefixIcon: const Icon(Icons.search, color: AppColors.azul),
                  filled: true,
                  fillColor: AppColors.cinza200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Filtros
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(filters.length, (index) {
                    final isSelected = selectedFilter == index;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => selectedFilter = index);
                          fetchStartups();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.azul : AppColors.cinza300,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              color: isSelected ? AppColors.branco : AppColors.preto,
                            ),
                          ),
                        ),
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
                                  final assets = data['assets'] as Map<String, dynamic>?;
                                  final photos = assets?['photos'] as Map<String, dynamic>?;
                                  final logoUrl = photos?['logoPhoto'] as String?;

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
                                      precoToken: (data['precoToken'] as num?)?.toDouble() ?? 0.0,
                                      totalTokens: (data['totalTokens'] as num?)?.toInt() ?? 0,
                                      logoUrl: logoUrl,
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

// Card de cada startup
class StartupCard extends StatelessWidget {
  final String nome;
  final String setor;
  final String estagio;
  final double precoToken;
  final int totalTokens;
  final String? logoUrl;

  const StartupCard({
    super.key,
    required this.nome,
    required this.setor,
    required this.estagio,
    required this.precoToken,
    required this.totalTokens,
    this.logoUrl,
  });

  @override
  Widget build(BuildContext context) {
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
                  AppColors.branco.withValues(alpha: 0.85),
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
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              setor,
              style: TextStyle(color: AppColors.cinza700),
            ),

            const SizedBox(height: 10),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Preço do token"),
                Text("R\$ ${NumberFormat('#,##0.00', 'pt_BR').format(precoToken)}"),
              ],
            ),

            const SizedBox(height: 5),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total de tokens"),
                Text(NumberFormat('#,##0', 'pt_BR').format(totalTokens)),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              _estagioLabels[estagio] ?? estagio.replaceAll('_', ' '),
              style: TextStyle(
                color: AppColors.cinza500,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}