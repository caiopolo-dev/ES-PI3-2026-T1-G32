import 'package:flutter_test/flutter_test.dart';

// Calcula a variacao percentual entre preco antigo e novo.
double calculateVariationPercent({
  required double oldPrice,
  required double newPrice,
}) {
  // Evita divisao por zero quando o preco antigo for invalido.
  if (oldPrice <= 0) return 0.0;

  return ((newPrice - oldPrice) / oldPrice) * 100;
}

void main() {
  group('Variation calculation', () {
    test('deve calcular valorizacao positiva', () {
      // De 10 para 12: variacao esperada de +20%.
      final variation = calculateVariationPercent(oldPrice: 10, newPrice: 12);

      expect(variation, 20.0);
    });

    test('deve calcular desvalorizacao negativa', () {
      // De 10 para 8: variacao esperada de -20%.
      final variation = calculateVariationPercent(oldPrice: 10, newPrice: 8);

      expect(variation, -20.0);
    });

    test('deve retornar zero quando preco antigo e novo forem iguais', () {
      // Sem mudanca de preco, variacao deve ser 0%.
      final variation = calculateVariationPercent(oldPrice: 10, newPrice: 10);

      expect(variation, 0.0);
    });

    test('deve tratar preco antigo zero sem dividir por zero', () {
      // Regra de seguranca: retorna 0 quando oldPrice for zero.
      final variation = calculateVariationPercent(oldPrice: 0, newPrice: 10);

      expect(variation, 0.0);
    });
  });
}
