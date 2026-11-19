import 'package:uuid/uuid.dart';

/// Modelo da entidade do tema escolhido: **Pet** (Clínica Pet).
///
/// Adaptação da classe `Transferencia` do Projeto Bank. Além dos campos
/// originais, o modelo carrega os dados de controle do comportamento
/// **Offline-first**:
///
/// - `idLocal`: identificador único de origem (UUID), gerado no momento do
///   cadastro. Garante a idempotência da sincronização: se um registro
///   pendente for re-enviado, a API reconhece o `id_local` e NÃO cria
///   duplicidade.
/// - `idRemoto`: identificador (`id`) devolvido pela API/PostgreSQL após a
///   confirmação do cadastro remoto. `null` enquanto não sincronizado.
/// - `sincronizado`: `true` SOMENTE quando a API confirmou o registro
///   (resposta HTTP 2xx). Registros apenas no SQLite ficam com `false`.
class Pet {
  /// Identificador numérico do atendimento digitado no formulário
  /// (campo original do primeiro bimestre, convertido com `int.tryParse`).
  final int id;

  /// Nome do pet atendido.
  final String nome;

  /// Espécie do pet (Cão, Gato, Ave, Roedor...).
  final String especie;

  /// Valor monetário da consulta em reais (convertido com `double.tryParse`).
  final double valor;

  /// Identificador único de origem (UUID v4) do registro.
  final String idLocal;

  /// Identificador remoto (`id` no PostgreSQL). `null` = ainda não sincronizado.
  final int? idRemoto;

  /// `true` somente após a confirmação do servidor pela API.
  final bool sincronizado;

  Pet({
    required this.id,
    required this.nome,
    required this.especie,
    required this.valor,
    String? idLocal,
    this.idRemoto,
    this.sincronizado = false,
  }) : idLocal = idLocal ?? const Uuid().v4();

  /// Cria uma cópia com os campos alterados (usada pelo Repository ao
  /// marcar o registro como sincronizado).
  Pet copiarCom({
    int? id,
    String? nome,
    String? especie,
    double? valor,
    String? idLocal,
    int? idRemoto,
    bool? sincronizado,
  }) {
    return Pet(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      especie: especie ?? this.especie,
      valor: valor ?? this.valor,
      idLocal: idLocal ?? this.idLocal,
      idRemoto: idRemoto ?? this.idRemoto,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  /// JSON enviado à API no `POST /pets` (campos exigidos pelo backend).
  Map<String, dynamic> toApiJson() {
    return <String, dynamic>{
      'idLocal': idLocal,
      'atendimentoId': id,
      'nome': nome,
      'especie': especie,
      'valor': valor,
    };
  }

  /// Registro devolvido pela API (linha do PostgreSQL).
  /// `valor` chega como texto (NUMERIC), por isso é convertido com `tryParse`.
  factory Pet.fromJsonRemoto(Map<String, dynamic> json, {required Pet origem}) {
    return origem.copiarCom(
      idRemoto: (json['id'] as num?)?.toInt(),
      sincronizado: true,
    );
  }

  @override
  String toString() {
    return 'Pet(id: $id, nome: $nome, especie: $especie, valor: $valor, '
        'idLocal: $idLocal, idRemoto: $idRemoto, sincronizado: $sincronizado)';
  }
}
