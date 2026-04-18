// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela do catalogo das startups

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InitialCatalogPage extends StatefulWidget {
  const InitialCatalogPage({super.key});

  @override
  State<InitialCatalogPage> createState() => _InitialCatalogPageState();
}

class _InitialCatalogPageState extends State<InitialCatalogPage> {
  int selectedFilter = 0;

  final List<String> filters = ["Todas", "Novas", "Em operação"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // Bottom Navigation
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(filters.length, (index) {
                  bool isSelected = selectedFilter == index;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => selectedFilter = index);
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

              const SizedBox(height: 20),

              // Lista dinâmica com Firebase
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('startups').snapshots(),
                  builder: (context, snapshot) {

                    if (snapshot.hasError) {
                      return Center(
                        child: Text("Erro: ${snapshot.error}"),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text("Nenhuma startup encontrada"));
                    }

                    final startups = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: startups.length,
                      itemBuilder: (context, index) {
                        final data = startups[index].data() as Map<String, dynamic>;

                        print('Documento: $data');
                        print('price tipo: ${data['price'].runtimeType}');
                        print('variation tipo: ${data['variation'].runtimeType}');

                        final name = data['name'] ?? '';
                        final price = (data['price'] as num?)?.toDouble() ?? 0.0;
                        final variation = (data['variation'] as num?)?.toDouble() ?? 0.0;

                        return StartupCard(
                          name: name,
                          price: "R\$ ${price.toStringAsFixed(2)}",
                          variation: "${variation >= 0 ? '+' : ''}${variation.toStringAsFixed(2)}%",
                          isPositive: variation >= 0,
                        );
                      },
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
  final String name;
  final String price;
  final String variation;
  final bool isPositive;

  const StartupCard({
    super.key,
    required this.name,
    required this.price,
    required this.variation,
    required this.isPositive,
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
          // Nome
          Text(
            name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          // Preço
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Preço agora"),
              Text(price),
            ],
          ),

          const SizedBox(height: 5),

          // Variação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Variação"),
              Text(
                variation,
                style: TextStyle(
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          const Text(
            "Ver mais >",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}