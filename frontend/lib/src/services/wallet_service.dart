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
      // O backend armazena valores monetários em centavos; dividir por 100 para exibir em reais.
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

  // Busca o histórico de transações do usuário (compras de tokens).
  // Cada item da lista é um Map com os campos da coleção token_transactions.
  static Future<Map<String, dynamic>> getTransactionHistory() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getTransactionHistory')
          .call();
      // Converte cada elemento da lista dinâmica para Map<String, dynamic> tipado.
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

  static Future<Map<String, dynamic>> addBalance(int amountCents) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('addBalance')
          .call({'amountCents': amountCents});
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      return {'success': false, 'message': e.message ?? 'Erro ao adicionar saldo'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Busca o portfólio de tokens do usuário com preço médio ponderado e valor atual.
  // O backend agrega direto de token_transactions para cobrir compras antigas
  // feitas antes da coleção userTokens existir (retrocompatibilidade).
  static Future<Map<String, dynamic>> getUserTokens() async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserTokens')
          .call();
      // precoMedio e valorAtual chegam em centavos do backend.
      // Convertemos para reais aqui para que a WalletPage exiba os valores formatados.
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