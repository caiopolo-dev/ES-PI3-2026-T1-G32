// Caio Ferreira polo - 25002823
//Pagina do balcão de negociação

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mescla_invest/src/pages/catalog_page.dart';
import 'package:mescla_invest/src/pages/profile_page.dart';
import 'package:mescla_invest/src/pages/initial_page.dart';

class BalcaoNegociacaoPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;

  const BalcaoNegociacaoPage({super.key, this.usuario});

  @override
  State<BalcaoNegociacaoPage> createState() => _BalcaoNegociacaoPageState();
}
class _BalcaoNegociacaoPageState extends State<BalcaoNegociacaoPage>{

  static const TextStyle _textStyle = TextStyle(fontFamily: "Josefins-sans", fontSize: 17);

  List<dynamic> offers = [];
  bool isLoading = true;
  String? errorMessage;
  @override
  void initState(){
    super.initState();
    loadOffers();
  }
  

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const InitialPage()),
      (_) => false,
    );
  }

  Future<void> loadOffers() async{
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });


    try{
      final callable  = FirebaseFunctions.instance.httpsCallable('listOffers');
      final result = await callable.call();
      final data = result.data['data'];

      setState(() {
        offers = List<dynamic>.from(data);
        isLoading = false;
      });

    }catch(e){
      if (!mounted) return;
      setState(() {
        errorMessage = "Erro ao carregar ofertas";
        isLoading = false;
      });
    }
    

  }

    

  @override
  Widget build(BuildContext context) {
    final usuario = widget.usuario ?? {};
    final nome = (usuario['nome'] ?? usuario['name']) as String? ?? '';
    final inicial = nome.isNotEmpty ? nome[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          currentIndex: 0,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            if (index == 0) return;
            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => InitialCatalogPage(usuario: widget.usuario),
                ),
              );
              return;
            }
            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilePage(usuario: widget.usuario),
                ),
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Em breve')),
            );
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.store), label: "Mercado"),
            BottomNavigationBarItem(icon: Icon(Icons.list), label: "Catálogo"),
            BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Carteira"),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "Perfil"),
          ],
        ),
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),    
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Linha 1: flecha (esquerda) e avatar do perfil (direita)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InitialCatalogPage(usuario: widget.usuario),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'perfil') {
                          Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ProfilePage(usuario: widget.usuario),
                          ));
                        } else if (value == 'sair') {
                          _logout();
                        }
                      },
                      color: Colors.white,
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'perfil',
                          child: Row(children: [
                            Icon(Icons.person_outline, size: 20, color: Colors.black87),
                            SizedBox(width: 12),
                            Text('Meu Perfil'),
                          ]),
                        ),
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 8,
                          padding: EdgeInsets.zero,
                          child: Divider(indent: 16, endIndent: 16, thickness: 1, height: 1, color: Colors.grey.shade200),
                        ),
                        const PopupMenuItem(
                          value: 'sair',
                          child: Row(children: [
                            Icon(Icons.logout, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Sair', style: TextStyle(color: Colors.red)),
                          ]),
                        ),
                      ],
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.blue,
                        child: Text(inicial, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Linha 2: barra de busca largura total
              TextField(
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
              const SizedBox(height: 35),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text("Nome", style: _textStyle),
                  ),
                  Expanded(
                    flex: 1,
                    child: Center(child: Text("Qtd", style: _textStyle)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text("valor - un", style: _textStyle),
                    ),
                  ),
                ],
              ),
              Divider(
                height: 18,
                thickness: 1,
                color: Colors.black54,
              ),
              
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.blue))
                    : errorMessage != null
                    ? Center(child: Text("Erro: $errorMessage", style: _textStyle))
                        : offers.isEmpty
                      ? const Center(child: Text("Nenhuma oferta de venda encontrada", style: _textStyle))
                            : ListView.builder(
                                itemCount: offers.length,
                                itemBuilder: (context, index){
                                  final data = offers[index];
                                  final startupId = data['startupId'] ?? '';
                                  final amount = data['amount'] ?? 0;
                                  final valorCentavos = data['valorUnitarioCentavos'] ?? 0;
                                  final valorFormatado = 'R\$ ${(valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';

                                  return Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(startupId, style: _textStyle),
                                          ),
                                          Expanded(
                                            flex: 1,
                                            child: Center(child: Text(amount.toString(), style: _textStyle)),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: Text(valorFormatado, style: _textStyle),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        height: 18,
                                        thickness: 1,
                                        color: Colors.black38,
                                      ),
                                    ],
                                  );
                                },
                            )
                
                
                ),
              
            ]
          ),
        ),
      ),
    );
  }
}