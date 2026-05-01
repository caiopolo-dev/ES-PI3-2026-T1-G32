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
  String errorText = '';

  final nameController = TextEditingController();
  final rgController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Passo 0: Nome + RG | Passo 1: Email + Telefone | Passo 2: Senha
  static const List<String> _stepTitles = [
    'Dados pessoais',
    'Contato',
    'Senha',
  ];

  bool validateStep() {
    setState(() => errorText = '');

    switch (currentStep) {
      case 0:
        if (nameController.text.trim().split(' ').length < 2) {
          errorText = 'Digite seu nome completo';
          return false;
        }
        final rg = rgController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (rg.isEmpty || rg.length < 7 || rg.length > 9) {
          errorText = 'RG deve ter entre 7 e 9 dígitos';
          return false;
        }
        return true;

      case 1:
        if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text)) {
          errorText = 'Digite um email válido';
          return false;
        }
        final phone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.length < 10) {
          errorText = 'Número de celular inválido';
          return false;
        }
        return true;

      case 2:
        final password = passwordController.text;
        if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password)) {
          errorText = 'Senha deve ter 8+ caracteres, maiúscula, minúscula e número';
          return false;
        }
        if (password != confirmPasswordController.text) {
          errorText = 'As senhas não coincidem';
          return false;
        }
        return true;

      default:
        return false;
    }
  }

  Widget buildStepContent() {
    switch (currentStep) {
      case 0:
        return Column(
          children: [
            buildInput(nameController, 'Nome completo'),
            const SizedBox(height: 20),
            buildInput(
              rgController,
              'RG',
              keyboardType: TextInputType.number,
              inputFormatters: [_RgFormatter()],
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            buildInput(emailController, 'Email'),
            const SizedBox(height: 20),
            buildInput(
              phoneController,
              'Celular',
              keyboardType: TextInputType.phone,
              inputFormatters: [_PhoneFormatter()],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            buildInput(passwordController, 'Senha', obscure: true),
            const SizedBox(height: 8),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: passwordController,
              builder: (context, value, _) {
                final valid = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(value.text);
                if (valid) return const SizedBox.shrink();
                return const Text(
                  'A senha deve conter 8+ caracteres, uma maiúscula e uma minúscula',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black38,
                    fontFamily: 'JosefinSans',
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            buildInput(confirmPasswordController, 'Confirme a senha', obscure: true),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget buildInput(
    TextEditingController controller,
    String hint, {
    bool obscure = false,
    int? maxLength,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
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
    if (!validateStep()) {
      setState(() {});
      return;
    }

    if (currentStep < 2) {
      setState(() => currentStep++);
      return;
    }

    setState(() => isLoading = true);

    final result = await AuthService.registerUser(
      rg: rgController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      email: emailController.text,
      nome: nameController.text,
      telefone: phoneController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      senha: passwordController.text,
    );

    setState(() => isLoading = false);

    if (!mounted) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (currentStep == 0) {
              Navigator.pop(context);
            } else {
              setState(() => currentStep--);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child: Image.asset('assets/MesclaLogoPequena.png'),
                ),
              ),

              const SizedBox(height: 32),

              Text(
                _stepTitles[currentStep],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'JosefinSans',
                ),
              ),

              Text(
                'Passo ${currentStep + 1} de 3',
                style: TextStyle(fontSize: 20, color: Colors.grey[500], fontFamily: 'JosefinSans'),
              ),

              const SizedBox(height: 30),

              buildStepContent(),

              const SizedBox(height: 20),

              if (errorText.isNotEmpty)
                Text(errorText, style: const TextStyle(color: Colors.red)),

              const SizedBox(height: 40),

              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: isLoading ? null : nextStep,
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          currentStep == 2 ? 'Finalizar' : 'Continuar',
                          style: const TextStyle(fontFamily: 'JosefinSans', fontSize: 22),
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

// Máscara RG: XX.XXX.XXX-X
class _RgFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 9) return oldValue;

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 2 || i == 5) buf.write('.');
      if (i == 8) buf.write('-');
      buf.write(digits[i]);
    }

    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

// Máscara telefone: (XX) XXXXX-XXXX
class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 11) return oldValue;

    final buf = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (i == 7) buf.write('-');
      buf.write(digits[i]);
    }

    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
