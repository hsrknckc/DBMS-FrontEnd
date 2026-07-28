import 'package:json_annotation/json_annotation.dart';

part 'db_response.g.dart';

/// Backend TCP/IP soket sunucusundan dönen yanıt veri modeli (DTO).
///
/// Yeni Protokol Yanıt Formatı:
///   `{"requestId": "...", "status": "OK", "message": "...", "data": [...]}`
///   `data` her zaman dizidir. Tek nesne dönen işlemlerde `data[0]` okunur.
@JsonSerializable(includeIfNull: false)
class DbResponse {
  final String requestId;
  final String? status;
  final String? message;
  final dynamic data;

  const DbResponse({
    required this.requestId,
    this.status,
    this.message,
    this.data,
  });

  /// Yanıt başarılı mı
  bool get isOk => status == 'OK';

  /// Yetkilendirme hatası mı
  bool get isUnauthorized => status == 'UNAUTHORIZED';

  /// Genel hata mı
  bool get isError => status == 'ERROR';

  factory DbResponse.fromJson(Map<String, dynamic> json) =>
      _$DbResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DbResponseToJson(this);
}
