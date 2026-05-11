// Autor: Henrique Leite de Camargo 25005997
// Data: 08/05/2026
// Descrição: Serviço de carteira do usuário

import 'package:cloud_functions/cloud_functions.dart';

class WalletService {
  static Future<Map<String, dynamic>> getWalletData() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getWalletInfo')
          .call();
      return {
        'success': true,
        'saldo': ((result.data['saldo'] ?? 0) as num).toDouble() / 100,
        'totalInvestido': ((result.data['totalInvestido'] ?? 0) as num).toDouble() / 100,
        'totalTokens': ((result.data['totalTokens'] ?? 0) as num).toInt(),
      };
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'message': e.message ?? 'Erro ao buscar carteira'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getTransactionHistory() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getTransactionHistory')
          .call();
      final list = (result.data['transactions'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      return {'success': true, 'transactions': list};
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'message': e.message ?? 'Erro ao buscar histórico'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getUserTokens() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserTokens')
          .call();
      final list = (result.data['tokens'] as List? ?? [])
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            m['precoMedio'] = ((m['precoMedio'] as num?) ?? 0) / 100.0;
            m['valorAtual'] = ((m['valorAtual'] as num?) ?? 0) / 100.0;
            return m;
          })
          .toList();
      return {'success': true, 'tokens': list};
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'message': e.message ?? 'Erro ao buscar tokens'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}