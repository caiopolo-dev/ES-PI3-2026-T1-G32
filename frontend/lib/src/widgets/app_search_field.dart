// Autor: Gustavo Alves de Siqueira Costa
// Data: 21/05/2026
// Descrição: Campo de busca reutilizável com ícone e botão de limpar

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class AppSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  const AppSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'JosefinSans',
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              fontFamily: 'JosefinSans',
              fontSize: 14,
              color: AppColors.cinza500,
            ),
            prefixIcon: const Icon(
              Icons.search,
              color: AppColors.cinza500,
              size: 20,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: AppColors.cinza500,
                    ),
                    onPressed: () {
                      controller.clear();
                      onChanged?.call('');
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.cinza200,
            contentPadding: const EdgeInsets.symmetric(
              vertical: 0,
              horizontal: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}
