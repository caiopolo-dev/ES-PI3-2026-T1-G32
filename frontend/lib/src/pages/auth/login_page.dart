// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela de login (email e senha)

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/services/auth_service.dart';
import 'package:mescla_invest/src/pages/catalog_page.dart';
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

        if (!mounted) return;

        if (result['success']) {
          // Login bem-sucedido
          final usuario = result['usuario'];
          
          // Redireciona para catálogo
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => InitialCatalogPage(
                usuario: usuario as Map<String, dynamic>?,
              ),
            ),
          );
        } else {
          // Erro no login
          setState(() {
            errorText = result['message'] ?? 'Erro ao fazer login';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Erro ao fazer login'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } on FirebaseAuthMultiFactorException catch (e) {
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
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
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
                          hintStyle: TextStyle(color: Colors.black26),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black26),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF013593), width: 2),
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
                          hintStyle: TextStyle(color: Colors.black26),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.black26),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF013593), width: 2),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Erro
                      if (errorText.isNotEmpty)
                        Text(
                          errorText,
                          style: const TextStyle(color: Colors.red),
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
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFF1565C0), width: 0.25),
                    ),
                    elevation: 6,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
                    backgroundColor: const Color(0xFFEEEEEE),
                    foregroundColor: const Color(0xFF555555),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black26,
                  ),
                  child: const Text(
                    'Recuperar senha',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 18,
                      color: Color(0xFF555555),
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