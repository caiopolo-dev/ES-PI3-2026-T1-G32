// código de Caio Ferreira Polo - RA 25002823
import 'package:flutter/material.dart';

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

              
              Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(1.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 190, 190, 190),
                        Color.fromARGB(255, 220, 219, 219),
                        Color.fromARGB(255, 190, 190, 190),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3E3E3),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Abrir conta',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'JosefinSans',
                        fontSize: 18,
                        
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              
              Center(
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(1.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromARGB(255, 190, 190, 190),
                        Color.fromARGB(255, 220, 219, 219),
                        Color.fromARGB(255, 190, 190, 190),
                      ],
                      stops: [0.0, 0.5, 1.0],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3E3E3),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Já tenho conta',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'JosefinSans',
                        fontSize: 18,
                      
                      ),
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