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

      // jsonDecode(jsonEncode(...)) converte o objeto dinâmico do SDK para tipos
      // Dart nativos, permitindo o cast seguro para List<Map<String, dynamic>>.
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

  // Envia uma nova pergunta para a FAQ de uma startup.
  // `privada: true` significa que apenas o autor pode ver a pergunta — útil para
  // dúvidas sensíveis que o usuário não quer expor publicamente.
  static Future<Map<String, dynamic>> createFaq({
    required String startupId,
    required String pergunta,
    required bool privada,
  }) async {
    try {
      // Atenção à segurança: o backend deve obter o autor (email/nome) a partir
      // do token de autenticação e não dos dados enviados no payload. Aqui
      // apenas chamamos a callable function passando os parâmetros sem dados
      // sensíveis do usuário.
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
