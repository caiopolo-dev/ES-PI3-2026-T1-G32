import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  static Map<String, dynamic> validarDados({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) {
    final rgLimpo = rg.trim();
    final emailLimpo = email.trim();
    final nomeLimpo = nome.trim();
    final telefoneLimpo = telefone.trim();

    if (rgLimpo.isEmpty) {
      return {'valido': false, 'erro': 'RG não pode estar vazio'};
    }

    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return {'valido': false, 'erro': 'Email inválido'};
    }

    if (nomeLimpo.split(' ').length < 2) {
      return {'valido': false, 'erro': 'Digite seu nome completo'};
    }

    if (telefoneLimpo.length < 10) {
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
      final emailLimpo = email.trim();
      final nomeLimpo = nome.trim();
      final rgLimpo = rg.trim();
      final telefoneLimpo = telefone.trim();

      userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailLimpo,
        password: senha,
      );

      await userCredential.user?.sendEmailVerification();

      final callable = FirebaseFunctions.instance.httpsCallable('createUser');

      final result = await callable.call({
        'name': nomeLimpo,
        'rg': rgLimpo,
        'telefone': telefoneLimpo,
        'email': emailLimpo,
      });

      return {
        'success': true,
        'authUid': userCredential.user?.uid,
        'userId': result.data,
        'message': 'Cadastro realizado com sucesso!',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao criar usuário';

      if (e.code == 'email-already-in-use') {
        message = 'Este e-mail já está cadastrado';
      } else if (e.code == 'invalid-email') {
        message = 'E-mail inválido';
      } else if (e.code == 'weak-password') {
        message = 'Senha muito fraca';
      } else if (e.message != null) {
        message = e.message!;
      }

      return {
        'success': false,
        'error': e.code,
        'message': message,
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

  static Future<Map<String, dynamic>> sendPasswordReset({
    required String email,
  }) async {
    final emailLimpo = email.trim();

    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return {'success': false, 'message': 'Digite um e-mail válido'};
    }

    try {
      await FirebaseFunctions.instance
          .httpsCallable('checkUserExists')
          .call({'email': emailLimpo});

      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailLimpo);
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      String message = 'Erro ao enviar e-mail de recuperação';
      if (e.code == 'not-found') {
        message = 'Nenhuma conta encontrada com este e-mail';
      }
      return {'success': false, 'message': message};
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao enviar e-mail de recuperação';
      if (e.code == 'invalid-email') message = 'E-mail inválido';
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erro inesperado: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();

    if (emailLimpo.isEmpty || senha.isEmpty) {
      return {
        'success': false,
        'error': 'Dados incompletos',
        'message': 'E-mail e senha são obrigatórios',
      };
    }

    if (!emailLimpo.contains('@')) {
      return {
        'success': false,
        'error': 'Email inválido',
        'message': 'Digite um e-mail válido',
      };
    }

    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailLimpo,
        password: senha,
      );

      final user = userCredential.user;

      if (user == null) {
        return {
          'success': false,
          'error': 'Usuário inválido',
          'message': 'Não foi possível carregar o usuário autenticado',
        };
      }

      if (!user.emailVerified) {
        await FirebaseAuth.instance.signOut();
        return {
          'success': false,
          'error': 'email-not-verified',
          'message':
              'Confirme seu e-mail antes de fazer login. '
              'Verifique sua caixa de entrada.',
        };
      }

      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserData')
          .call();

      final userData =
          Map<String, dynamic>.from(result.data as Map? ?? {});

      return {
        'success': true,
        'usuario': {
          'uid': user.uid,
          'email': user.email,
          ...userData,
        },
        'message': 'Login realizado com sucesso!',
      };
    } on FirebaseAuthMultiFactorException {
      rethrow;
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao fazer login';

      if (e.code == 'invalid-email') {
        message = 'E-mail inválido';
      } else if (e.code == 'user-disabled') {
        message = 'Este usuário foi desativado';
      } else if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        message = 'E-mail ou senha incorretos';
      } else if (e.message != null) {
        message = e.message!;
      }

      return {
        'success': false,
        'error': e.code,
        'message': message,
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao buscar dados do usuário',
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }

  static Future<Map<String, dynamic>> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Usuário não autenticado'};
      }

      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserData')
          .call();

      final userData =
          Map<String, dynamic>.from(result.data as Map? ?? {});

      return {
        'success': true,
        'usuario': {
          'uid': user.uid,
          'email': user.email,
          ...userData,
        },
      };
    } on FirebaseFunctionsException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'Erro ao buscar dados do usuário',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }
}