import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/pet.dart';

/// Camada **database**: criação, abertura e gerenciamento do banco SQLite
/// local da aplicação Clínica Pet.
///
/// A tabela `pets` corresponde à entidade principal e possui o campo de
/// controle de sincronização `sincronizado`:
///
/// - `1` = registro sincronizado com a API (confirmado pelo servidor).
/// - `0` = registro pendente de sincronização (valor padrão na criação).
///
/// Identificação dos registros:
/// - `id` (SQLite, autoincrement): identificador local da linha.
/// - `id_local` (TEXT UNIQUE): UUID de origem — permite relacionar o registro
///   local ao remoto e evita duplicidade na sincronização.
/// - `id_remoto` (INTEGER, anulável): identificador devolvido pela API.
class AppDatabase {
  AppDatabase._();

  /// Instância única do banco (padrão singleton).
  static final AppDatabase instancia = AppDatabase._();

  Database? _banco;

  /// Abre (ou cria) o banco local. Os dados persistem entre execuções.
  Future<Database> abrir() async {
    final Database? atual = _banco;
    if (atual != null && atual.isOpen) {
      return atual;
    }

    _banco = await openDatabase(
      join(await getDatabasesPath(), 'clinica_pet.db'),
      version: 1,
      onCreate: (Database db, int versao) async {
        await db.execute('''
          CREATE TABLE pets (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            id_local TEXT NOT NULL UNIQUE,
            id_remoto INTEGER,
            atendimento_id INTEGER NOT NULL,
            nome TEXT NOT NULL,
            especie TEXT NOT NULL,
            valor REAL NOT NULL,
            sincronizado INTEGER NOT NULL DEFAULT 0
          );
        ''');
      },
    );
    return _banco!;
  }

  Map<String, dynamic> _paraMapa(Pet pet) {
    return <String, dynamic>{
      'id_local': pet.idLocal,
      'id_remoto': pet.idRemoto,
      'atendimento_id': pet.id,
      'nome': pet.nome,
      'especie': pet.especie,
      'valor': pet.valor,
      'sincronizado': pet.sincronizado ? 1 : 0,
    };
  }

  Pet _doMapa(Map<String, Object?> mapa) {
    return Pet(
      id: mapa['atendimento_id'] as int,
      nome: mapa['nome'] as String,
      especie: mapa['especie'] as String,
      valor: (mapa['valor'] as num).toDouble(),
      idLocal: mapa['id_local'] as String,
      idRemoto: mapa['id_remoto'] as int?,
      sincronizado: (mapa['sincronizado'] as int) == 1,
    );
  }

  /// Insere (ou re-insere) um registro. `ConflictAlgorithm.replace` cobre o
  /// caso de re-tentativa de gravação do mesmo `id_local` (UUID).
  Future<int> inserir(Pet pet) async {
    final Database db = await abrir();
    return db.insert(
      'pets',
      _paraMapa(pet),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Consulta todos os registros salvos localmente.
  Future<List<Pet>> listar() async {
    final Database db = await abrir();
    final List<Map<String, Object?>> linhas =
        await db.query('pets', orderBy: 'id ASC');
    return linhas.map(_doMapa).toList();
  }

  /// Localiza os registros pendentes de sincronização (`sincronizado = 0`).
  Future<List<Pet>> listarPendentes() async {
    final Database db = await abrir();
    final List<Map<String, Object?>> linhas = await db.query(
      'pets',
      where: 'sincronizado = ?',
      whereArgs: <int>[0],
      orderBy: 'id ASC',
    );
    return linhas.map(_doMapa).toList();
  }

  /// Quantidade de registros aguardando sincronização.
  Future<int> contarPendentes() async {
    final Database db = await abrir();
    final int? total = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM pets WHERE sincronizado = 0;'),
    );
    return total ?? 0;
  }

  /// Marca um registro como sincronizado (1) e grava o `id_remoto` recebido
  /// da API. Chamado SOMENTE após a confirmação do servidor.
  Future<int> atualizarSincronizacao({
    required String idLocal,
    required int idRemoto,
  }) async {
    final Database db = await abrir();
    return db.update(
      'pets',
      <String, dynamic>{'sincronizado': 1, 'id_remoto': idRemoto},
      where: 'id_local = ?',
      whereArgs: <String>[idLocal],
    );
  }
}
