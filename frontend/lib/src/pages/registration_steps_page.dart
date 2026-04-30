// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela de cadastro multi-etapas com validação

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  int currentStep = 0;
  bool isLoading = false;

  final TextEditingController rgController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String errorText = '';

  // Validações
  bool validateStep() {
    setState(() => errorText = '');

    switch (currentStep) {
      case 0:
        String rg = rgController.text.trim();
        if (rg.isEmpty) {
          errorText = 'RG é obrigatório';
          return false;
        }
        if (!RegExp(r'^[0-9]{7,9}$').hasMatch(rg)) {
          errorText = 'RG deve ter entre 7 e 9 dígitos';
          return false;
        }
        return true;

      case 1:
        if (emailController.text.isEmpty || !emailController.text.contains('@')) {
          errorText = 'Digite um email válido';
          return false;
        }
        return true;

      case 2:
        if (nameController.text.trim().split(' ').length < 2) {
          errorText = 'Digite seu nome completo';
          return false;
        }
        return true;

      case 3:
        if (phoneController.text.length < 10) {
          errorText = 'Número inválido';
          return false;
        }
        return true;

      case 4:
        String password = passwordController.text;
        String confirm = confirmPasswordController.text;

        final regex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$');

        if (!regex.hasMatch(password)) {
          errorText =
          'Senha deve ter 8+ caracteres, maiúscula, minúscula e número';
          return false;
        }

        if (password != confirm) {
          errorText = 'As senhas não coincidem';
          return false;
        }

        return true;

      default:
        return false;
    }
  }

  // Conteúdo dinâmico
  Widget buildStepContent() {
    switch (currentStep) {
      case 0:
        return buildInput(
          rgController,
          'Digite seu RG',
          maxLength: 9,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        );
      case 1:
        return buildInput(emailController, 'Digite seu email');
      case 2:
        return buildInput(nameController, 'Digite o seu nome completo');
      case 3:
        return buildInput(phoneController, 'Digite seu celular');
      case 4:
        return Column(
          children: [
            buildInput(passwordController, 'Digite sua senha', obscure: true),
            const SizedBox(height: 20),
            buildInput(confirmPasswordController, 'Confirme sua senha', obscure: true),
          ],
        );
      default:
        return const Text("Finalizado");
    }
  }

  Widget buildInput(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      inputFormatters: inputFormatters,
      textAlign: TextAlign.center,
      style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 18),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black26),
        counterText: '',
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.black26, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF013593), width: 2),
        ),
      ),
    );
  }

  void nextStep() async {
    if (validateStep()) {
      if (currentStep < 4) {
        setState(() => currentStep++);
      } else {
        setState(() => isLoading = true);

        final result = await AuthService.registerUser(
          rg: rgController.text,
          email: emailController.text,
          nome: nameController.text,
          telefone: phoneController.text,
          senha: passwordController.text,
        );

        setState(() => isLoading = false);

        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cadastro realizado com sucesso!')),
          );
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Erro ao registrar')),
          );
        }
      }
    } else {
      setState(() {});
    }
  }

  void previousStep() {
    if (currentStep > 0) {
      setState(() => currentStep--);
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

              // Título dinâmico
              Text(
                'Cadastro passo ${currentStep + 1} - 5',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JosefinSans',
                ),
              ),

              const SizedBox(height: 30),

              // Conteúdo dinâmico
              buildStepContent(),

              const SizedBox(height: 20),

              // Erro
              if (errorText.isNotEmpty)
                Text(
                  errorText,
                  style: const TextStyle(color: Colors.red),
                ),

              const SizedBox(height: 40),

              // Botão continuar
              SizedBox(
                width: 250,
                child: ElevatedButton(
                  onPressed: isLoading ? null : nextStep,
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
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(
                            fontFamily: 'JosefinSans',
                            fontSize: 18,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Botão voltar
                SizedBox(
                  width: 160,
                  child: ElevatedButton(
                    onPressed: () {
                      if (currentStep == 0) {
                        Navigator.pop(context); // volta para a initial_page
                      } else {
                        previousStep(); // volta um passo
                      }
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
}