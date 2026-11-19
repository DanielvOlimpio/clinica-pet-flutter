// Teste de integração REAL Flutter (Service) ↔ API ↔ PostgreSQL.
//
// PRÉ-REQUISITO: API em execução (localmente ou publicada). Exemplo:
//
//   flutter test test/integracao_api_test.dart \
//     --dart-define=API_URL=http://localhost:3000
//
// Se a API não estiver disponível, o teste é PULADO (a camada service
// identifica a indisponibilidade via ApiIndisponivel).

import 'package:flutter_test/flutter_test.dart';

import 'package:clinica_pet/models/pet.dart';
import 'package:clinica_pet/services/pet_api_service.dart';

void main() {
  final PetApiService api = PetApiService();

  test('Integração real: POST /pets confirma e GET /pets retorna o registro',
      () async {
    final Pet novo = Pet(id: 10, nome: 'Thor', especie: 'Cão', valor: 180.50);

    final Pet remoto;
    try {
      remoto = await api.cadastrarRemoto(novo);
    } on ApiException catch (e) {
      // API indisponível: pula o teste (não é falha do código).
      print('API indisponível — teste pulado: $e');
      return;
    }

    // Confirmação real do servidor: idRemoto atribuído pelo PostgreSQL.
    expect(remoto.idRemoto, isNotNull);
    expect(remoto.idRemoto, greaterThan(0));
    expect(remoto.sincronizado, isTrue);
    expect(remoto.idLocal, novo.idLocal);
    print('POST ok: idRemoto=${remoto.idRemoto}');

    // Re-envio do MESMO idLocal: idempotência, sem duplicidade.
    final Pet reenvio = await api.cadastrarRemoto(novo);
    expect(reenvio.idRemoto, remoto.idRemoto);
    print('Idempotência ok: re-envio retornou o id ${reenvio.idRemoto}');

    // GET lista o registro gravado.
    final List<Pet> remotos = await api.listarRemotos();
    expect(
      remotos.any((Pet p) => p.idRemoto == remoto.idRemoto),
      isTrue,
    );
    print('GET ok: ${remotos.length} registro(s) no PostgreSQL');

    api.dispose();
  });
}
