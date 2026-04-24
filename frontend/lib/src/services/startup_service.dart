// Autor: Gustavo Alves de Siqueira Costa
// Data: 24/04/2026
// Descrição: Service responsável por buscar os dados das startups via API

import 'package:http/http.dart' as http;
import 'dart:convert';

class StartupService {
  static const String baseUrl =
      "https://us-central1-es-pi3-2026-t1-g32.cloudfunctions.net";

  // Busca todas as startups, com filtro opcional por estágio
  static Future<Map<String, dynamic>> getStartups({String? estagio}) async {
    try {
      final url = estagio != null
          ? Uri.parse('$baseUrl/getStartups?estagio=$estagio')
          : Uri.parse('$baseUrl/getStartups');

      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar startups',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Busca uma startup específica pelo ID
  static Future<Map<String, dynamic>> getStartupById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/getStartupById/$id'),
        headers: {'Content-Type': 'application/json'},
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': responseData['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Startup não encontrada',
        };
      } else {
        return {
          'success': false,
          'message': 'Erro ao buscar startup',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}