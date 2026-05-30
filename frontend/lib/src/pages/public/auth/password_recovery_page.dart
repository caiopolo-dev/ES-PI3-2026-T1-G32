// Autor: Caio Ferreira Polo
// Descrição: Tela de recuperação de senha por e-mail

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';
import 'package:mescla_invest/src/services/auth_service.dart';
import 'package:mescla_invest/src/widgets/widgets.dart';

class PasswordRecoveryPage extends StatefulWidget {
  const PasswordRecoveryPage({super.key});

  @override
  State<PasswordRecoveryPage> createState() => _PasswordRecoveryPageState();
}

class _PasswordRecoveryPageState extends State<PasswordRecoveryPage> {
  final TextEditingController emailController = TextEditingController();

  String errorText = '';
  bool isLoading = false;

  // Validação local com regex completa antes de qualquer chamada de rede.
  // Regex mais rigorosa que a do auth_service para evitar requisição com e-mail claramente inválido.
  bool validateEmail() {
    // Limpa erro anterior antes de revalidar.
    setState(() => errorText = '');

    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$').hasMatch(emailController.text)) {
      errorText = 'Digite um email válido';
      return false;
    }

    return true;
  }

  // Fluxo de recuperação:
  // 1. Valida o e-mail localmente
  // 2. Chama AuthService que: verifica existência no Firestore, depois aciona Firebase
  // 3. Se bem-sucedido, exibe snackbar e retorna à tela anterior
  // 4. Se falhar (e-mail não cadastrado, etc.), exibe a mensagem de erro na tela
  Future<void> sendRecoveryEmail() async {
    // Aborta se a validação local falhar — evita requisição desnecessária.
    if (!validateEmail()) return;

    // Ativa o indicador de carregamento e limpa qualquer erro residual.
    setState(() { isLoading = true; errorText = ''; });

    final result = await AuthService.sendPasswordReset(email: emailController.text);

    // Após await, o widget pode ter sido destruído — não usar context sem verificar.
    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] as bool) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('E-mail de recuperação enviado com sucesso'),
          backgroundColor: AppColors.verde,
          duration: Duration(seconds: 3),
        ),
      );
      // Retorna à tela de login após o envio bem-sucedido.
      Navigator.pop(context);
    } else {
      // Exibe a mensagem de erro retornada pelo AuthService (ex: "Nenhuma conta encontrada").
      setState(() => errorText = result['message'] as String? ?? 'Erro ao enviar e-mail');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.branco,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.branco,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.preto),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.08),

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
                    color: AppColors.preto54,
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
                    hintStyle: TextStyle(color: AppColors.cinza400),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.cinza400),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppColors.azul, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Erro
                if (errorText.isNotEmpty)
                  Text(
                    errorText,
                    style: const TextStyle(color: AppColors.vermelho),
                  ),

                const SizedBox(height: 40),

                // Botão Enviar Email
                SizedBox(
                  width: 260,
                  child: AppPrimaryButton(
                    label: 'Enviar Email',
                    onPressed: sendRecoveryEmail,
                    elevated: true,
                    verticalPadding: 14,
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 24),
              ],
            ),
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
