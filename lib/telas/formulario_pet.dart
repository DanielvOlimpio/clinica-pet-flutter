import 'package:flutter/material.dart';

import '../components/editor.dart';
import '../models/pet.dart';

/// **Tela de formulário** do tema escolhido.
///
/// Utiliza `TextEditingController` em todos os campos, o componente `Editor`
/// e conversões seguras com `int.tryParse` e `double.tryParse`.
/// O objeto `Pet` só é criado quando **todos** os dados são válidos e, ao
/// final, é devolvido à tela de lista com `Navigator.pop(context, pet)`.
class FormularioPet extends StatefulWidget {
  const FormularioPet({super.key});

  @override
  State<FormularioPet> createState() => _FormularioPetState();
}

class _FormularioPetState extends State<FormularioPet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _controladorId = TextEditingController();
  final TextEditingController _controladorNome = TextEditingController();
  final TextEditingController _controladorEspecie = TextEditingController();
  final TextEditingController _controladorValor = TextEditingController();

  @override
  void dispose() {
    _controladorId.dispose();
    _controladorNome.dispose();
    _controladorEspecie.dispose();
    _controladorValor.dispose();
    super.dispose();
  }

  /// Cria o objeto apenas quando os dados são válidos e retorna para a lista.
  void _salvar() {
    final bool formularioValido = _formKey.currentState?.validate() ?? false;
    if (!formularioValido) {
      return;
    }

    // Conversões seguras: `tryParse` devolve `null` em vez de lançar exceção.
    final int? id = int.tryParse(_controladorId.text.trim());
    final double? valor = double.tryParse(
      _controladorValor.text.trim().replaceAll(',', '.'),
    );
    final String nome = _controladorNome.text.trim();
    final String especie = _controladorEspecie.text.trim();

    if (id == null || id <= 0 || valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Id e valor precisam ser números maiores que zero.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // Objeto criado somente com dados válidos.
    final Pet pet = Pet(
      id: id,
      nome: nome,
      especie: especie,
      valor: valor,
    );

    // Devolve o objeto para a tela de lista.
    Navigator.pop(context, pet);
  }

  String? _validarId(String? texto) {
    final int? id = int.tryParse((texto ?? '').trim());
    if (id == null) {
      return 'Informe apenas números';
    }
    if (id <= 0) {
      return 'O id deve ser maior que zero';
    }
    return null;
  }

  String? _validarNome(String? texto) {
    if ((texto ?? '').trim().isEmpty) {
      return 'Informe o nome do pet';
    }
    return null;
  }

  String? _validarEspecie(String? texto) {
    if ((texto ?? '').trim().isEmpty) {
      return 'Informe a espécie do pet';
    }
    return null;
  }

  String? _validarValor(String? texto) {
    final double? valor = double.tryParse(
      (texto ?? '').trim().replaceAll(',', '.'),
    );
    if (valor == null) {
      return 'Informe apenas números (ex.: 150,50)';
    }
    if (valor <= 0) {
      return 'O valor deve ser maior que zero';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadastrar atendimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: <Widget>[
            Editor(
              controlador: _controladorId,
              texto: 'Identificador (id)',
              dicaTexto: 'Ex.: 3',
              icone: Icons.tag,
              numeroDecimal: 0,
              validador: _validarId,
            ),
            Editor(
              controlador: _controladorNome,
              texto: 'Nome do pet',
              dicaTexto: 'Ex.: Thor',
              icone: Icons.pets,
              validador: _validarNome,
            ),
            Editor(
              controlador: _controladorEspecie,
              texto: 'Espécie',
              dicaTexto: 'Ex.: Cão, Gato, Ave...',
              icone: Icons.category_outlined,
              validador: _validarEspecie,
            ),
            Editor(
              controlador: _controladorValor,
              texto: 'Valor da consulta',
              dicaTexto: 'Ex.: 180,50',
              icone: Icons.payments_outlined,
              numeroDecimal: 2,
              prefixoTexto: 'R\$ ',
              validador: _validarValor,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: FilledButton.icon(
                onPressed: _salvar,
                icon: const Icon(Icons.save),
                label: const Text('Salvar atendimento'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
