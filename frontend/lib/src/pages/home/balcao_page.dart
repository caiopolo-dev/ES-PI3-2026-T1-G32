// Autor: Caio Ferreira Polo
// Descrição: Tela do balcão de negociação — listagem e compra de ofertas de tokens

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'home_page.dart';
import 'catalog_page.dart';
import 'profile_page.dart';
import '../initial_page.dart';
import 'buy_steps_page.dart';
import 'wallet_page.dart';

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
    // Guard inicial: widget pode ser desmontado antes do primeiro frame (ex: navegação rápida).
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errorMessage = null;
    });


    try{
      // listOffers já filtra as próprias ofertas do usuário no backend (excludeSellerId).
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
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'perfil') {
                  Navigator.pushReplacement(context, MaterialPageRoute(
                    builder: (_) => ProfilePage(usuario: widget.usuario),
                  ));
                } else if (value == 'sair') {
                  _logout();
                }
              },
              color: AppColors.branco,
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppColors.cinza200),
              ),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'perfil',
                  child: Row(children: [
                    Icon(Icons.person_outline, size: 20, color: AppColors.preto87),
                    SizedBox(width: 12),
                    Text('Meu Perfil'),
                  ]),
                ),
                PopupMenuItem<String>(
                  enabled: false,
                  height: 8,
                  padding: EdgeInsets.zero,
                  child: Divider(indent: 16, endIndent: 16, thickness: 1, height: 1, color: AppColors.cinza200),
                ),
                const PopupMenuItem(
                  value: 'sair',
                  child: Row(children: [
                    Icon(Icons.logout, size: 20, color: AppColors.vermelho),
                    SizedBox(width: 12),
                    Text('Sair', style: TextStyle(color: AppColors.vermelho)),
                  ]),
                ),
              ],
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.azul,
                child: Text(
                  inicial,
                  style: const TextStyle(
                    inherit: false,
                    color: AppColors.branco,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.branco,
          border: Border(top: BorderSide(color: AppColors.cinza300)),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.branco,
          elevation: 0,
          currentIndex: 1,
          selectedItemColor: AppColors.azul,
          unselectedItemColor: AppColors.cinza500,
          onTap: (index) {
            if (index == 0) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => HomePage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 1) return;
            if (index == 2) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => InitialCatalogPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 3) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => WalletPage(usuario: widget.usuario)),
              );
              return;
            }
            if (index == 4) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ProfilePage(usuario: widget.usuario)),
              );
              return;
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "Início"),
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

              // Barra de busca
              TextField(
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
                color: AppColors.preto54,
              ),
              
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.azul))
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
                                  // Valor chega em centavos do backend; converte para reais na exibição.
                                  final valorFormatado = 'R\$ ${(valorCentavos / 100).toStringAsFixed(2).replaceAll('.', ',')}';
                                  final offerId = data['offerId'] ?? '';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.branco,
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(color: AppColors.cinza300),
                                    ),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(15),
                                      onTap: () {
                                        Navigator.push(context,
                                          MaterialPageRoute(builder: (_) => BuyStepsPage(
                                            startupName: startupId.toString(),
                                            availableQuantity: int.tryParse(amount.toString()) ?? 0,
                                            pricePerTokenCents: int.tryParse(valorCentavos.toString()) ?? 0,
                                            offerId: offerId.toString(),
                                          )),
                                        );
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                        child: Row(
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
                                      ),
                                    ),
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