import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../models/pet.dart';
import 'api_config.dart';

/// Exceções tipadas da camada service, para o Repository diferenciar
/// "API indisponível" de "a API respondeu, mas com erro".
abstract class ApiException implements Exception {
  final String mensagem;
  const ApiException(this.mensagem);

  @override
  String toString() => mensagem;
}

/// A API não pôde ser alcançada (sem conexão, timeout, DNS...).
class ApiIndisponivel extends ApiException {
  const ApiIndisponivel(super.mensagem);
}

/// A API respondeu, mas com status de erro ou corpo inválido.
class ApiErroServidor extends ApiException {
  const ApiErroServidor(super.mensagem);
}

/// Camada **service**: centraliza TODA a comunicação HTTP com a API.
///
/// As telas NÃO executam requisições diretamente — elas falam com o
/// Repository, que por sua vez usa este serviço.
class PetApiService {
  static const Duration _tempoLimite = Duration(seconds: 10);

  final http.Client _cliente = http.Client();

  Uri get _uriPets => Uri.parse('${ApiConfig.urlApi}/pets');

  /// Envia um novo registro para a API (`POST /pets`).
  ///
  /// Devolve o `Pet` com o `idRemoto` preenchido e `sincronizado = true`.
  /// Lança [ApiIndisponivel] quando o servidor não responde e
  /// [ApiErroServidor] quando a resposta é um erro ou é inválida.
  Future<Pet> cadastrarRemoto(Pet pet) async {
    try {
      final http.Response resposta = await _cliente
          .post(
            _uriPets,
            headers: const <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(pet.toApiJson()),
          )
          .timeout(_tempoLimite);

      if (resposta.statusCode != 201 && resposta.statusCode != 200) {
        throw ApiErroServidor(
          'A API respondeu com o status ${resposta.statusCode}.',
        );
      }

      final Map<String, dynamic> dados = jsonDecode(
        utf8.decode(resposta.bodyBytes),
      ) as Map<String, dynamic>;
      return Pet.fromJsonRemoto(dados, origem: pet);
    } on TimeoutException {
      throw const ApiIndisponivel('Tempo esgotado ao contatar a API.');
    } on SocketException {
      throw const ApiIndisponivel('Sem conexão com o servidor.');
    } on http.ClientException {
      throw const ApiIndisponivel('Sem conexão com o servidor.');
    } on FormatException {
      throw const ApiErroServidor('Resposta inválida da API.');
    }
  }

  /// Busca os registros armazenados no PostgreSQL (`GET /pets`).
  Future<List<Pet>> listarRemotos() async {
    try {
      final http.Response resposta =
          await _cliente.get(_uriPets).timeout(_tempoLimite);

      if (resposta.statusCode != 200) {
        throw ApiErroServidor(
          'A API respondeu com o status ${resposta.statusCode}.',
        );
      }

      final List<dynamic> dados =
          jsonDecode(utf8.decode(resposta.bodyBytes)) as List<dynamic>;
      return dados.map((dynamic item) {
        final Map<String, dynamic> json = item as Map<String, dynamic>;
        return Pet(
          id: (json['atendimento_id'] as num).toInt(),
          nome: json['nome'] as String,
          especie: json['especie'] as String,
          valor: double.tryParse('${json['valor']}') ?? 0,
          idLocal: json['id_local'] as String,
          idRemoto: (json['id'] as num?)?.toInt(),
          sincronizado: true,
        );
      }).toList();
    } on TimeoutException {
      throw const ApiIndisponivel('Tempo esgotado ao contatar a API.');
    } on SocketException {
      throw const ApiIndisponivel('Sem conexão com o servidor.');
    } on http.ClientException {
      throw const ApiIndisponivel('Sem conexão com o servidor.');
    } on FormatException {
      throw const ApiErroServidor('Resposta inválida da API.');
    }
  }

  void dispose() {
    _cliente.close();
  }
}
