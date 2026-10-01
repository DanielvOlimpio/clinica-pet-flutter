import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/tile_pet.dart';
import '../models/pet.dart';
import 'formulario_pet.dart';

/// **Tela de lista** do tema escolhido.
///
/// Construída com `ListView.builder`, exibe cada registro com Card/ListTile
/// (componente [TilePet]) e recebe o novo pet devolvido pelo formulário com
/// `Navigator.push` / `Navigator.pop`. A lista fica **somente em memória** e é
/// atualizada com `setState` após um `Future.delayed()` de 1 segundo.
class ListaPets extends StatefulWidget {
  const ListaPets({super.key});

  @override
  State<ListaPets> createState() => _ListaPetsState();
}

class _ListaPetsState extends State<ListaPets> {
  /// Formatação monetária no padrão brasileiro (R$ 0,00) via pacote `intl`.
  final NumberFormat _formatador = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: r'R$',
    decimalDigits: 2,
  );

  /// Registros iniciais mantidos apenas em memória (sem persistência).
  final List<Pet> _pets = <Pet>[
    const Pet(id: 1, nome: 'Thor', especie: 'Cão', valor: 180.00),
    const Pet(id: 2, nome: 'Mia', especie: 'Gato', valor: 120.50),
  ];

  double get _totalConsultas => _pets.fold<double>(
        0,
        (double soma, Pet pet) => soma + pet.valor,
      );

  /// Abre o formulário e recebe o `Pet` criado com `Navigator.pop`.
  Future<void> _abrirFormulario() async {
    final Pet? novoPet = await Navigator.push<Pet>(
      context,
      MaterialPageRoute<Pet>(
        builder: (BuildContext context) => const FormularioPet(),
      ),
    );

    // Se o usuário voltar sem salvar, nada é incluído na lista.
    if (novoPet == null || !mounted) {
      return;
    }

    // Antes do setState, utiliza-se Future.delayed() (1 segundo).
    Future<void>.delayed(const Duration(seconds: 1), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _pets.add(novoPet);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Atendimento de ${novoPet.nome} salvo na lista!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData tema = Theme.of(context);
    final ColorScheme cores = tema.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clínica Pet'),
        actions: <Widget>[
          IconButton(
            onPressed: _abrirFormulario,
            icon: const Icon(Icons.medical_services_outlined),
            tooltip: 'Cadastrar atendimento',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              '${_pets.length} atendimento(s) • Total: ${_formatador.format(_totalConsultas)}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: _pets.length,
        itemBuilder: (BuildContext context, int indice) {
          return TilePet(
            pet: _pets[indice],
            formatador: _formatador,
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormulario,
        backgroundColor: cores.primary,
        foregroundColor: cores.onPrimary,
        icon: const Icon(Icons.pets),
        label: const Text('Novo pet'),
      ),
    );
  }
}
