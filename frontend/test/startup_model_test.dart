import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> readStartupSummary(Map<String, dynamic> data) {
	// Como não existe model de Startup no frontend, este helper simula a leitura
	// segura dos campos que a tela usa ao receber dados do Firebase.
	return {
		'id': data['id']?.toString() ?? '',
		'nome': data['nome']?.toString() ?? '',
		'descricao': data['descricao']?.toString() ?? '',
		'precoToken': (data['precoToken'] as num?)?.toInt() ?? 0,
		'totalTokens': (data['totalTokens'] as num?)?.toInt() ?? 0,
		'variacaoHojePercentual': (data['variacaoHojePercentual'] as num?)?.toDouble() ?? 0.0,
		'priceHistory': List<Map<String, dynamic>>.from(data['priceHistory'] ?? const []),
	};
}

void main() {
	group('Leitura de dados de startup', () {
		test('deve ler campos principais de um mapa de startup', () {
			// Simula uma startup vinda do Firebase com os campos principais.
			final raw = <String, dynamic>{
				'id': 'startup-001',
				'nome': 'Mescla Invest',
				'descricao': 'Startup de teste para o projeto',
				'precoToken': 1250,
				'totalTokens': 100000,
				'variacaoHojePercentual': 2.75,
				'priceHistory': [
					{'createdAt': '2026-05-25T10:00:00.000Z', 'price': 1200},
				],
			};

			final startup = readStartupSummary(raw);

			expect(startup['id'], 'startup-001');
			expect(startup['nome'], 'Mescla Invest');
			expect(startup['descricao'], 'Startup de teste para o projeto');
			expect(startup['precoToken'], 1250);
			expect(startup['totalTokens'], 100000);
			expect(startup['variacaoHojePercentual'], 2.75);
			expect((startup['priceHistory'] as List).length, 1);
		});

		test('deve tratar campos ausentes de forma segura', () {
			// Simula um mapa incompleto para validar valores padrão.
			final startup = readStartupSummary(<String, dynamic>{});

			expect(startup['id'], '');
			expect(startup['nome'], '');
			expect(startup['descricao'], '');
			expect(startup['precoToken'], 0);
			expect(startup['totalTokens'], 0);
			expect(startup['variacaoHojePercentual'], 0.0);
			expect((startup['priceHistory'] as List).isEmpty, isTrue);
		});

		test('deve ler histórico com mais de um registro', () {
			// Valida que a lista de histórico é preservada corretamente.
			final startup = readStartupSummary(<String, dynamic>{
				'priceHistory': [
					{'createdAt': '2026-05-25T10:00:00.000Z', 'price': 1200},
					{'createdAt': '2026-05-28T10:00:00.000Z', 'price': 1300},
				],
			});

			final history = startup['priceHistory'] as List<Map<String, dynamic>>;

			expect(history.length, 2);
			expect(history[0]['price'], 1200);
			expect(history[1]['price'], 1300);
		});
	});
}
