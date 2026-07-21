/// Uygulama geneli Dio HTTP istemcisi.
///
/// [repository_providers.dart] içindeki [dioProvider] tarafından
/// oluşturulur ve tüm HTTP repository'lere inject edilir.
///
/// Bu sınıf artık sadece yardımcı sabitler içeriyor.
/// Gerçek HTTP çağrıları Dio üzerinden yapılıyor.
class ApiClient {
  /// Backend API temel URL'i.
  /// [repository_providers.dart]'taki dioProvider'da da ayarlanıyor.
  static const String baseUrl = 'http://localhost:8080/api/v1';

  /// Mock mode aktifken servisler sahte/taslak veri döner.
  /// [repository_providers.dart]'ta Mock yerine Http sınıfı seçilerek kapatılır.
  static const bool useMockData = true;

  static Map<String, String> get defaultHeaders => const {
        'Content-Type': 'application/json; charset=UTF-8',
        'Accept': 'application/json',
      };

  /// Auth token'ı header'a eklemek için yardımcı metod.
  /// Backend hazır olduğunda kullanılacak.
  static Map<String, String> authHeaders(String token) => {
        ...defaultHeaders,
        'Authorization': 'Bearer $token',
      };
}
