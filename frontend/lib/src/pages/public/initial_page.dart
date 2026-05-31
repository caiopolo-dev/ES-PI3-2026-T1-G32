// Autor: Caio Ferreira Polo
// Descrição: Tela inicial do aplicativo com opções de cadastro e login
import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/pages/public/auth/login_page.dart';
import 'package:mescla_invest/src/pages/public/auth/registration_steps_page.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Tela inicial simples: mostra logo, slogan e dois botões principais.
    // - 'Abrir conta' navega para a tela de registro (`RegisterPage`).
    // - 'Já tenho conta' navega para a tela de login (`LoginPage`).
    // Este widget é `Stateless` e não mantém estado local; toda ação de
    // navegação é feita via `Navigator`.
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
                child: AppPrimaryButton(
                  label: 'Abrir conta',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  elevated: true,
                  verticalPadding: 14,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: 16),

              // BOTÃO 2 (Já tenho conta)
              SizedBox(
                width: 200,
                child: AppSecondaryButton(
                  label: 'Já tenho conta',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  verticalPadding: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


