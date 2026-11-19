// Testes automatizados da aplicação Clínica Pet.
//
// A interface depende da camada Repository, que é injetada com um FAKE
// nestes testes — nenhum teste real executa SQL ou HTTP.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:clinica_pet/main.dart';
import 'package:clinica_pet/models/pet.dart';
import 'package:clinica_pet/repository/pet_repository.dart';
import 'package:clinica_pet/services/pet_api_service.dart';

/// Repositório fake: memoriza os cadastros e simula o comportamento
/// Offline-first (sincronizado conforme o modo configurado).
class RepositorioFake extends PetRepository {
  final List<Pet> registros;
  final bool apiDisponivel;
  int pendentesForcados;

  RepositorioFake({
    required this.registros,
    this.apiDisponivel = true,
    this.pendentesForcados = 0,
  });

  @override
  Future<List<Pet>> listar() async => List<Pet>.of(registros);

  @override
  Future<int> contarPendentes() async => pendentesForcados;

  @override
  Future<Pet> cadastrar(Pet pet) async {
    final Pet salvo = pet.copiarCom(sincronizado: apiDisponivel);
    registros.add(salvo);
    if (!salvo.sincronizado) {
      pendentesForcados++;
    }
    return salvo;
  }

  @override
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    final int antes = pendentesForcados;
    pendentesForcados = apiDisponivel ? 0 : pendentesForcados;
    for (int i = 0; i < registros.length; i++) {
      if (apiDisponivel) {
        registros[i] = registros[i].copiarCom(sincronizado: true);
      }
    }
    return ResultadoSincronizacao(
      enviados: apiDisponivel ? antes : 0,
      pendentesRestantes: pendentesForcados,
    );
  }
}

