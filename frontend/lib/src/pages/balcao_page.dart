// Caio Ferreira polo - 25002823
//Pagina do balcão de negociação

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import './auth/catalog_page.dart';

class BalcaoNegociacaoPage extends StatefulWidget {
  const BalcaoNegociacaoPage({super.key});

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
    final selectedIconColor = const Color(0xFF013593).withOpacity(0.85);
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color.fromARGB(255, 0, 0, 0), width: 0.8),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          elevation: 0,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          currentIndex: 0, // 0 = Mercado, 1 = Catálogo, 2 = Carteira
          selectedItemColor: Colors.black,
          unselectedItemColor: Colors.black,
          onTap: (index) {
            if (index == 0) return;

            if (index == 1) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const InitialCatalogPage(),
                ),
              );
              return;
            }
          },
          selectedLabelStyle: _textStyle,
          unselectedLabelStyle: _textStyle,
          items: [
            BottomNavigationBarItem(
              activeIcon: Image.asset(
                "assets/BotaoBalcao.png",
                width: 50,
                height: 50,
                color: selectedIconColor,
                colorBlendMode: BlendMode.srcIn,
              ),
              icon: Image.asset("assets/BotaoBalcao.png", width: 40 ,height: 40),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Image.asset("assets/BotaoCatalogo.png", width: 50 ,height: 50),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Image.asset("assets/BotãoCarteira.png", width: 50 ,height: 50),
              label: "",
            ),
          ],
        ),
      ),


      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),    
          child: Column(
            children: [
              const SizedBox(height: 20),

              Center(
                child: FractionallySizedBox(
               
                widthFactor: 0.8,
                
                child: TextField(
                  style: _textStyle,
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    hintText: "Buscar startup",
                    hintStyle: TextStyle(color: Color.fromARGB(70, 0, 0, 0), fontSize: 20, fontFamily: "Josefins-sans"), //arruamar
                    prefixIcon: const Icon(Icons.search, color: Color.fromARGB(70, 0, 0, 0),),
                    filled: true,
                    fillColor: Colors.grey[200],
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: Color.fromARGB(65, 189,186,186),
                        width: 3
                      )
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: Color.fromARGB(98, 45, 158, 173), width: 3),
                    ),
                  ),

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


  
 