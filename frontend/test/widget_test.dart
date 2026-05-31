import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mescla_invest/main.dart';

void main() {
  testWidgets('smoke test da tela inicial do app', (WidgetTester tester) async {
    // Monta o app principal sem executar o bootstrap real do Firebase.
    await tester.pumpWidget(const MyApp());

    // Verifica se a estrutura principal foi renderizada.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('MesclaInvest'), findsOneWidget);
    expect(find.text('Onde grandes ideias ganham fôlego.'), findsOneWidget);

    // Verifica se os botões principais da tela inicial aparecem.
    expect(find.text('Abrir conta'), findsOneWidget);
    expect(find.text('Já tenho conta'), findsOneWidget);
  });
}
