// Autor: Henrique Leite de Camargo 25005997
// Data: 06/05/2026
// Descrição: Service para autenticação de dois fatores via TOTP

import 'package:firebase_auth/firebase_auth.dart';

class TwoFactorService {
  static Future<Map<String, dynamic>> generateSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      if (!user.emailVerified) {
        await user.sendEmailVerification();
        return {
          'success': false,
          'message':
              'Confirme seu e-mail antes de ativar o 2FA. '
              'Enviamos um link de verificação para ${user.email}.',
        };
      }

      final session = await user.multiFactor.getSession();
      final secret =
          await TotpMultiFactorGenerator.generateSecret(session);
      final qrCodeUrl = await secret.generateQrCodeUrl(
        accountName: user.email ?? 'usuario',
        issuer: 'MesclaInvest',
      );
      return {'success': true, 'qrCodeUrl': qrCodeUrl, 'secret': secret};
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro ao gerar QR Code: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> enrollTotp(
    TotpSecret secret,
    String code,
  ) async {
    try {
      final assertion =
          await TotpMultiFactorGenerator.getAssertionForEnrollment(
        secret,
        code,
      );
      await FirebaseAuth.instance.currentUser!.multiFactor.enroll(
        assertion,
        displayName: 'Autenticador',
      );
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Código inválido. Tente novamente.'};
    }
  }

  static Future<Map<String, dynamic>> verifyTotp(
    MultiFactorResolver resolver,
    String code,
  ) async {
    try {
      final assertion =
          await TotpMultiFactorGenerator.getAssertionForSignIn(
        resolver.hints.first.uid,
        code,
      );
      await resolver.resolveSignIn(assertion);
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Código inválido. Tente novamente.'};
    }
  }
}
