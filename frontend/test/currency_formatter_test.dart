import 'package:flutter_test/flutter_test.dart';
import 'package:mescla_invest/src/utils/currency_formatter.dart';

void main() {
	group('CurrencyFormatter.formatCents', () {
		test('deve formatar zero como moeda com centavos', () {
			// Cenário básico: zero reais e zero centavos.
			expect(CurrencyFormatter.formatCents(0), '0,00');
		});

		test('deve formatar valor inteiro em reais', () {
			// Cenário com valor inteiro, sem centavos.
			expect(CurrencyFormatter.formatCents(1000), '10,00');
		});

		test('deve formatar valor com centavos', () {
			// Cenário com centavos diferentes de zero.
			expect(CurrencyFormatter.formatCents(1234), '12,34');
		});

		test('deve formatar valor alto com separador de milhar', () {
			// Cenário com número grande para validar separador de milhar.
			expect(CurrencyFormatter.formatCents(5000000), '50.000,00');
		});

		test('deve tratar valor negativo como zero', () {
			// O formatter limita valores negativos para zero.
			expect(CurrencyFormatter.formatCents(-150), '0,00');
		});
	});
}
