// Autor: Gustavo Costa
// Data: 17/04/2026
// Descrição: Tela de cadastro multi-etapas com validação

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/auth_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';
import 'package:mescla_invest/src/pages/public/auth/registration_widgets.dart';

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

  @override
  void dispose() {
    nameController.dispose();
    rgController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // Passo 0: Nome + RG | Passo 1: Email + Telefone | Passo 2: Senha
  static const List<String> _stepTitles = [
    'Dados pessoais',
    'Contato',
    'Senha',
  ];

  // Valida os campos do passo atual antes de avançar.
  bool validateStep() {
    setState(() => errorText = '');

    switch (currentStep) {
      case 0:
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

      case 1:
        if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
            .hasMatch(emailController.text)) {
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
            RegisterInput(
              controller: nameController,
              hint: 'Nome completo',
              inputFormatters: [NomeFormatter()],
            ),
            const SizedBox(height: 20),
            RegisterInput(
              controller: rgController,
              hint: 'RG',
              keyboardType: TextInputType.number,
              inputFormatters: [RgFormatter()],
            ),
          ],
        );
      case 1:
        return Column(
          children: [
            RegisterInput(controller: emailController, hint: 'Email'),
            const SizedBox(height: 20),
            RegisterInput(
              controller: phoneController,
              hint: 'Celular',
              keyboardType: TextInputType.phone,
              inputFormatters: [PhoneFormatter()],
            ),
          ],
        );
      case 2:
        return Column(
          children: [
            RegisterInput(controller: passwordController, hint: 'Senha', obscure: true),
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
                      PasswordRequirement('8 ou mais caracteres', hasLength),
                      PasswordRequirement('Uma letra maiúscula', hasUpper),
                      PasswordRequirement('Uma letra minúscula', hasLower),
                      PasswordRequirement('Um número', hasDigit),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            RegisterInput(
              controller: confirmPasswordController,
              hint: 'Confirme a senha',
              obscure: true,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
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
                child: const Icon(Icons.mark_email_read_outlined,
                    color: AppColors.verde, size: 40),
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
                child: AppPrimaryButton(
                  label: 'OK',
                  onPressed: () => Navigator.pop(dialogContext),
                  verticalPadding: 12,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barras de progresso no topo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      left: i > 0 ? 4 : 0,
                      right: i < 2 ? 4 : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= currentStep ? AppColors.azul : AppColors.cinza200,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),

            // Conteúdo centralizado verticalmente
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset('assets/MesclaLogoPequena.png'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _stepTitles[currentStep],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'JosefinSans',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Passo ${currentStep + 1} de 3',
                      style: const TextStyle(
                        fontSize: 18,
                        color: AppColors.cinza500,
                        fontFamily: 'JosefinSans',
                      ),
                    ),
                    const SizedBox(height: 36),
                    buildStepContent(),
                    const SizedBox(height: 12),
                    if (errorText.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 14, color: AppColors.vermelho),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              errorText,
                              style: const TextStyle(
                                color: AppColors.vermelho,
                                fontFamily: 'JosefinSans',
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            // Botão fixo na parte inferior
            Center(
              child: SizedBox(
                width: 260,
                child: AppPrimaryButton(
                  label: currentStep == 2 ? 'Finalizar' : 'Continuar',
                  onPressed: nextStep,
                  isLoading: isLoading,
                  elevated: true,
                  verticalPadding: 14,
                ),
              ),
            ),
            const SizedBox(height: 126),
          ],
        ),
      ),
    );
  }
}
