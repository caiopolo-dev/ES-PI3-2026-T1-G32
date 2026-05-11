// Caio Ferreira Polo = 25002823

import 'package:cloud_functions/cloud_functions.dart';

class TokenDataService {
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


  static Future<Map<String, dynamic>> buyOffer({
    required String offerId,
    required int quantity,
}) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('buyOffer');

    final result = await callable.call({
      'offerId': offerId,
      'quantity': quantity,
    });

    return {
      'success': true,
      'data': result.data['data'],
    };
  } on FirebaseFunctionsException catch (e) {
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




