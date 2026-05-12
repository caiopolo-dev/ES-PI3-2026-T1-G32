// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela de login (email e senha)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/auth_service.dart';
import 'package:mescla_invest/src/pages/home/home_page.dart';
import 'package:mescla_invest/src/pages/auth/password_recovery_page.dart';
import 'package:mescla_invest/src/pages/auth/two_factor_verify_page.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorText = '';
  bool isLoading = false;

  // Validação local antes de chamar a Cloud Function, evitando
  // uma requisição de rede desnecessária para erros evidentes.
  bool validateLogin() {
    setState(() => errorText = '');

    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text)) {
      errorText = 'Digite um email válido';
      return false;
    }

    if (passwordController.text.length < 8) {
      errorText = 'Senha deve ter pelo menos 8 caracteres';
      return false;
    }

    return true;
  }

  Future<void> login() async {
    if (validateLogin()) {
      setState(() => isLoading = true);

      try {
        final result = await AuthService.loginUser(
          email: emailController.text,
          senha: passwordController.text,
        );

        // Após qualquer await, o widget pode ter sido descartado — verificar antes de usar context.
        if (!mounted) return;

        if (result['success']) {
          // Login bem-sucedido
          final usuario = result['usuario'];
          
          // Redireciona para catálogo
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => HomePage(
                usuario: usuario as Map<String, dynamic>?,
              ),
            ),
            (_) => false,
          );
        } else {
          // Erro no login
          setState(() {
            errorText = result['message'] ?? 'Erro ao fazer login';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erro ao fazer login'),
              backgroundColor: AppColors.vermelho,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } on FirebaseAuthMultiFactorException catch (e) {
  // Usuário tem 2FA ativo: o Firebase não completa o login e lança esta exceção
  // com o resolver necessário para validar o código TOTP.
  if (mounted) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TwoFactorVerifyPage(
          resolver: e.resolver,
          usuario: null,
        ),
      ),
    );
  }
} catch (e) {
        if (mounted) {
          setState(() {
            errorText = 'Erro de conexão: ${e.toString()}';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${e.toString()}'),
              backgroundColor: AppColors.vermelho,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        // finally garante que isLoading é resetado mesmo em caso de exceção.
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
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
                      // Logo
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset('assets/MesclaLogoPequena.png'),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Título
                      const Text(
                        'Log-in',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JosefinSans',
                        ),
                      ),

                      const SizedBox(height: 30),

                      // email
                      TextField(
                        keyboardType: TextInputType.emailAddress,
                        controller: emailController,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 18),
                        decoration: const InputDecoration(
                          hintText: 'Digite seu email',
                          hintStyle: TextStyle(color: AppColors.cinza400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.cinza400),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.azul, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Senha
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 18),
                        decoration: const InputDecoration(
                          hintText: 'Digite sua senha',
                          hintStyle: TextStyle(color: AppColors.cinza400),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.cinza400),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.azul, width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Erro
                      if (errorText.isNotEmpty)
                        Text(
                          errorText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.vermelho),
                        ),
                    ],
                  ),
                ),
              ),

              // Botão Login
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
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
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.branco),
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 22,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão Recuperar Senha
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PasswordRecoveryPage(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cinza200,
                    foregroundColor: AppColors.cinza700,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.cinza300),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.cinza400,
                  ),
                  child: const Text(
                    'Recuperar senha',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 18,
                      color: AppColors.cinza700,
                    ),
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

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}