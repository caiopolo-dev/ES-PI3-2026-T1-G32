// Autor: Henrique Leite de Camargo 25005997
// Data: 06/05/2026
// Descrição: Tela de verificação do código 2FA no login

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mescla_invest/src/pages/catalog_page.dart';

class TwoFactorVerifyPage extends StatefulWidget {
  final MultiFactorResolver resolver;
  final Map<String, dynamic>? usuario;

  const TwoFactorVerifyPage({
    super.key,
    required this.resolver,
    this.usuario,
  });

  @override
  State<TwoFactorVerifyPage> createState() => _TwoFactorVerifyPageState();
}

class _TwoFactorVerifyPageState extends State<TwoFactorVerifyPage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String _errorText = '';

  Future<void> _verify() async {
    if (_codeController.text.length != 6) {
      setState(() => _errorText = 'Digite o código de 6 dígitos');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorText = '';
    });

    try {
      final assertion = await TotpMultiFactorGenerator.getAssertionForSignIn(
        widget.resolver.hints.first.uid,
        _codeController.text,
      );

      await widget.resolver.resolveSignIn(assertion);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InitialCatalogPage(usuario: widget.usuario),
        ),
      );
    } catch (e) {
      setState(() {
        _errorText = 'Código inválido. Tente novamente.';
        _isVerifying = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
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
                      Center(
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: Image.asset('assets/MesclaLogoPequena.png'),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Verificação em duas etapas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'JosefinSans',
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Digite o código gerado pelo seu app autenticador',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          fontFamily: 'JosefinSans',
                        ),
                      ),

                      const SizedBox(height: 32),

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
                          style: const TextStyle(
                            color: Colors.red,
                            fontFamily: 'JosefinSans',
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _verify,
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
                          'Verificar',
                          style: TextStyle(fontFamily: 'JosefinSans', fontSize: 22),
                        ),
                ),
              ),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
