// Teste automatizado (smoke test) da aplicação Clínica Pet.
//
// Verifica que a tela de lista é exibida com os registros iniciais em memória
// e que a navegação para a tela de formulário funciona.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:clinica_pet/main.dart';
import 'package:clinica_pet/models/pet.dart';

void main() {
  testWidgets('Exibe a tela de lista com os registros iniciais', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClinicaPetApp());

    final NumberFormat formatador = NumberFormat.currency(
      locale: 'pt_BR',
      symbol: r'R$',
      decimalDigits: 2,
    );

    expect(find.text('Clínica Pet'), findsOneWidget);
    expect(find.text('Thor'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Atendimento #1 • Cão'), findsOneWidget);

    // O valor monetário é exibido no padrão brasileiro (R$ 180,00).
    expect(find.text(formatador.format(180.00)), findsOneWidget);
    expect(find.text(formatador.format(120.50)), findsOneWidget);
    expect(find.textContaining(RegExp(r'R\$\s180,00')), findsOneWidget);
    expect(find.textContaining(RegExp(r'R\$\s120,50')), findsOneWidget);
  });

  testWidgets('Abre o formulário e cria o pet devolvido à lista', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ClinicaPetApp());

    await tester.tap(find.text('Novo pet'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar atendimento'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '3');
    await tester.enterText(find.byType(TextFormField).at(1), 'Bidu');
    await tester.enterText(find.byType(TextFormField).at(2), 'Cão');
    await tester.enterText(find.byType(TextFormField).at(3), '95.90');

    await tester.tap(find.text('Salvar atendimento'));
    await tester.pump(); // Navigator.pop
    await tester.pump(const Duration(seconds: 2)); // Future.delayed + setState

    expect(find.text('Bidu'), findsOneWidget);
    expect(find.text('Atendimento #3 • Cão'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'R\$\s95,90')),
      findsOneWidget,
    );
  });

  test('O modelo Pet é formatado no toString()', () {
    const Pet pet = Pet(id: 9, nome: 'Luna', especie: 'Gato', valor: 210.75);
    expect(
      pet.toString(),
      'Pet(id: 9, nome: Luna, especie: Gato, valor: 210.75)',
    );
  });
}
