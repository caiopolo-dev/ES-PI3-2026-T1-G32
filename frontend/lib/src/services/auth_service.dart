import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
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
      return {
        'valido': false,
        'erro': 'Senha deve ter maiúscula, minúscula e número',
      };
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

    UserCredential? userCredential;

    try {
      userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: senha,
      );

      final callable = FirebaseFunctions.instance.httpsCallable('createUser');

      final result = await callable.call({
        'name': nome.trim(),
        'rg': rg.trim(),
        'telefone': telefone.trim(),
        'email': email.trim(),
      });

      return {
        'success': true,
        'authUid': userCredential.user?.uid,
        'userId': result.data,
        'message': 'Cadastro realizado com sucesso!',
      };
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao criar usuário',
      };
    } on FirebaseFunctionsException catch (e) {
      await userCredential?.user?.delete();

      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao salvar dados do usuário',
      };
    } catch (e) {
      await userCredential?.user?.delete();

      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String rg,
    required String senha,
  }) async {
    if (rg.trim().isEmpty || senha.isEmpty) {
      return {
        'success': false,
        'error': 'Dados incompletos',
        'message': 'RG e senha são obrigatórios',
      };
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('rg', isEqualTo: rg.trim())
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'success': false,
          'error': 'Usuário não encontrado',
          'message': 'RG não cadastrado',
        };
      }

      final usuario = snapshot.docs.first.data();
      final email = usuario['email'];

      if (email == null || email.toString().isEmpty) {
        return {
          'success': false,
          'error': 'Email não encontrado',
          'message': 'Não foi possível localizar o e-mail deste usuário',
        };
      }

      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.toString(),
        password: senha,
      );

      return {
        'success': true,
        'usuario': {
          ...usuario,
          'uid': userCredential.user?.uid,
        },
        'message': 'Login realizado com sucesso!',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao fazer login';

      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'Senha incorreta';
      } else if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      }

      return {
        'success': false,
        'error': e.code,
        'message': message,
      };
    } on FirebaseException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao buscar usuário',
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