// Autor: Gustavo Alves de Siqueira Costa
// Data: 17/05/2026
// Descrição: Paleta de cores do app — fonte única de verdade para todas as cores

import 'dart:ui';

class AppColors {
  AppColors._();

  // Azul da marca — botões primários, bordas de foco e destaques
  static const Color azul = Color(0xFF013593);

  // Azul 800 — borda sutil dos botões primários
  static const Color azul800 = Color(0xFF1565C0);

  // Azul 200 — track ativo do Switch
  static const Color azul200 = Color(0xFF90CAF9);

  // Azul noite — gradientes e elementos secundários
  static const Color azulNoite = Color(0xFF30476B);

  // Branco puro — fundos de tela, texto sobre fundo escuro
  static const Color branco = Color(0xFFFFFFFF);
  static const Color branco54 = Color(0x8AFFFFFF);

  // Preto puro — ícones e textos sobre fundo branco
  static const Color preto = Color(0xFF000000);
  static const Color preto87 = Color(0xDD000000);
  static const Color preto54 = Color(0x8A000000);

  // Transparente — desativa surface tint do Material 3
  static const Color transparente = Color(0x00000000);

  // Cinza 100 — fundo da maioria das telas
  static const Color cinza100 = Color(0xFFF5F5F5);

  // Cinza 200 — separadores, cards e campos de busca
  static const Color cinza200 = Color(0xFFEEEEEE);

  // Cinza 300 — fundo de campos de input
  static const Color cinza300 = Color(0xFFE0E0E0);

  // Cinza 400 — bordas, chips não selecionados e textos de estado vazio
  static const Color cinza400 = Color(0xFFBDBDBD);

  // Cinza 500 — ícones inativos, thumb de switch desativado
  static const Color cinza500 = Color(0xFF9E9E9E);

  // Cinza 700 — textos secundários, legendas e placeholders
  static const Color cinza700 = Color(0xFF555555);

  // Verde — confirmações e sucesso
  static const Color verde = Color(0xFF4CAF50);

  // Vermelho — erros e alertas críticos
  static const Color vermelho = Color(0xFFF44336);

  // Laranja — avisos
  static const Color laranja = Color(0xFFFF9800);

  // Amarelo — ordens em aberto / pendentes
  static const Color amarelo = Color(0xFFFFB300);
}
