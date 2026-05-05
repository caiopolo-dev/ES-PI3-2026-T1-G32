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

    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text)) {
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
                        'Recuperar Senha',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JosefinSans',
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Subtítulo
                      const Text(
                        'Informe o email cadastrado \n para receber as instruções',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontFamily: 'JosefinSans',
                          color: Colors.black54,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Email Input
                      TextField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
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
                    ],
                  ),
                ),
              ),

              // Botão Enviar Email
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: isLoading ? null : sendRecoveryEmail,
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
                          'Enviar Email',
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 22,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 126),
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
