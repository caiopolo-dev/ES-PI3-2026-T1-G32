// Autor: Henrique Leite de Camargo 25005997
// Data: 06/05/2026
// Descrição: Tela de verificação do código 2FA no login

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/widgets/main_scaffold.dart';
import 'package:mescla_invest/src/services/auth_service.dart';
import 'package:mescla_invest/src/services/two_factor_service.dart';

// resolver é obtido da FirebaseAuthMultiFactorException lançada durante o login
// quando o usuário tem 2FA ativo. Ele contém o estado necessário para completar
// a autenticação após a validação do código TOTP.
class TwoFactorVerifyPage extends StatefulWidget {
  final MultiFactorResolver resolver;
  final Map<String, dynamic>? usuario;

  const TwoFactorVerifyPage({
    super.key,
    required this.resolver,
    this.usuario,
  });

  @override
  State<TwoFactorVerifyPage> createState() => _TwoFactorVerifyPageState();
}

class _TwoFactorVerifyPageState extends State<TwoFactorVerifyPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String _errorText = '';

  Future<void> _verify() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorText = 'Digite o código de 6 dígitos');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = '';
    });

    final result = await TwoFactorService.verifyTotp(
      widget.resolver,
      _codeController.text,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      // Após completar o 2FA, o token de auth existe mas os dados do Firestore
      // ainda não foram carregados — busca os dados do usuário antes de navegar.
      final data = await AuthService.fetchUserData();
      final usuario = data['success'] == true
          ? data['usuario'] as Map<String, dynamic>?
          : null;

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => MainScaffold(usuario: usuario)),
        (_) => false,
      );
    } else {
      setState(() {
        _errorText =
            result['message'] as String? ?? 'Código inválido. Tente novamente.';
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.preto),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset('assets/MesclaLogoPequena.png'),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Verificação em duas etapas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JosefinSans',
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Digite o código gerado pelo seu app autenticador',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.preto54,
                          fontFamily: 'JosefinSans',
                        ),
                      ),

                      const SizedBox(height: 32),

                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 24,
                          fontFamily: 'JosefinSans',
                          letterSpacing: 8,
                        ),
                        decoration: const InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(color: AppColors.cinza400),
                          counterText: '',
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.cinza400),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.azul, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (_errorText.isNotEmpty)
                        Text(
                          _errorText,
                          style: const TextStyle(
                            color: AppColors.vermelho,
                            fontFamily: 'JosefinSans',
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.azul800, width: 0.25),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.azul.withValues(alpha: 0.4),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.branco),
                          ),
                        )
                      : const Text(
                          'Verificar',
                          style: TextStyle(fontFamily: 'JosefinSans', fontSize: 22),
                        ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}