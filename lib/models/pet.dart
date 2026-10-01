/// Modelo da entidade do tema escolhido: **Pet** (Clínica Pet).
///
/// Adaptação da classe `Transferencia` do Projeto Bank, mantendo a mesma
/// estrutura: um identificador numérico `int`, dois campos de texto e um
/// valor monetário `double`.
///
/// Observação: os dados existem **somente em memória**. Não há persistência
/// (sem sqflite/shared_preferences) e a camada `database` do Projeto Bank
/// **não é utilizada** neste projeto.
class Pet {
  /// Identificador numérico do pet (convertido com `int.tryParse`).
  final int id;

  /// Nome do pet atendido.
  final String nome;

  /// Espécie do pet (Cão, Gato, Ave, Roedor...).
  final String especie;

  /// Valor monetário da consulta em reais (convertido com `double.tryParse`).
  final double valor;

  const Pet({
    required this.id,
    required this.nome,
    required this.especie,
    required this.valor,
  });

  @override
  String toString() {
    return 'Pet(id: $id, nome: $nome, especie: $especie, valor: $valor)';
  }
}
