// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela de cadastro multi-etapas com validação

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/src/services/auth_service.dart';

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

  // Valida os campos do passo atual antes de avançar.
  // Cada case corresponde a um step da tela.
  bool validateStep() {
    setState(() => errorText = '');

    switch (currentStep) {
      case 0: // Dados pessoais: nome completo e RG
        final nome = nameController.text.trim();
        if (nome.split(' ').length < 2) {
          errorText = 'Digite seu nome completo';
          return false;
        }
        if (RegExp(r'[0-9]').hasMatch(nome)) {
          errorText = 'Nome não pode conter números';
          return false;
        }
        // Remove a máscara do RG antes de validar o comprimento real.
        final rg = rgController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (rg.isEmpty || rg.length < 7 || rg.length > 9) {
          errorText = 'RG deve ter entre 7 e 9 dígitos';
          return false;
        }
        return true;

      case 1: // Contato: email e telefone
        if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text)) {
          errorText = 'Digite um email válido';
          return false;
        }
        // Remove a máscara do telefone para verificar se há dígitos suficientes.
        final phone = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
        if (phone.length < 10) {
          errorText = 'Número de celular inválido';
          return false;
        }
        return true;

      case 2: // Senha: regex de complexidade + confirmação
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
            buildInput(
              nameController,
              'Nome completo',
              inputFormatters: [_NomeFormatter()],
            ),
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
                final pwd = value.text;
                final hasLength = pwd.length >= 8;
                final hasUpper = pwd.contains(RegExp(r'[A-Z]'));
                final hasLower = pwd.contains(RegExp(r'[a-z]'));
                final hasDigit = pwd.contains(RegExp(r'\d'));
                final allMet = hasLength && hasUpper && hasLower && hasDigit;
                if (allMet) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _PasswordRequirement('8 ou mais caracteres', hasLength),
                      _PasswordRequirement('Uma letra maiúscula', hasUpper),
                      _PasswordRequirement('Uma letra minúscula', hasLower),
                      _PasswordRequirement('Um número', hasDigit),
                    ],
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
        hintStyle: TextStyle(color: AppColors.cinza400),
        counterText: '',
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.cinza400, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: AppColors.azul, width: 2),
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

    // Remove as máscaras antes de enviar para o backend.
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
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.verde.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mark_email_read_outlined, color: AppColors.verde, size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Conta criada!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enviamos um e-mail de verificação para ${emailController.text}. Confirme seu e-mail para ativar sua conta.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'JosefinSans',
                  fontSize: 14,
                  color: AppColors.cinza700,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: AppColors.branco,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('OK', style: TextStyle(fontFamily: 'JosefinSans', fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      );
      if (mounted) Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Erro ao registrar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.preto),
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
                style: TextStyle(fontSize: 20, color: AppColors.cinza500, fontFamily: 'JosefinSans'),
              ),

              const SizedBox(height: 30),

              buildStepContent(),

              const SizedBox(height: 20),

              if (errorText.isNotEmpty)
                Text(errorText, style: const TextStyle(color: AppColors.vermelho)),

              const SizedBox(height: 40),

              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: isLoading ? null : nextStep,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.azul,
                    foregroundColor: AppColors.branco,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: AppColors.azul800, width: 0.25),
                    ),
                    elevation: 6,
                    shadowColor: AppColors.azul.withValues(alpha: 0.4),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.branco),
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

// Formatadores de input: aplicam máscara em tempo real enquanto o usuário digita.
// _NomeFormatter: bloqueia números e caracteres especiais no campo de nome.
class _NomeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = newValue.text.replaceAll(
      RegExp(r'[^a-zA-ZÀ-ÿ\s]'),
      '',
    );
    return newValue.copyWith(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}

// _RgFormatter: aplica máscara XX.XXX.XXX-X conforme o usuário digita.
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

// _PhoneFormatter: aplica máscara (XX) XXXXX-XXXX conforme o usuário digita.
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

class _PasswordRequirement extends StatelessWidget {
  final String label;
  final bool met;

  const _PasswordRequirement(this.label, this.met);

  @override
  Widget build(BuildContext context) {
    final color = met ? AppColors.verde : AppColors.vermelho;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 15,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
