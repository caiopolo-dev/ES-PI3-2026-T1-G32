// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Tela do catálogo das startups, com filtros funcionais

import 'package:flutter/material.dart';
import '../../services/startup_service.dart';

class InitialCatalogPage extends StatefulWidget {
  const InitialCatalogPage({super.key});

  @override
  State<InitialCatalogPage> createState() => _InitialCatalogPageState();
}

class _InitialCatalogPageState extends State<InitialCatalogPage> {
  int selectedFilter = 0;
  List<dynamic> startups = [];
  bool isLoading = true;
  String? error;

  // Mapeamento dos filtros para os valores da API
  final List<String> filters = ["Todas", "Novas", "Em operação", "Em expansão"];
  final List<String?> filterValues = [null, "nova", "em_operacao", "em_expansao"];

  @override
  void initState() {
    super.initState();
    fetchStartups();
  }

  Future<void> fetchStartups() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    final result = await StartupService.getStartups(
      estagio: filterValues[selectedFilter],
    );

    setState(() {
      isLoading = false;
      if (result['success']) {
        startups = result['data'];
      } else {
        error = result['message'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      bottomNavigationBar: BottomNavigationBar(
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
                decoration: InputDecoration(
                  hintText: "Buscar startup",
                  prefixIcon: const Icon(Icons.search),
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
                    bool isSelected = selectedFilter == index;

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
                            color: isSelected ? Colors.black : Colors.grey[300],
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
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text("Erro: $error"))
                        : startups.isEmpty
                            ? const Center(child: Text("Nenhuma startup encontrada"))
                            : ListView.builder(
                                itemCount: startups.length,
                                itemBuilder: (context, index) {
                                  final data = startups[index] as Map<String, dynamic>;

                                  return StartupCard(
                                    nome: data['nome'] ?? '',
                                    setor: data['setor'] ?? '',
                                    estagio: data['estagio'] ?? '',
                                    precoToken: (data['precoToken'] as num?)?.toDouble() ?? 0.0,
                                    totalTokens: (data['totalTokens'] as num?)?.toInt() ?? 0,
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

  const StartupCard({
    super.key,
    required this.nome,
    required this.setor,
    required this.estagio,
    required this.precoToken,
    required this.totalTokens,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black12),
      ),
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
              Text("Preço do token"),
              Text("R\$ ${precoToken.toStringAsFixed(2)}"),
            ],
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Total de tokens"),
              Text(totalTokens.toString()),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            estagio.replaceAll("_", " "),
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            "Ver mais >",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}