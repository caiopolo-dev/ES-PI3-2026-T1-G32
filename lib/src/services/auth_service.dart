import 'package:http/http.dart' as http;
import 'dart:convert';

class AuthService {
  static const String baseUrl = "https://us-central1-es-pi3-2026-t1-g32.cloudfunctions.net";

  static Map<String, dynamic> validarDados({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) {
    if (rg.isEmpty) {
      return {'valido': false, 'erro': 'RG não pode estar vazio'};
    }

    if (email.isEmpty || !email.contains('@')) {
      return {'valido': false, 'erro': 'Email inválido'};
    }

    if (nome.trim().split(' ').length < 2) {
      return {'valido': false, 'erro': 'Digite seu nome completo'};
    }

    if (telefone.length < 10) {
      return {'valido': false, 'erro': 'Número inválido'};
    }

    if (senha.length < 8) {
      return {'valido': false, 'erro': 'Senha deve ter no mínimo 8 caracteres'};
    }

    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');
    if (!regex.hasMatch(senha)) {
      return {'valido': false, 'erro': 'Senha deve ter maiúscula, minúscula e número'};
    }

    return {'valido': true};
  }

  static Future<Map<String, dynamic>> registerUser({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) async {
    final validacao = validarDados(
      rg: rg,
      email: email,
      nome: nome,
      telefone: telefone,
      senha: senha,
    );

    if (!validacao['valido']) {
      return {
        'success': false,
        'error': 'Validação',
        'message': validacao['erro'],
      };
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/registerUser'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'RG': rg,
          'email': email,
          'nome': nome,
          'numero': telefone,
          'senha': senha,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'userId': responseData['userId'],
          'message': responseData['message'],
        };
      } else if (response.statusCode == 409) {
        return {
          'success': false,
          'error': responseData['error'],
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'error': 'Erro ao conectar com servidor',
          'message': 'Status: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro de conexão',
        'message': e.toString(),
      };
    }
  }
}
