
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  // Validação puramente local — sem chamadas de rede — para dar feedback
  // imediato ao usuário antes de qualquer requisição ao Firebase.
  static Map<String, dynamic> validarDados({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) {
    // Remove espaços em branco das extremidades antes de validar.
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

    // Nome completo exige pelo menos duas palavras (nome + sobrenome).
    if (nomeLimpo.split(' ').length < 2) {
      return {'valido': false, 'erro': 'Digite seu nome completo'};
    }

    // 10 dígitos = DDD (2) + número (8 ou 9).
    if (telefoneLimpo.length < 10) {
      return {'valido': false, 'erro': 'Número inválido'};
    }

    if (senha.length < 8) {
      return {'valido': false, 'erro': 'Senha deve ter no mínimo 8 caracteres'};
    }

    // Regex exige: pelo menos uma minúscula, uma maiúscula e um dígito.
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

    if (!regex.hasMatch(senha)) {
      return {
        'valido': false,
        'erro': 'Senha deve ter maiúscula, minúscula e número',
      };
    }

    return {'valido': true};
  }

  // Fluxo de cadastro:
  // 1. Valida dados localmente
  // 2. Cria conta no Firebase Auth
  // 3. Envia e-mail de verificação
  // 4. Chama Cloud Function para salvar no Firestore
  // 5. Em caso de falha após o passo 2, desfaz a criação da conta no Auth (rollback)
  static Future<Map<String, dynamic>> registerUser({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) async {
    // Valida antes de qualquer chamada de rede.
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

    // Declarado como nullable para o rollback: se falhar após a criação
    // no Auth mas antes de salvar no Firestore, podemos excluir a conta.
    UserCredential? userCredential;

    try {
      final emailLimpo = email.trim();
      final nomeLimpo = nome.trim();
      final rgLimpo = rg.trim();
      final telefoneLimpo = telefone.trim();

      // Cria a conta no Firebase Auth primeiro; se a Cloud Function falhar,
      // o bloco catch abaixo exclui a conta para evitar usuário órfão no Auth.
      userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailLimpo,
        password: senha,
      );

      // Envia e-mail de verificação — o login só será permitido após a confirmação.
      await userCredential.user?.sendEmailVerification();

      // Chama a Cloud Function para salvar os dados adicionais no Firestore.
      // O uid do usuário autenticado é inferido pelo backend via request.auth.uid.
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
        'userId': result.data, // Cloud Function retorna o uid do documento criado
        'message': 'Cadastro realizado com sucesso!',
      };
    } on FirebaseAuthException catch (e) {
      // Erros do Firebase Auth (email duplicado, senha fraca etc.).
      // Nenhum rollback necessário: a conta não foi criada ou o Auth já a gerencia.
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
      // A conta foi criada no Auth mas a Cloud Function falhou (ex: RG duplicado no Firestore).
      // Rollback: exclui a conta do Auth para manter consistência.
      await userCredential?.user?.delete();

      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao salvar dados do usuário',
      };
    } catch (e) {
      // Qualquer outro erro inesperado — também faz rollback para segurança.
      await userCredential?.user?.delete();

      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }

  // Fluxo de recuperação de senha em duas etapas:
  // 1. Verifica via Cloud Function se o e-mail está cadastrado no Firestore
  // 2. Se existir, pede ao Firebase para enviar o link de redefinição
  // Fazer isso em dois passos permite mostrar mensagem amigável se o e-mail não existir.
  static Future<Map<String, dynamic>> sendPasswordReset({
    required String email,
  }) async {
    final emailLimpo = email.trim();

    // Validação local antes de chamar qualquer serviço.
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return {'success': false, 'message': 'Digite um e-mail válido'};
    }

    try {
      // checkUserExists lança 'not-found' se o e-mail não estiver cadastrado,
      // interrompendo o fluxo antes de chamar o Firebase Auth.
      await FirebaseFunctions.instance
          .httpsCallable('checkUserExists')
          .call({'email': emailLimpo});

      // E-mail existe — solicita ao Firebase o envio do link de redefinição.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailLimpo);
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      // Captura 'not-found' retornado pelo checkUserExists.
      String message = 'Erro ao enviar e-mail de recuperação';
      if (e.code == 'not-found') {
        message = 'Nenhuma conta encontrada com este e-mail';
      }
      return {'success': false, 'message': message};
    } on FirebaseAuthException catch (e) {
      // Erros do próprio Firebase Auth ao tentar enviar o e-mail.
      String message = 'Erro ao enviar e-mail de recuperação';
      if (e.code == 'invalid-email') message = 'E-mail inválido';
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erro inesperado: ${e.toString()}'};
    }
  }

  // Fluxo de login:
  // 1. Valida campos localmente
  // 2. Tenta autenticar no Firebase Auth
  // 3. Se o usuário tem 2FA, lança FirebaseAuthMultiFactorException (repassada para a tela)
  // 4. Verifica se o e-mail foi confirmado; se não, faz logout e retorna erro
  // 5. Busca dados adicionais do Firestore via Cloud Function
  // 6. Retorna o mapa 'usuario' com dados do Auth + Firestore combinados
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();

    // Validações locais para evitar chamada de rede com dados claramente inválidos.
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
      // Autentica no Firebase Auth. Se o usuário tiver 2FA ativo, esta chamada
      // lança FirebaseAuthMultiFactorException antes de completar o login.
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailLimpo,
        password: senha,
      );

      final user = userCredential.user;

      // Caso de segurança: o SDK do Firebase nunca deve retornar null aqui,
      // mas verificamos para evitar null safety issues.
      if (user == null) {
        return {
          'success': false,
          'error': 'Usuário inválido',
          'message': 'Não foi possível carregar o usuário autenticado',
        };
      }

      // Bloqueia login de contas que ainda não verificaram o e-mail.
      // Faz signOut para limpar a sessão que o Firebase criaria mesmo sem verificação.
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

      // Busca dados adicionais do usuário no Firestore (nome, RG, telefone etc.)
      // que não estão disponíveis no token de autenticação.
      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserData')
          .call();

      // Converte o resultado dinâmico do SDK para um Map<String, dynamic> tipado.
      final userData =
          Map<String, dynamic>.from(result.data as Map? ?? {});

      // Combina dados do Auth (uid, email) com dados do Firestore (nome, telefone etc.).
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
      // Repropaga para a página de login interceptar e redirecionar para o fluxo 2FA.
      // Não deve ser capturada aqui pois contém o resolver necessário para completar o login.
      rethrow;
    } on FirebaseAuthException catch (e) {
      // Erros conhecidos do Firebase Auth com mensagens amigáveis.
      String message = 'Erro ao fazer login';

      if (e.code == 'invalid-email') {
        message = 'E-mail inválido';
      } else if (e.code == 'user-disabled') {
        message = 'Este usuário foi desativado';
      } else if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // 'invalid-credential' é o código retornado em versões mais recentes do SDK.
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
      // Erro ao buscar dados do Firestore após autenticação bem-sucedida.
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