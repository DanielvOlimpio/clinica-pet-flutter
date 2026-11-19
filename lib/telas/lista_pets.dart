import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../components/tile_pet.dart';
import '../models/pet.dart';
import '../repository/pet_repository.dart';
import '../services/pet_api_service.dart' show ApiException;
import 'formulario_pet.dart';

/// **Tela de lista** do tema escolhido.
///
/// Construída com `ListView.builder`, exibe cada registro com Card/ListTile
/// (componente [TilePet]). Os dados vêm da camada **Repository**
/// (SQLite + sincronização com a API) — a tela NÃO executa SQL nem HTTP.
///
/// Comportamento Offline-first:
/// - os registros pendentes aparecem com o indicador `cloud_upload`;
/// - um banner informa a existência de pendências;
/// - o botão "Sincronizar pendentes" (ícone `sync`) aciona a sincronização
///   manual e apresenta o resumo do resultado.
class ListaPets extends StatefulWidget {
  /// Repositório injetado (permite fake nos testes automatizados).
  final PetRepository repository;

  ListaPets({super.key, PetRepository? repository})
      : repository = repository ?? PetRepository();

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

  List<Pet> _pets = <Pet>[];
  int _pendentes = 0;
  bool _sincronizando = false;

  @override
  void initState() {
    super.initState();
    _atualizarDados();
  }

  /// Recarrega a listagem e o contador de pendências do banco local.
  Future<void> _atualizarDados() async {
    final List<Pet> pets = await widget.repository.listar();
    final int pendentes = await widget.repository.contarPendentes();
    if (!mounted) {
      return;
    }
    setState(() {
      _pets = pets;
      _pendentes = pendentes;
    });
  }

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

    // Antes do setState, utiliza-se Future.delayed() (1 segundo) — padrão
    // preservado do primeiro bimestre.
    Future<void>.delayed(const Duration(seconds: 1), () async {
      if (!mounted) {
        return;
      }

      // O Repository decide a persistência: API confirmada -> sincronizado;
      // API indisponível -> salvo no dispositivo (pendente).
      Pet salvo;
      try {
        salvo = await widget.repository.cadastrar(novoPet);
      } on ApiException {
        salvo = novoPet;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _pets = List<Pet>.of(_pets)..add(salvo);
        if (!salvo.sincronizado) {
          _pendentes++;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            salvo.sincronizado
                ? 'Registro cadastrado e sincronizado com sucesso.'
                : 'Sem conexão com o servidor. Registro salvo no dispositivo.',
          ),
          backgroundColor:
              salvo.sincronizado ? Colors.green.shade700 : Colors.orange.shade800,
        ),
      );
    });
  }

  /// Ação "Sincronizar pendentes": envia os registros pendentes à API.
  Future<void> _sincronizar() async {
    if (_sincronizando) {
      return;
    }
    setState(() {
      _sincronizando = true;
    });

    final ResultadoSincronizacao resultado;
    try {
      resultado = await widget.repository.sincronizarPendentes();
    } finally {
      if (mounted) {
        setState(() {
          _sincronizando = false;
        });
      }
    }

    await _atualizarDados();
    if (!mounted) {
      return;
    }

    final bool tudoSincronizado = resultado.pendentesRestantes == 0;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          tudoSincronizado
              ? 'Sincronização concluída. ${resultado.enviados} registro(s) enviado(s).'
              : 'Não foi possível sincronizar alguns registros. '
                  'Eles continuam salvos localmente.',
        ),
        backgroundColor:
            tudoSincronizado ? Colors.green.shade700 : Colors.orange.shade800,
      ),
    );
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
          // Sincronização manual dos registros pendentes.
          IconButton(
            onPressed: _sincronizando ? null : _sincronizar,
            icon: _sincronizando
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.sync),
            tooltip: 'Sincronizar pendentes',
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
      body: Column(
        children: <Widget>[
          // Banner informativo: existem registros aguardando sincronização.
          if (_pendentes > 0)
            Material(
              color: Colors.orange.shade800,
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.cloud_upload_outlined,
                    color: Colors.white),
                title: Text(
                  'Existem registros aguardando sincronização ($_pendentes).',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          Expanded(
            child: _pets.isEmpty
                ? const Center(
                    child: Text(
                      'Nenhum atendimento cadastrado.\nUse o botão "Novo pet".',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    itemCount: _pets.length,
                    itemBuilder: (BuildContext context, int indice) {
                      return TilePet(
                        pet: _pets[indice],
                        formatador: _formatador,
                      );
                    },
                  ),
          ),
        ],
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
