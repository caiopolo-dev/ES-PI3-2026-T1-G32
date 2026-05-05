// código de Caio Ferreira Polo - RA 25002823
import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'auth/registration_steps_page.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                          Color(0xFF013593),
                          Color(0xFF080B11),
                        ],
                        stops: [0.0, 0.5, 1.0],
                      ).createShader(bounds),
                      child: const Text(
                        'MesclaInvest',
                        style: TextStyle(
                          fontSize: 45,
                          color: Colors.white,
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
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFF1565C0), width: 0.25),
                    ),
                    elevation: 6,
                    shadowColor: Colors.blue.withOpacity(0.4),
                  ),
                  child: const Text(
                    'Abrir conta',
                    style: TextStyle(
                      color: Colors.white,
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
                    backgroundColor: const Color(0xFFEEEEEE),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: Colors.black12),
                    ),
                    elevation: 3,
                    shadowColor: Colors.black26,
                  ),
                  child: const Text(
                    'Já tenho conta',
                    style: TextStyle(
                      color: Color(0xFF555555),
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


