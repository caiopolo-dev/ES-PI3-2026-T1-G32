// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/04/2026
// Descrição: Service responsável por buscar os dados das startups via callable functions

import 'package:cloud_functions/cloud_functions.dart';

class StartupService {

  // Busca todas as startups, com filtro opcional por estágio
  // Exemplo: getStartups(estagio: 'nova')
  static Future<Map<String, dynamic>> getStartups({String? estagio}) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('getStartups');

      final result = await callable.call(
        estagio != null ? {'estagio': estagio} : {},
      );

      return {
        'success': true,
        'data': List<Map<String, dynamic>>.from(
          (result.data['data'] as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        ),
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
      'data': Map<String, dynamic>.from(result.data['data'] as Map),
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