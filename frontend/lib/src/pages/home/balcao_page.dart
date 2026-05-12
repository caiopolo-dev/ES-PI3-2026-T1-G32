// Autor: Caio Ferreira Polo
// Descrição: Tela do balcão de negociação — listagem e compra de ofertas de tokens

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/widgets/user_avatar_menu.dart';
import 'package:mescla_invest/src/widgets/app_loading_indicator.dart';
import 'buy_steps_page.dart';

class BalcaoNegociacaoPage extends StatefulWidget {
  final Map<String, dynamic>? usuario;
  final void Function(int)? onTabSwitch;
  final bool isActive;

  const BalcaoNegociacaoPage({super.key, this.usuario, this.onTabSwitch, this.isActive = false});

  @override
  State<BalcaoNegociacaoPage> createState() => _BalcaoNegociacaoPageState();
}
class _BalcaoNegociacaoPageState extends State<BalcaoNegociacaoPage>{

  static const TextStyle _textStyle = TextStyle(fontFamily: "Josefins-sans", fontSize: 17);

  List<dynamic> offers = [];
  bool isLoading = true;
  String? errorMessage;
  @override
  void didUpdateWidget(BalcaoNegociacaoPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recarrega as ofertas ao retornar para esta aba,
    // garantindo que ofertas já compradas não apareçam mais.
    if (widget.isActive && !oldWidget.isActive) loadOffers();
  }

  @override
  void initState(){
    super.initState();
    loadOffers();
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
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
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
                    ? const AppLoadingIndicator()
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
                                      onTap: () async {
                                        // Aguarda o resultado: BuyStepsPage retorna true
                                        // se a compra foi concluída, null/false se cancelada.
                                        final comprou = await Navigator.push<bool>(context,
                                          MaterialPageRoute(builder: (_) => BuyStepsPage(
                                            startupName: startupId.toString(),
                                            availableQuantity: int.tryParse(amount.toString()) ?? 0,
                                            pricePerTokenCents: int.tryParse(valorCentavos.toString()) ?? 0,
                                            offerId: offerId.toString(),
                                          )),
                                        );
                                        // Recarrega as ofertas para refletir a oferta recém-comprada
                                        // (pode ter sido parcialmente consumida ou removida).
                                        if (comprou == true) loadOffers();
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