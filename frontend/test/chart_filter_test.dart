import 'package:flutter_test/flutter_test.dart';

class PricePoint {
  final DateTime createdAt;
  final double price;

  const PricePoint({required this.createdAt, required this.price});
}

// Filtra pontos das ultimas 24 horas com base em um horario de referencia.
List<PricePoint> filterLast24Hours(List<PricePoint> points, DateTime now) {
  final start = now.subtract(const Duration(hours: 24));
  return points.where((p) => p.createdAt.isAfter(start)).toList();
}

// Filtra pontos dos ultimos 7 dias com base em um horario de referencia.
List<PricePoint> filterLast7Days(List<PricePoint> points, DateTime now) {
  final start = now.subtract(const Duration(days: 7));
  return points.where((p) => p.createdAt.isAfter(start)).toList();
}

// Filtra pontos dos ultimos 30 dias com base em um horario de referencia.
List<PricePoint> filterLast30Days(List<PricePoint> points, DateTime now) {
  final start = now.subtract(const Duration(days: 30));
  return points.where((p) => p.createdAt.isAfter(start)).toList();
}

void main() {
  group('Chart filter rules', () {
    final now = DateTime(2026, 5, 31, 12, 0);

    // Lista simulada com pontos em varias datas para testar os filtros.
    final points = <PricePoint>[
      PricePoint(createdAt: now.subtract(const Duration(hours: 6)), price: 10.2),
      PricePoint(createdAt: now.subtract(const Duration(hours: 25)), price: 10.1),
      PricePoint(createdAt: now.subtract(const Duration(days: 3)), price: 10.5),
      PricePoint(createdAt: now.subtract(const Duration(days: 8)), price: 9.9),
      PricePoint(createdAt: now.subtract(const Duration(days: 20)), price: 11.0),
      PricePoint(createdAt: now.subtract(const Duration(days: 40)), price: 8.7),
    ];

    test('filtro 24h deve retornar apenas pontos das ultimas 24 horas', () {
      // Esperado: somente o ponto de 6 horas atras.
      final filtered = filterLast24Hours(points, now);

      expect(filtered.length, 1);
      expect(filtered.first.price, 10.2);
    });

    test('filtro 7D deve retornar apenas pontos dos ultimos 7 dias', () {
      // Esperado: pontos de 6h, 25h e 3 dias.
      final filtered = filterLast7Days(points, now);

      expect(filtered.length, 3);
      expect(filtered.map((p) => p.price), containsAll(<double>[10.2, 10.1, 10.5]));
    });

    test('filtro 30D deve retornar apenas pontos dos ultimos 30 dias', () {
      // Esperado: todos menos o ponto de 40 dias.
      final filtered = filterLast30Days(points, now);

      expect(filtered.length, 5);
      expect(filtered.map((p) => p.price), isNot(contains(8.7)));
    });

    test('lista vazia deve continuar vazia no filtro 24h', () {
      // Sem dados, o resultado deve continuar vazio.
      expect(filterLast24Hours(const <PricePoint>[], now), isEmpty);
    });

    test('lista vazia deve continuar vazia no filtro 7D', () {
      // Sem dados, o resultado deve continuar vazio.
      expect(filterLast7Days(const <PricePoint>[], now), isEmpty);
    });

    test('lista vazia deve continuar vazia no filtro 30D', () {
      // Sem dados, o resultado deve continuar vazio.
      expect(filterLast30Days(const <PricePoint>[], now), isEmpty);
    });
  });
}
