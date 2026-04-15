// Autor: Henrique Leite de Camargo [25005997]
// Tela de cadastro - Telefone

import 'package:flutter/material.dart';

class CadastroTelefonePage extends StatefulWidget {
  const CadastroTelefonePage({super.key});

  @override
  State<CadastroTelefonePage> createState() => _CadastroTelefonePageState();
}

class _CadastroTelefonePageState extends State<CadastroTelefonePage> {
  final TextEditingController _telefoneController = TextEditingController();

  @override
  void dispose() {
    _telefoneController.dispose();
    super.dispose();
  }

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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Image.asset(
                      'assets/MesclaLogoPequena.png',
                      width: 50,
                    ),
                    const SizedBox(width: 8),
                    Transform.translate(
                      offset: const Offset(0, 3),
                      child: ShaderMask(
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
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Cadastro passo 3 - 4',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'JosefinSans',
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 32),

              Center(
                child: SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _telefoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontFamily: 'JosefinSans',
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Digite o seu número de telefone',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        fontFamily: 'JosefinSans',
                        fontSize: 18,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.black87),
                      ),
                    ),
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
                    onPressed: () {
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3E3E3),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'JosefinSans',
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Center(
                child: Container(
                  width: 160,
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
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE3E3E3),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      '< Voltar',
                      style: TextStyle(
                        color: Colors.black,
                        fontFamily: 'JosefinSans',
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}