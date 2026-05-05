// Autor: Gustavo Alves de Siqueira Costa
// Data: 05/05/2026
// Descrição: Service responsável pelas FAQs das startups via callable functions

import 'package:cloud_functions/cloud_functions.dart';
import 'dart:convert';

class FaqService {
  static Future<Map<String, dynamic>> getFaqs(String startupId) async {
    try {
      final result = await FirebaseFunctions.instance
          .httpsCallable('getFaqs')
          .call({'startupId': startupId});

      return {
        'success': true,
        'data': (jsonDecode(jsonEncode(result.data['data'])) as List)
            .cast<Map<String, dynamic>>(),
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao buscar perguntas',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> createFaq({
    required String startupId,
    required String pergunta,
    required bool privada,
  }) async {
    try {
      await FirebaseFunctions.instance
          .httpsCallable('createFaq')
          .call({'startupId': startupId, 'pergunta': pergunta, 'privada': privada});

      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao enviar pergunta',
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