void main() {
  final NumberFormat formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );

  testWidgets('Exibe a tela de lista com os registros do repositório', (
    WidgetTester tester,
  ) async {
    final RepositorioFake repositorio = RepositorioFake(registros: <Pet>[
      Pet(id: 1, nome: 'Thor', especie: 'Cão', valor: 180.00,
          idLocal: 'uuid-1', idRemoto: 1, sincronizado: true),
      Pet(id: 2, nome: 'Mia', especie: 'Gato', valor: 120.50,
          idLocal: 'uuid-2', idRemoto: 2, sincronizado: true),
    ]);

    await tester.pumpWidget(ClinicaPetApp(repository: repositorio));
    await tester.pumpAndSettle();

    expect(find.text('Clínica Pet'), findsOneWidget);
    expect(find.text('Thor'), findsOneWidget);
    expect(find.text('Mia'), findsOneWidget);
    expect(find.text('Atendimento #1 • Cão'), findsOneWidget);

    // O valor monetário é exibido no padrão brasileiro (R$ 180,00).
    expect(find.textContaining(RegExp(r'R\$\s180,00')), findsOneWidget);
    expect(find.textContaining(RegExp(r'R\$\s120,50')), findsOneWidget);

    // Registros sincronizados exibem o indicador cloud_done.
    expect(find.byIcon(Icons.cloud_done), findsNWidgets(2));
  });

  testWidgets('Exibe banner e indicador para registros pendentes', (
    WidgetTester tester,
  ) async {
    final RepositorioFake repositorio = RepositorioFake(registros: <Pet>[
      Pet(id: 5, nome: 'Bidu', especie: 'Cão', valor: 95.90,
          idLocal: 'uuid-5', sincronizado: false),
    ], pendentesForcados: 1);

    await tester.pumpWidget(ClinicaPetApp(repository: repositorio));
    await tester.pumpAndSettle();

    expect(find.text('Bidu'), findsOneWidget);
    expect(
      find.textContaining(formatador.format(95.90)),
      findsNWidgets(2),
    ); // no item e no total do AppBar

    expect(
      find.textContaining('aguardando sincronização (1)'),
      findsOneWidget,
    );
    // O ícone cloud_upload aparece no banner e no item pendente.
    expect(find.byIcon(Icons.cloud_upload_outlined), findsNWidgets(2));
    expect(find.byTooltip('Sincronizar pendentes'), findsOneWidget);
  });

  testWidgets('Abre o formulário e cadastra o pet devolvido à lista', (
    WidgetTester tester,
  ) async {
    final RepositorioFake repositorio = RepositorioFake(registros: <Pet>[]);

    await tester.pumpWidget(ClinicaPetApp(repository: repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo pet'));
    await tester.pumpAndSettle();

    expect(find.text('Cadastrar atendimento'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), '3');
    await tester.enterText(find.byType(TextFormField).at(1), 'Bidu');
    await tester.enterText(find.byType(TextFormField).at(2), 'Cão');
    await tester.enterText(find.byType(TextFormField).at(3), '95.90');

    await tester.tap(find.text('Salvar atendimento'));
    await tester.pump(); // Navigator.pop
    await tester
        .pump(const Duration(seconds: 2)); // Future.delayed + setState

    expect(find.text('Bidu'), findsOneWidget);
    expect(find.text('Atendimento #3 • Cão'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'R\$\s95,90')),
      findsNWidgets(2),
    ); // no item e no total do AppBar
    // O cadastro chegou ao repositório fake.
    expect(repositorio.registros.length, 1);
    expect(repositorio.registros.first.sincronizado, isTrue);
  });

  testWidgets('Cadastro offline: registro salvo como pendente e banner exibido',
      (WidgetTester tester) async {
    final RepositorioFake repositorio = RepositorioFake(
      registros: <Pet>[],
      apiDisponivel: false,
    );

    await tester.pumpWidget(ClinicaPetApp(repository: repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Novo pet'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), '7');
    await tester.enterText(find.byType(TextFormField).at(1), 'Luna');
    await tester.enterText(find.byType(TextFormField).at(2), 'Gato');
    await tester.enterText(find.byType(TextFormField).at(3), '110,00');

    await tester.tap(find.text('Salvar atendimento'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    // Mensagem Offline-first correta (e não a de sucesso com a API).
    expect(
      find.textContaining('Sem conexão com o servidor'),
      findsOneWidget,
    );
    expect(repositorio.registros.first.sincronizado, isFalse);
    expect(repositorio.pendentesForcados, 1);
  });

  testWidgets('Sincronização manual envia os pendentes e exibe o resumo', (
    WidgetTester tester,
  ) async {
    final RepositorioFake repositorio = RepositorioFake(registros: <Pet>[
      Pet(id: 7, nome: 'Luna', especie: 'Gato', valor: 110.00,
          idLocal: 'uuid-7', sincronizado: false),
    ], pendentesForcados: 1);

    await tester.pumpWidget(ClinicaPetApp(repository: repositorio));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sincronizar pendentes'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Sincronização concluída. 1 registro(s) enviado(s)'),
      findsOneWidget,
    );
    expect(repositorio.pendentesForcados, 0);
  });

  test('O modelo Pet é formatado no toString()', () {
    final Pet pet = Pet(
      id: 9,
      nome: 'Luna',
      especie: 'Gato',
      valor: 210.75,
      idLocal: 'uuid-9',
      idRemoto: 42,
      sincronizado: true,
    );
    expect(
      pet.toString(),
      'Pet(id: 9, nome: Luna, especie: Gato, valor: 210.75, '
      'idLocal: uuid-9, idRemoto: 42, sincronizado: true)',
    );
  });

  test('Pet.toApiJson() envia os campos exigidos pela API', () {
    final Pet pet = Pet(
      id: 3,
      nome: 'Thor',
      especie: 'Cão',
      valor: 180.50,
      idLocal: 'uuid-3',
    );
    expect(pet.toApiJson(), <String, dynamic>{
      'idLocal': 'uuid-3',
      'atendimentoId': 3,
      'nome': 'Thor',
      'especie': 'Cão',
      'valor': 180.50,
    });
  });

  test('Gerar idLocal único para dois registros novos (idempotência)', () {
    final Pet a = Pet(id: 1, nome: 'A', especie: 'Cão', valor: 10);
    final Pet b = Pet(id: 2, nome: 'B', especie: 'Gato', valor: 20);
    expect(a.idLocal, isNot(equals(b.idLocal)));
  });

  test('ApiIndisponivel e ApiErroServidor são ApiException', () {
    expect(const ApiIndisponivel('x'), isA<ApiException>());
    expect(const ApiErroServidor('y'), isA<ApiException>());
  });
}
