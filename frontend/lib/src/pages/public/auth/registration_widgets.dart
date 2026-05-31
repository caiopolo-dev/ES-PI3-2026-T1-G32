// Autor: Gustavo Alves de Siqueira Costa
// Data: 29/05/2026
// Descrição: Widgets, formatadores e validadores do cadastro multi-etapas

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class RegisterInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  const RegisterInput({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) => TextField(
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

  // `RegisterInput` é um wrapper leve em torno de `TextField` usado no fluxo
  // de registro para centralizar estilos e máscaras. Mantém-se simples para
  // permitir reutilização entre os passos do cadastro.

class PasswordRequirement extends StatelessWidget {
  final String label;
  final bool met;

  const PasswordRequirement(this.label, this.met, {super.key});

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

// `PasswordRequirement` mostra requisito de senha com ícone e cor.
// Usado para feedback visual imediato enquanto o usuário digita.

// NomeFormatter: bloqueia números e caracteres especiais no campo de nome.
class NomeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final sanitized = newValue.text.replaceAll(RegExp(r'[^a-zA-ZÀ-ÿ\s]'), '');
    return newValue.copyWith(
      text: sanitized,
      selection: TextSelection.collapsed(offset: sanitized.length),
    );
  }
}

// O `NomeFormatter` garante que apenas letras (incluindo acentos) e espaços
// permaneçam, evitando que usuários insiram números ou símbolos no nome.

// RgFormatter: aplica máscara XX.XXX.XXX-X conforme o usuário digita.
class RgFormatter extends TextInputFormatter {
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

// `RgFormatter` aplica máscara progressiva e limita a 9 dígitos, retornando
// ao valor anterior quando o usuário excede o limite, prevenindo entradas
// inválidas.

// PhoneFormatter: aplica máscara (XX) XXXXX-XXXX conforme o usuário digita.
class PhoneFormatter extends TextInputFormatter {
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

// `PhoneFormatter` formata DDD + número móvel (11 dígitos) conforme a digitação
// e protege contra maiores entradas.
