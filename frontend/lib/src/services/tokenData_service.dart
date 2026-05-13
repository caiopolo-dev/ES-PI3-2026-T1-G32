// Autor: Caio Ferreira Polo
// Descrição: Serviço de dados de tokens — saldo da carteira e compra de ofertas

import 'package:cloud_functions/cloud_functions.dart';

class TokenDataService {
  // Retorna o saldo em centavos (sem dividir por 100) para que o buy_steps_page
  // possa comparar diretamente com totalCents, que também está em centavos.
  static Future<int> getWalletBalance() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getWalletInfo')
          .call();
      return (result.data['saldo'] as num).toInt();
    } catch (_) {
      return 0;
    }
  }


  // Executa a compra de tokens de uma oferta no balcão.
  // O backend executa a transação de forma atômica: debita o saldo do comprador,
  // credita o vendedor e registra em token_transactions — tudo ou nada.
  static Future<Map<String, dynamic>> buyOffer({
    required String offerId,
    required int quantity,
}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('buyOffer');

    // buyerId é inferido pelo backend via request.auth.uid — não enviamos no payload.
    final result = await callable.call({
      'offerId': offerId,
      'quantity': quantity,
    });

    return {
      'success': true,
      'data': result.data['data'],
    };
  } on FirebaseFunctionsException catch (e) {
    // Erros comuns: saldo insuficiente, quantidade maior que disponível, oferta inativa.
    return {
      'success': false,
      'message': e.message ?? 'Erro ao confirmar compra',
      'error': e.code,
    };
  } catch (e) {
    return {
      'success': false,
      'message': e.toString(),
      'error': 'unexpected',
    };
  }
}
}




