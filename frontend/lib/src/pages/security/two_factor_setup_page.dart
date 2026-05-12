// Autor: Henrique Leite de Camargo 25005997
// Data: 06/05/2026
// Descrição: Tela de configuração do 2FA via TOTP

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mescla_invest/src/services/two_factor_service.dart';

class TwoFactorSetupPage extends StatefulWidget {
  const TwoFactorSetupPage({super.key});

  @override
  State<TwoFactorSetupPage> createState() => _TwoFactorSetupPageState();
}

class _TwoFactorSetupPageState extends State<TwoFactorSetupPage> {
  final TextEditingController _codeController = TextEditingController();
  // Controller separado para o campo de senha no dialog de reautenticação.
  final TextEditingController _passwordController = TextEditingController();
  String? _qrCodeUrl;
  TotpSecret? _totpSecret;
  bool _isLoading = true;
  bool _isVerifying = false;
  String _errorText = '';

  @override
  void initState() {
    super.initState();
    _initTotp();
  }

  // Gera o segredo TOTP e a URL do QR Code para o usuário escanear no autenticador.
  // Se o Firebase rejeitar por token antigo (requires-recent-login), abre o
  // dialog de reautenticação antes de tentar de novo.
  Future<void> _initTotp() async {
    final result = await TwoFactorService.generateSetup();

    // Widget pode ter sido descartado durante o await (usuário voltou).
    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        // URL no formato otpauth://totp/... — usada para gerar o QR Code.
        _qrCodeUrl = result['qrCodeUrl'] as String;
        // TotpSecret é o objeto do SDK do Firebase necessário para o enrollment.
        _totpSecret = result['secret'] as TotpSecret;
        _isLoading = false;
      });
    } else if (result['requiresReauth'] == true) {
      // Token do usuário está antigo — Firebase exige autenticação recente
      // antes de operações sensíveis como enrollment de MFA.
      await _showReauthDialog();
    } else {
      setState(() {
        _errorText = result['message'] as String? ?? 'Erro ao gerar QR Code';
        _isLoading = false;
      });
    }
  }

  // Exibe um dialog pedindo a senha do usuário para reautenticar.
  // Após reautenticação bem-sucedida, reinicia o fluxo de setup do TOTP.
  Future<void> _showReauthDialog() async {
    _passwordController.clear();
    String dialogError = '';

    // Retorna true se o usuário confirmou a senha com sucesso, false/null se voltou.
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            title: const Text(
              'Confirme sua senha',
              style: TextStyle(fontFamily: 'JosefinSans'),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Por segurança, confirme sua senha para continuar.',
                  style: TextStyle(fontFamily: 'JosefinSans', fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      labelStyle: TextStyle(fontFamily: 'JosefinSans'),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                if (dialogError.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    dialogError,
                    style: const TextStyle(
                      color: Colors.red,
                      fontFamily: 'JosefinSans',
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                // Volta para a tela anterior sem tentar ativar o 2FA.
                onPressed: () => Navigator.pop(context, false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey.shade600,
                ),
                child: const Text(
                  'Voltar',
                  style: TextStyle(fontFamily: 'JosefinSans'),
                ),
              ),
              TextButton(
                onPressed: () async {
                  final email =
                      FirebaseAuth.instance.currentUser?.email ?? '';
                  final reauth = await TwoFactorService.reauthenticate(
                    email,
                    _passwordController.text,
                  );

                  if (reauth['success'] == true) {
                    // Fecha o dialog sinalizando sucesso para retomar o setup.
                    if (context.mounted) Navigator.pop(context, true);
                  } else {
                    setDialogState(() {
                      dialogError =
                          reauth['message'] as String? ?? 'Erro ao autenticar';
                    });
                  }
                },
                child: const Text(
                  'Confirmar',
                  style: TextStyle(
                    fontFamily: 'JosefinSans',
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (!mounted) return;

    if (confirmed == true) {
      // Reautenticou com sucesso — tenta gerar o QR Code de novo.
      await _initTotp();
    } else {
      // Usuário voltou — fecha a tela de setup e retorna à tela anterior.
      Navigator.pop(context, false);
    }
  }

  // Verifica o código TOTP digitado e, se válido, vincula o autenticador à conta.
  // Fluxo:
  // 1. Valida que o código tem exatamente 6 dígitos
  // 2. Chama enrollTotp com o segredo gerado em _initTotp e o código digitado
  // 3. O Firebase valida o código contra o segredo — se correto, registra o fator
  // 4. Retorna `true` via Navigator.pop para o ProfilePage atualizar o toggle do 2FA
  Future<void> _verifyAndEnable() async {
    // Código TOTP tem sempre 6 dígitos — rejeita antes de chamar o Firebase.
    if (_codeController.text.length != 6) {
      setState(() => _errorText = 'Digite o código de 6 dígitos');
      return;
    }

    setState(() {
      _isVerifying = true;
      // Limpa erro anterior enquanto aguarda resposta do Firebase.
      _errorText = '';
    });

    // _totpSecret! é seguro aqui: _verifyAndEnable só é chamado quando
    // _isLoading == false, o que só ocorre após _initTotp preencher _totpSecret.
    final result = await TwoFactorService.enrollTotp(
      _totpSecret!,
      _codeController.text,
    );

    // Verifica montagem após o await para evitar setState em widget destruído.
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('2FA ativado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
      // Retorna `true` para que ProfilePage saiba que o 2FA foi ativado
      // e possa atualizar o estado do toggle na tela de perfil.
      Navigator.pop(context, true);
    } else {
      setState(() {
        _errorText = result['message'] as String? ?? 'Código inválido.';
        // Reabilita o botão para o usuário tentar novamente.
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: const Text(
          'Ativar 2FA',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'JosefinSans',
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    const SizedBox(height: 24),

                    const Text(
                      '1. Abra o Google Authenticator ou outro app autenticador',
                      style: TextStyle(fontFamily: 'JosefinSans', fontSize: 14),
                    ),

                    const SizedBox(height: 8),

                    const Text(
                      '2. Escaneie o QR Code abaixo',
                      style: TextStyle(fontFamily: 'JosefinSans', fontSize: 14),
                    ),

                    const SizedBox(height: 24),

                    if (_qrCodeUrl != null) ...[
                      Center(
                        child: QrImageView(
                          data: _qrCodeUrl!,
                          version: QrVersions.auto,
                          size: 220,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Center(
                        child: TextButton(
                          onPressed: () => launchUrl(
                            Uri.parse(_qrCodeUrl!),
                            mode: LaunchMode.externalApplication,
                          ),
                          child: const Text(
                            'Não consigo escanear — abrir link',
                            style: TextStyle(
                              fontFamily: 'JosefinSans',
                              fontSize: 13,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    const Text(
                      '3. Digite o código de 6 dígitos gerado pelo app',
                      style: TextStyle(fontFamily: 'JosefinSans', fontSize: 14),
                    ),

                    const SizedBox(height: 16),

                    TextField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(
                        fontSize: 24,
                        fontFamily: 'JosefinSans',
                        letterSpacing: 8,
                      ),
                      decoration: const InputDecoration(
                        hintText: '000000',
                        hintStyle: TextStyle(color: Colors.black26),
                        counterText: '',
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF013593), width: 2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_errorText.isNotEmpty)
                      Text(
                        _errorText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontFamily: 'JosefinSans'),
                      ),

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyAndEnable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          elevation: 6,
                          shadowColor: Colors.blue.withValues(alpha: 0.4),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Confirmar e ativar',
                                style: TextStyle(fontFamily: 'JosefinSans', fontSize: 18),
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