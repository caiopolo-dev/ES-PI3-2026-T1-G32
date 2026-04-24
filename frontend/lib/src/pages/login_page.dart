// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela de login (RG e senha)

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'auth/catalog_page.dart';
import 'password_recovery_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController rgController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String errorText = '';
  bool isLoading = false;

  bool validateLogin() {
    setState(() => errorText = '');

    if (rgController.text.isEmpty) {
      errorText = 'Digite seu RG';
      return false;
    }

    if (passwordController.text.isEmpty) {
      errorText = 'Digite sua senha';
      return false;
    }

    return true;
  }

  Future<void> login() async {
    if (validateLogin()) {
      setState(() => isLoading = true);

      try {
        final result = await AuthService.loginUser(
          rg: rgController.text,
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
              builder: (context) => const InitialCatalogPage(),
              settings: RouteSettings(arguments: usuario),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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

              // RG
              TextField(
                controller: rgController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 18),
                decoration: const InputDecoration(
                  hintText: 'Digite seu RG',
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

              const SizedBox(height: 40),

              // Link Recuperar Senha
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PasswordRecoveryPage(),
                    ),
                  );
                },
                child: const Text(
                  'Esqueci minha senha',
                  style: TextStyle(
                    color: Color(0xFF013593),
                    fontSize: 14,
                    fontFamily: 'JosefinSans',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Botão Login
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: isLoading ? null : login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão Voltar
              SizedBox(
                width: 160,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // volta pra MainPage
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEEEEEE),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                      side: const BorderSide(color: Colors.black12),
                    ),
                  ),
                  child: const Text(
                    'Voltar',
                    style: TextStyle(
                      fontFamily: 'JosefinSans',
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    rgController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}