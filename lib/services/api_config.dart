/// Configuração centralizada da URL da API.
///
/// A URL NÃO deve ficar espalhada pelo código: as telas e o repository
/// sempre levem [urlApi].
///
/// Como definir a URL:
///
/// - **Desenvolvimento (emulador Android):** `10.0.2.2` é o endereço que o
///   emulador usa para alcançar o `localhost` do computador hospedeiro
///   (o `localhost` do emulador representa o PRÓPRIO emulador, não o PC).
///   Em dispositivo físico use o IP local da máquina na rede Wi-Fi.
/// - **Produção (após publicar a API no Render):** passe a URL via
///   `--dart-define`:
///
/// ```
/// flutter run --dart-define=API_URL=https://clinica-pet-api.onrender.com
/// ```
///
/// ou altere o valor de [urlProducao] abaixo.
class ApiConfig {
  /// URL usada em desenvolvimento (emulador Android -> localhost do PC).
  static const String urlDesenvolvimento = 'http://10.0.2.2:3000';

  /// Substitua pela URL pública da API publicada no Render.
  static const String urlProducao = 'URL-DA-API-NO-RENDER';

  /// URL efetiva: prioriza o valor recebido por `--dart-define=API_URL=...`;
  /// em último caso usa a URL de desenvolvimento.
  static const String urlApi = String.fromEnvironment(
    'API_URL',
    defaultValue: urlDesenvolvimento,
  );
}
