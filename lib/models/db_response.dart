import 'package:json_annotation/json_annotation.dart';

part 'db_response.g.dart';

/// Backend TCP/IP soket sunucusundan dönen yanıt veri modeli (DTO).
///
/// Ön Yüz (Flutter) Protokolü:
///   `{"requestId": "...", "ok": true, "data": ...}`
///   `{"requestId": "...", "ok": false, "error": "..."}`
///
/// Arka Yüz (Java) Protokolü:
///   `{"requestId": "...", "status": "OK", "message": "...", "data": ...}`
@JsonSerializable(includeIfNull: false)
class DbResponse {
  final String requestId;

  // Ön Yüz (Flutter) Protokol Alanları
  final bool? ok;
  final dynamic data;
  final String? error;

  // Arka Yüz (Java) Protokol Alanları
  final String? status;
  final String? message;

  const DbResponse({
    required this.requestId,
    this.ok,
    this.data,
    this.error,
    this.status,
    this.message,
  });

  /// Yanıt başarılı mı
  bool get isOk => ok == true || status == 'OK';

  /// Yetkilendirme hatası mı
  bool get isUnauthorized =>
      status == 'UNAUTHORIZED' ||
      error == 'Not authenticated' ||
      (error != null && error!.toLowerCase().contains('unauthorized')) ||
      (error != null && error!.toLowerCase().contains('permission denied'));

  /// Genel hata mı
  bool get isError => ok == false || status == 'ERROR';

  factory DbResponse.fromJson(Map<String, dynamic> json) =>
      _$DbResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DbResponseToJson(this);
}
