// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Tela do catálogo das startups, com filtros funcionais

import 'package:flutter/material.dart';
import '../../services/startup_service.dart';
import 'package:intl/intl.dart';
import 'startup_detail_page.dart';

const Map<String, String> _estagioLabels = {
  'nova': 'Nova',
  'em_operacao': 'Em Operação',
  'em_expansao': 'Em Expansão',
};

class InitialCatalogPage extends StatefulWidget {
  const InitialCatalogPage({super.key});

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
  void initState() {
    super.initState();
    fetchStartups();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchStartups() async {
    final requestId = ++_requestId;

    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await StartupService.getStartups(
      estagio: filterValues[selectedFilter],
    );

    if (requestId != _requestId) return;

    setState(() {
      isLoading = false;
      if (result['success'] as bool) {
        startups = List<Map<String, dynamic>>.from(result['data'] as List);
      } else {
        error = result['message'] as String?;
      }
    });
  }

  List<Map<String, dynamic>> get _filteredStartups {
    if (_searchQuery.isEmpty) return startups;
    return startups.where((s) {
      final nome = (s['nome'] as String? ?? '').toLowerCase();
      final setor = (s['setor'] as String? ?? '').toLowerCase();
      return nome.contains(_searchQuery) || setor.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        selectedItemColor: Colors.blue,
        onTap: (index) {
          if (index == 1) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Em breve')),
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
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
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  filled: true,
                  fillColor: Colors.grey[200],
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
                            color: isSelected ? Colors.blue : Colors.grey[300],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            filters[index],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
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
                    ? const Center(child: CircularProgressIndicator(color: Colors.blue))
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
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => StartupDetailPage(
                                          startupId: data['id'] as String? ?? '',
                                          startupNome: data['nome'] as String? ?? '',
                                        ),
                                      ),
                                    ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black12),
        image: logoUrl != null
            ? DecorationImage(
                image: NetworkImage(logoUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.85),
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
              style: TextStyle(color: Colors.grey[600]),
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
                color: Colors.grey[500],
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
