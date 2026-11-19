import 'package:flutter/material.dart';

import 'repository/pet_repository.dart';
import 'telas/lista_pets.dart';

/// Aplicação remota de **Clínica Pet**.
///
/// Adaptação do Projeto Bank ao tema "Clínica Pet", mantendo o padrão
/// estudado em aula (models, componente Editor, tela de lista e tela de
/// formulário) e trabalhando **somente com dados em memória**.
void main() {
  runApp(const ClinicaPetApp());
}

class ClinicaPetApp extends StatelessWidget {
  /// Repositório injetado (permite fake nos testes automatizados).
  final PetRepository? repository;

  const ClinicaPetApp({super.key, this.repository});

  /// Cor principal do tema (verde-azulado da clínica).
  static const Color corPrimaria = Color(0xFF00897B);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clínica Pet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: corPrimaria,
          primary: corPrimaria,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: corPrimaria,
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          elevation: 4,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: ListaPets(repository: repository),
    );
  }
}
