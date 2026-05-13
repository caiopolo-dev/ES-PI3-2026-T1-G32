// Autor: Gustavo Alves de Siqueira Costa
// Data: 12/05/2026
// Descrição: Indicador de carregamento centralizado — reutilizado em todas as telas

import 'package:flutter/material.dart';
import 'package:mescla_invest/src/theme/app_colors.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: AppColors.azul));
}
