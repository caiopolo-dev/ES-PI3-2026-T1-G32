// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/04/2026
// Descrição: Service responsável por buscar os dados das startups via callable functions

import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

class StartupService {

  // Busca todas as startups, com filtro opcional por estágio
  // Exemplo: getStartups(estagio: 'nova')
  static Future<Map<String, dynamic>> getStartups({
    String? estagio,
    bool includeDailyVariation = false,
  }) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('getStartups');

      final params = <String, dynamic>{};
      if (estagio != null) params['estagio'] = estagio;
      if (includeDailyVariation) params['includeDailyVariation'] = true;

      final result = await callable.call(params);

      // jsonDecode(jsonEncode(...)) converte o objeto dinâmico retornado pelo SDK
      // em tipos Dart nativos (Map/List), necessário para o cast funcionar corretamente.
      return {
        'success': true,
        'data': (jsonDecode(jsonEncode(result.data['data'])) as List)
            .cast<Map<String, dynamic>>(),
      };

    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao buscar startups',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }

  // Busca uma startup específica pelo ID
  static Future<Map<String, dynamic>> getStartupById(String id) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('getStartupById');

      final result = await callable.call({'id': id});

      return {
        'success': true,
        'data': jsonDecode(jsonEncode(result.data['data'])) as Map<String, dynamic>,
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao buscar startup',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }
}