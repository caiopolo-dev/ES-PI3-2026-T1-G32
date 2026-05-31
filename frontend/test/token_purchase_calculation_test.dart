import 'package:flutter_test/flutter_test.dart';

// Calcula o valor total da compra em centavos.
int calculatePurchaseTotalCents({
  required int tokenPriceCents,
  required int quantity,
}) {
  return tokenPriceCents * quantity;
}

// Calcula o saldo restante após concluir a compra.
int calculateNewBalanceAfterPurchase({
  required int currentBalanceCents,
  required int purchaseTotalCents,
}) {
  return currentBalanceCents - purchaseTotalCents;
}

// Regra simples para validar quantidade de tokens.
bool isValidQuantity(int quantity) => quantity > 0;

// Regra simples para validar se a compra pode acontecer.
bool canPurchase({
  required int currentBalanceCents,
  required int tokenPriceCents,
  required int quantity,
}) {
  if (!isValidQuantity(quantity)) return false;

  final total = calculatePurchaseTotalCents(
    tokenPriceCents: tokenPriceCents,
    quantity: quantity,
  );

  return currentBalanceCents >= total;
}

void main() {
  group('Token purchase calculation', () {
    test('deve calcular o total da compra: preco x quantidade', () {
      // 2.500 centavos (R\$ 25,00) x 3 tokens = 7.500 centavos.
      final total = calculatePurchaseTotalCents(
        tokenPriceCents: 2500,
        quantity: 3,
      );

      expect(total, 7500);
    });

    test('deve calcular o novo saldo apos compra', () {
      // Saldo de 10.000 menos compra de 3.000 deve resultar em 7.000.
      final newBalance = calculateNewBalanceAfterPurchase(
        currentBalanceCents: 10000,
        purchaseTotalCents: 3000,
      );

      expect(newBalance, 7000);
    });

    test('deve validar compra com saldo suficiente', () {
      // Saldo cobre o total da compra.
      final isValid = canPurchase(
        currentBalanceCents: 10000,
        tokenPriceCents: 2000,
        quantity: 5,
      );

      expect(isValid, isTrue);
    });

    test('deve invalidar compra com saldo insuficiente', () {
      // Saldo nao cobre o total da compra.
      final isValid = canPurchase(
        currentBalanceCents: 5000,
        tokenPriceCents: 2000,
        quantity: 3,
      );

      expect(isValid, isFalse);
    });

    test('deve invalidar compra com quantidade zero', () {
      // Quantidade zero nao pode ser aceita.
      final isValid = canPurchase(
        currentBalanceCents: 5000,
        tokenPriceCents: 1000,
        quantity: 0,
      );

      expect(isValid, isFalse);
    });

    test('deve invalidar compra com quantidade negativa', () {
      // Quantidade negativa tambem deve ser bloqueada.
      final isValid = canPurchase(
        currentBalanceCents: 5000,
        tokenPriceCents: 1000,
        quantity: -2,
      );

      expect(isValid, isFalse);
    });
  });
}
