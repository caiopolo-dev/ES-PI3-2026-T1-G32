// Autor: Henrique Leite de Camargo 25005997
// Data: 06/05/2026
// Descrição: Service para autenticação de dois fatores via TOTP

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class TwoFactorService {
  // Gera o segredo TOTP e a URL do QR Code para vincular um autenticador.
  // Pré-requisito: e-mail verificado — Firebase exige verificação antes de registrar
  // um segundo fator para garantir que o usuário controla o e-mail da conta.
  static Future<Map<String, dynamic>> generateSetup() async {
    try {
      // currentUser! é seguro aqui: esta tela só é acessível por usuários logados.
      final user = FirebaseAuth.instance.currentUser!;

      // Firebase rejeita o enrollment de TOTP se o e-mail não estiver verificado.
      // Ao invés de deixar o Firebase lançar um erro opaco, verificamos antes
      // e reenviamos o e-mail de verificação proativamente.
      if (!user.emailVerified) {
        await user.sendEmailVerification();
        return {
          'success': false,
          'message':
              'Confirme seu e-mail antes de ativar o 2FA. '
              'Enviamos um link de verificação para ${user.email}.',
        };
      }

      // Sessão multifator: token de curta duração que autoriza alterações de segurança.
      // Obrigatório para operações multifator mesmo em usuários já autenticados.
      final session = await user.multiFactor.getSession();

      // Gera um novo segredo TOTP criptograficamente aleatório vinculado à sessão.
      final secret = await TotpMultiFactorGenerator.generateSecret(session);

      // Converte o segredo para URL no formato otpauth://totp/... reconhecido
      // por Google Authenticator, Authy e outros apps compatíveis com RFC 6238.
      final qrCodeUrl = await secret.generateQrCodeUrl(
        accountName: user.email ?? 'usuario',
        issuer: 'MesclaInvest',
      );

      return {'success': true, 'qrCodeUrl': qrCodeUrl, 'secret': secret};
    } on FirebaseAuthException catch (e) {
      // Firebase exige autenticação recente para operações de segurança como
      // o enrollment de MFA. Se o token estiver velho, retorna flag para a
      // tela pedir a senha ao usuário e reautenticar antes de tentar de novo.
      if (e.code == 'requires-recent-login') {
        return {'success': false, 'requiresReauth': true};
      }
      return {
        'success': false,
        'message': 'Erro ao gerar QR Code: ${e.message}',
      };
    } on PlatformException catch (e) {
      // Em iOS/Android o Firebase pode lançar PlatformException em vez de
      // FirebaseAuthException quando o token está antigo.
      final msg = e.message?.toLowerCase() ?? '';
      if (msg.contains('requires recent authentication')) {
        return {'success': false, 'requiresReauth': true};
      }
      return {
        'success': false,
        'message': 'Erro ao gerar QR Code: ${e.message}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao gerar QR Code: ${e.toString()}',
      };
    }
  }

  // Reautentica o usuário com e-mail e senha.
  // Necessário quando o Firebase rejeita operações sensíveis por token antigo
  // (código requires-recent-login). Após reautenticar, o fluxo pode ser retomado.
  static Future<Map<String, dynamic>> reauthenticate(
    String email,
    String password,
  ) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await FirebaseAuth.instance.currentUser!
          .reauthenticateWithCredential(credential);
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      // wrong-password ou invalid-credential indicam senha incorreta.
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return {'success': false, 'message': 'Senha incorreta.'};
      }
      return {'success': false, 'message': 'Erro ao autenticar: ${e.message}'};
    }
  }

  // Registra o TOTP como segundo fator na conta do usuário.
  // O `code` é o código de 6 dígitos gerado pelo app autenticador após escanear o QR Code.
  // O Firebase valida o código contra o `secret` — se correto, o fator é salvo na conta.
  static Future<Map<String, dynamic>> enrollTotp(
    TotpSecret secret,
    String code,
  ) async {
    try {
      // Cria uma asserção que prova ao Firebase que o usuário tem acesso ao autenticador.
      // O Firebase valida internamente se o código corresponde ao segredo e ao tempo atual.
      final assertion = await TotpMultiFactorGenerator.getAssertionForEnrollment(
        secret,
        code,
      );

      // Registra o TOTP como fator adicional da conta.
      // displayName é exibido na lista de fatores no console do Firebase.
      await FirebaseAuth.instance.currentUser!.multiFactor.enroll(
        assertion,
        displayName: 'Autenticador',
      );
      return {'success': true};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        return {'success': false, 'message': 'Código inválido. Tente novamente.'};
      }
      return {'success': false, 'message': 'Erro ao ativar 2FA: ${e.message}'};
    } catch (e) {
      return {'success': false, 'message': 'Erro inesperado. Verifique sua conexão.'};
    }
  }

  // Completa o login quando o usuário tem 2FA ativo.
  // `resolver` vem da FirebaseAuthMultiFactorException lançada em signInWithEmailAndPassword
  // e contém o estado interno necessário para finalizar a autenticação.
  static Future<Map<String, dynamic>> verifyTotp(
    MultiFactorResolver resolver,
    String code,
  ) async {
    try {
      // O resolver foi obtido da FirebaseAuthMultiFactorException no login;
      // resolveSignIn completa a autenticação se o código TOTP for válido.

      // hints.first.uid identifica qual fator registrado o usuário está usando.
      // Em contas com múltiplos fatores, hints lista todos; aqui assumimos apenas um.
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
        resolver.hints.first.uid,
        code,
      );

      // Finaliza o fluxo de login — após este ponto o usuário está completamente autenticado.
      await resolver.resolveSignIn(assertion);
      return {'success': true};
    } catch (e) {
      // Firebase lança exceção para código inválido ou expirado.
      return {'success': false, 'message': 'Código inválido. Tente novamente.'};
    }
  }
}
