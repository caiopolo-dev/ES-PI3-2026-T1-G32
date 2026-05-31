import 'package:flutter_test/flutter_test.dart';

bool isValidQuantity(int quantity) {
	// Regra simples: quantidade precisa ser maior que zero.
	return quantity > 0;
}

bool isValidTokenPrice(int pricePerTokenCents) {
	// Regra simples: o preço do token também precisa ser maior que zero.
	return pricePerTokenCents > 0;
}

bool canBuyTokens({
	required int quantity,
	required int walletBalanceCents,
	required int pricePerTokenCents,
}) {
	// Compra válida exige quantidade, preço e saldo suficientes.
	if (!isValidQuantity(quantity)) return false;
	if (!isValidTokenPrice(pricePerTokenCents)) return false;
	return quantity * pricePerTokenCents <= walletBalanceCents;
}

void main() {
	group('Regras de validação de tokens', () {
		test('quantidade maior que zero deve ser válida', () {
			// Quantidade positiva é aceita.
			expect(isValidQuantity(1), isTrue);
		});

		test('quantidade igual a zero deve ser inválida', () {
			// Quantidade zero não pode passar.
			expect(isValidQuantity(0), isFalse);
		});

		test('quantidade negativa deve ser inválida', () {
			// Quantidade negativa também é rejeitada.
			expect(isValidQuantity(-3), isFalse);
		});

		test('saldo suficiente deve permitir compra', () {
			// O saldo cobre o valor total da compra.
			expect(
				canBuyTokens(
					quantity: 2,
					walletBalanceCents: 5000,
					pricePerTokenCents: 2000,
				),
				isTrue,
			);
		});

		test('saldo insuficiente deve impedir compra', () {
			// O saldo não cobre o total da operação.
			expect(
				canBuyTokens(
					quantity: 3,
					walletBalanceCents: 5000,
					pricePerTokenCents: 2000,
				),
				isFalse,
			);
		});

		test('preço do token maior que zero deve ser válido', () {
			// Preço positivo passa na regra.
			expect(isValidTokenPrice(1), isTrue);
		});

		test('preço do token zero deve ser inválido', () {
			// Preço zero não é permitido.
			expect(isValidTokenPrice(0), isFalse);
		});

		test('preço do token negativo deve ser inválido', () {
			// Preço negativo também não é permitido.
			expect(isValidTokenPrice(-100), isFalse);
		});
	});
}
