// Autor: Caio Ferreira Polo
// Descrição: Tela inicial do aplicativo com opções de cadastro e login
import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/auth/login_page.dart';
import 'package:mescla_invest/src/pages/auth/registration_steps_page.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
          child: Column(
            children: [
              const SizedBox(height: 60),

              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/MesclaLogoPequena.png',
                      width: 50,
                    ),
                    const SizedBox(width: 8),
                    ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [
                          Color(0xFF000000),
                          AppColors.azul,
                          AppColors.preto,
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'MesclaInvest',
                        style: TextStyle(
                          fontSize: 45,
                          color: AppColors.branco,
                          fontFamily: 'JosefinSans',
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              const Center(
                child: Text(
                  'Onde grandes ideias ganham fôlego.',
                  style: TextStyle(
                    fontSize: 19,
                    fontFamily: 'JosefinSans',
                  ),
                ),
              ),

              const Spacer(),

              // BOTÃO 1 (Abrir conta)
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.azul800, width: 0.25),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.azul.withValues(alpha: 0.4),
                  ),
                  child: const Text(
                    'Abrir conta',
                    style: TextStyle(
                      color: AppColors.branco,
                      fontFamily: 'JosefinSans',
                      fontSize: 22,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // BOTÃO 2 (Já tenho conta)
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.cinza200,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(color: AppColors.cinza300),
                    ),
                    elevation: 3,
                    shadowColor: AppColors.cinza400,
                  ),
                  child: const Text(
                    'Já tenho conta',
                    style: TextStyle(
                      color: AppColors.cinza700,
                      fontFamily: 'JosefinSans',
                      fontSize: 18,
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
}


