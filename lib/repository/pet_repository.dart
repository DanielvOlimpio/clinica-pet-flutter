import '../database/app_database.dart';
import '../models/pet.dart';
import '../services/pet_api_service.dart';

/// Resumo de uma execução de sincronização manual.
class ResultadoSincronizacao {
  /// Registros confirmados pela API nesta execução.
  final int enviados;

  /// Registros que continuam pendentes após a execução.
  final int pendentesRestantes;

  const ResultadoSincronizacao({
    required this.enviados,
    required this.pendentesRestantes,
  });
}

/// Camada **repository**: centraliza TODAS as regras de acesso aos dados.
///
/// A tela NÃO decide se usa SQLite ou API — o Repository controla essa
/// decisão e implementa o comportamento **Offline-first**:
///
/// 1. **Cadastro com API disponível:** tenta `POST /pets`; com confirmação
///    do servidor (HTTP 2xx), grava no SQLite com `sincronizado = 1` e o
///    `idRemoto` devolvido pela API.
/// 2. **Cadastro com API indisponível:** grava no SQLite com
///    `sincronizado = 0` — o registro não é perdido.
/// 3. **Sincronização manual:** envia os pendentes um a um; marca
///    `sincronizado = 1` SOMENTE com confirmação da API; uma falha não
///    interrompe o lote; a idempotência (UUID de origem) evita duplicidade
///    em re-envios.
class PetRepository {
  final AppDatabase _banco;
  final PetApiService _api;

  PetRepository({AppDatabase? banco, PetApiService? api})
      : _banco = banco ?? AppDatabase.instancia,
        _api = api ?? PetApiService();

  /// Lista todos os registros salvos localmente (SQLite).
  Future<List<Pet>> listar() => _banco.listar();

  /// Quantidade de registros pendentes de sincronização.
  Future<int> contarPendentes() => _banco.contarPendentes();

  /// Lista os registros armazenados no PostgreSQL (uso pontual/diagnóstico).
  Future<List<Pet>> buscarRemotos() => _api.listarRemotos();

  /// Recebe um cadastro e decide onde persistir.
  ///
  /// Devolve o `Pet` como está salvo no SQLite: com `sincronizado = true`
  /// quando a API confirmou, ou `sincronizado = false` quando ficou pendente.
  Future<Pet> cadastrar(Pet pet) async {
    try {
      // Tentativa de persistência remota.
      final Pet remoto = await _api.cadastrarRemoto(pet);

      // Confirmação recebida (HTTP 2xx): grava local como sincronizado.
      final Pet sincronizado = remoto.copiarCom(sincronizado: true);
      await _banco.inserir(sincronizado);
      return sincronizado;
    } on ApiException {
      // API indisponível ou com erro: persistência LOCAL garantida.
      // O registro NÃO é perdido e fica pendente (sincronizado = 0).
      await _banco.inserir(pet);
      rethrow;
    }
  }

  /// Sincronização manual: envia todos os registros pendentes à API.
  ///
  /// - Marca `sincronizado = 1` somente após a confirmação do servidor.
  /// - Se um envio falhar, o registro continua pendente e o lote segue.
  /// - Nenhum registro local é excluído.
  Future<ResultadoSincronizacao> sincronizarPendentes() async {
    final List<Pet> pendentes = await _banco.listarPendentes();

    int enviados = 0;
    for (final Pet pet in pendentes) {
      try {
        final Pet remoto = await _api.cadastrarRemoto(pet);
        await _banco.atualizarSincronizacao(
          idLocal: pet.idLocal,
          idRemoto: remoto.idRemoto!,
        );
        enviados++;
      } on ApiException {
        // Falha neste registro: mantém pendente e tenta o próximo.
        continue;
      }
    }

    return ResultadoSincronizacao(
      enviados: enviados,
      pendentesRestantes: pendentes.length - enviados,
    );
  }
}
