// Caio Ferreira Polo 25002823


import 'package:flutter/material.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final TextEditingController emailController = TextEditingController();

  String errorText = '';
  bool isLoading = false;

  bool validateEmail() {
    setState(() => errorText = '');

    if (emailController.text.isEmpty) {
      errorText = 'Digite seu email';
      return false;
    }

    if (!emailController.text.contains('@')) {
      errorText = 'Digite um email válido';
      return false;
    }

    return true;
  }

  Future<void> sendRecoveryEmail() async {
    if (validateEmail()) {
      setState(() => isLoading = true);

      try {
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email de recuperação enviado para ${emailController.text}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Aguardar 1 segundo e voltar para login
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            errorText = 'Erro ao enviar email: ${e.toString()}';
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
                'Recuperar Senha',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JosefinSans',
                ),
              ),

              const SizedBox(height: 15),

              // Subtítulo
              const Text(
                'Informe o email cadastrado para receber as instruções',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontFamily: 'JosefinSans',
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 30),

              // Email Input
              TextField(
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

              // Erro
              if (errorText.isNotEmpty)
                Text(
                  errorText,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 40),

              // Botão Enviar Email
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendRecoveryEmail,
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
                          'Enviar Email',
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
                    Navigator.pop(context);
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
    emailController.dispose();
    super.dispose();
  }
}
