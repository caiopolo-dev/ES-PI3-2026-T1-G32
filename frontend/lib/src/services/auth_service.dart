
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AuthService {
  /// Serviço centralizado para operações de autenticação e gerenciamento
  /// de dados de usuário que envolvem Firebase Auth e Cloud Functions.
  ///
  /// Observações gerais:
  /// - As funções aqui são todas estáticas para permitir uso direto sem
  ///   necessidade de instanciar a classe (padrão para helpers/services).
  /// - Estas rotinas combinam validação local (feedback rápido) com
  ///   chamadas remotas ao Firebase (Auth + Cloud Functions).

  /// Validação puramente local — sem chamadas de rede — para dar feedback
  /// imediato ao usuário antes de qualquer requisição ao Firebase.
  ///
  /// Retorno:
  /// - Em caso de sucesso: {'valido': true}
  /// - Em caso de falha: {'valido': false, 'erro': '<mensagem amigável>'}
  static Map<String, dynamic> validarDados({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) {
    // Normaliza entradas: remove espaços extras nas extremidades.
    // Isto evita que usuários sejam bloqueados por espaços acidentais.
    final rgLimpo = rg.trim();
    final emailLimpo = email.trim();
    final nomeLimpo = nome.trim();
    final telefoneLimpo = telefone.trim();

    // Valida RG: campo obrigatório.
    if (rgLimpo.isEmpty) {
      return {'valido': false, 'erro': 'RG não pode estar vazio'};
    }

    // Valida email com uma checagem simples (presença de '@').
    // Observação: validação mais robusta pode usar regex ou pacotes de email.
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return {'valido': false, 'erro': 'Email inválido'};
    }

    // Nome deve conter pelo menos duas palavras (nome + sobrenome).
    // Isso melhora a qualidade dos dados exibidos em mensagens/contratos.
    if (nomeLimpo.split(' ').length < 2) {
      return {'valido': false, 'erro': 'Digite seu nome completo'};
    }

    // Telefone: checagem básica de comprimento — aceita 10+ dígitos.
    // Não formatamos o número aqui; isso deve ser feito na UI se necessário.
    if (telefoneLimpo.length < 10) {
      return {'valido': false, 'erro': 'Número inválido'};
    }

    // Senha mínima de segurança: ao menos 8 caracteres.
    if (senha.length < 8) {
      return {'valido': false, 'erro': 'Senha deve ter no mínimo 8 caracteres'};
    }

    // Regex exige: pelo menos uma minúscula, uma maiúscula e um dígito.
    // Isto torna a senha mais resistente a ataques de força bruta simples.
    final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

    if (!regex.hasMatch(senha)) {
      return {
        'valido': false,
        'erro': 'Senha deve ter maiúscula, minúscula e número',
      };
    }

    // Todas as verificações passaram.
    return {'valido': true};
  }

  /// Registra um novo usuário seguindo o fluxo seguro:
  /// 1) Validação local
  /// 2) Criação da conta no Firebase Auth
  /// 3) Envio de e-mail de verificação
  /// 4) Chamada de Cloud Function para persistir dados no Firestore
  ///
  /// Em caso de falha depois que a conta do Auth for criada, é feito
  /// rollback (exclusão da conta) para evitar usuários órfãos no Auth.
  ///
  /// Retorno: Map com chaves como 'success', 'message', e possivelmente
  /// 'authUid' e 'userId' quando bem sucedido.
  static Future<Map<String, dynamic>> registerUser({
    required String rg,
    required String email,
    required String nome,
    required String telefone,
    required String senha,
  }) async {
    // Valida antes de qualquer chamada de rede para economizar recursos
    // e para possibilitar feedback imediato ao usuário.
    final validacao = validarDados(
      rg: rg,
      email: email,
      nome: nome,
      telefone: telefone,
      senha: senha,
    );

    if (!validacao['valido']) {
      // Retorna um erro estruturado que a UI pode interpretar e mostrar.
      return {
        'success': false,
        'error': 'Validação',
        'message': validacao['erro'],
      };
    }

    // Nullable para suportar rollback caso a Cloud Function falhe após
    // a criação da conta no Firebase Auth.
    UserCredential? userCredential;

    try {
      // Normaliza campos para enviar ao Auth e à Cloud Function.
      final emailLimpo = email.trim();
      final nomeLimpo = nome.trim();
      final rgLimpo = rg.trim();
      final telefoneLimpo = telefone.trim();

      // 1) Cria a conta no Firebase Auth.
      // Se isso lançar uma FirebaseAuthException, jamais teremos um
      // usuário criado que precise de rollback aqui.
      userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailLimpo,
        password: senha,
      );

      // 2) Envia e-mail de verificação. A verificação é necessária para
      // permitir login em `loginUser` (veja checagem de `emailVerified`).
      await userCredential.user?.sendEmailVerification();

      // 3) Salva dados adicionais no Firestore via Cloud Function.
      // Usamos Cloud Functions para garantir regras/validações server-side
      // (ex: checar duplicidade de RG) e para evitar expor lógica no cliente.
      final callable = FirebaseFunctions.instance.httpsCallable('createUser');

      final result = await callable.call({
        'name': nomeLimpo,
        'rg': rgLimpo,
        'telefone': telefoneLimpo,
        'email': emailLimpo,
      });

      // Se tudo ocorreu bem, retornamos identificadores úteis para a UI.
      return {
        'success': true,
        'authUid': userCredential.user?.uid,
        'userId': result.data, // Cloud Function retorna o uid do documento criado
        'message': 'Cadastro realizado com sucesso!',
      };
    } on FirebaseAuthException catch (e) {
      // Erros do Firebase Auth (email duplicado, senha fraca, etc.).
      // Aqui não precisamos desfazer nada porque a criação pode ter falhado
      // ou o SDK já lidou com a consistência.
      String message = 'Erro ao criar usuário';

      // Mapeia códigos técnicos para mensagens amigáveis à UI.
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
      // A conta já foi criada no Auth, mas a Cloud Function falhou.
      // Fazemos rollback: removemos o usuário criado no Auth para manter
      // consistência entre os sistemas (Auth <-> Firestore).
      await userCredential?.user?.delete();

      return {
        'success': false,
        'error': e.code,
        'message': e.message ?? 'Erro ao salvar dados do usuário',
      };
    } catch (e) {
      // Qualquer outro erro inesperado também dispara rollback por precaução.
      await userCredential?.user?.delete();

      return {
        'success': false,
        'error': 'Erro inesperado',
        'message': e.toString(),
      };
    }
  }

  /// Envia e-mail de redefinição de senha em dois passos:
  /// 1) Verifica via Cloud Function se o e-mail existe no Firestore
  /// 2) Se existir, solicita ao Firebase Auth o envio do link de redefinição
  ///
  /// Este fluxo evita vazamento de informação e permite mensagens amigáveis
  /// quando o e-mail não está cadastrado.
  static Future<Map<String, dynamic>> sendPasswordReset({
    required String email,
  }) async {
    final emailLimpo = email.trim();

    // Validação local para evitar chamadas desnecessárias.
    if (emailLimpo.isEmpty || !emailLimpo.contains('@')) {
      return {'success': false, 'message': 'Digite um e-mail válido'};
    }

    try {
      // Chamada server-side que pode lançar 'not-found' quando o e-mail
      // não estiver cadastrado no Firestore. Isso permite diferenciar
      // mensagens entre "não existe" e "falha ao enviar".
      await FirebaseFunctions.instance
          .httpsCallable('checkUserExists')
          .call({'email': emailLimpo});

      // Se a função não lançou, o e-mail existe — pede envio do link.
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailLimpo);
      return {'success': true};
    } on FirebaseFunctionsException catch (e) {
      // Tratamento específico do erro retornado pela Cloud Function.
      String message = 'Erro ao enviar e-mail de recuperação';
      if (e.code == 'not-found') {
        message = 'Nenhuma conta encontrada com este e-mail';
      }
      return {'success': false, 'message': message};
    } on FirebaseAuthException catch (e) {
      // Erros do Firebase Auth ao tentar enviar o e-mail (ex: invalid-email).
      String message = 'Erro ao enviar e-mail de recuperação';
      if (e.code == 'invalid-email') message = 'E-mail inválido';
      return {'success': false, 'message': message};
    } catch (e) {
      return {'success': false, 'message': 'Erro inesperado: ${e.toString()}'};
    }
  }

  /// Realiza o fluxo de login:
  /// - Valida campos localmente
  /// - Autentica no Firebase Auth
  /// - Lida com 2FA (re-lança a exceção especializada para a UI tratar)
  /// - Verifica se o e-mail foi confirmado e impede login se não
  /// - Busca dados adicionais do Firestore via Cloud Function e retorna
  ///   um objeto combinado com dados do Auth + Firestore
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String senha,
  }) async {
    final emailLimpo = email.trim();

    // Validações básicas para evitar chamadas de rede com dados óbvios inválidos.
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
      // Autenticação principal. Se o usuário tiver configurado MFA/2FA,
      // o SDK lança `FirebaseAuthMultiFactorException` contendo o resolver.
      final userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailLimpo,
        password: senha,
      );

      final user = userCredential.user;

      // Verificação de segurança: o SDK normalmente não retorna null,
      // mas defensivamente protegemos contra isso.
      if (user == null) {
        return {
          'success': false,
          'error': 'Usuário inválido',
          'message': 'Não foi possível carregar o usuário autenticado',
        };
      }

      // Impede login de contas cujo e-mail não foi confirmado.
      // Também faz signOut para limpar qualquer sessão criada.
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

      // Busca dados adicionais do Firestore via Cloud Function. A função
      // backend deve usar request.auth.uid para identificar o usuário.
      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserData')
          .call();

      // Converte o retorno dinâmico do SDK para um Map tipado.
      final userData = Map<String, dynamic>.from(result.data as Map? ?? {});

      // Retorna o objeto combinado: dados de autenticação + perfil salvo.
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
      // Repropaga a exceção especializada para a camada de UI, que precisa
      // do resolver presente nessa exceção para completar o fluxo 2FA.
      rethrow;
    } on FirebaseAuthException catch (e) {
      // Mapeia códigos do Auth para mensagens amigáveis.
      String message = 'Erro ao fazer login';

      if (e.code == 'invalid-email') {
        message = 'E-mail inválido';
      } else if (e.code == 'user-disabled') {
        message = 'Este usuário foi desativado';
      } else if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        // 'invalid-credential' pode aparecer em versões mais recentes do SDK.
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
      // Falha ao buscar dados adicionais do Firestore após autenticação.
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

  /// Busca dados do usuário atualmente autenticado combinando informações
  /// do Firebase Auth com os dados salvos no Firestore (via Cloud Function).
  static Future<Map<String, dynamic>> fetchUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'Usuário não autenticado'};
      }

      // Reutiliza a mesma Cloud Function `getUserData` usada no login.
      final result = await FirebaseFunctions.instance
          .httpsCallable('getUserData')
          .call();

      final userData = Map<String, dynamic>.from(result.data as Map? ?? {});

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