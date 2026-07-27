import 'package:json_annotation/json_annotation.dart';

part 'db_response.g.dart';

/// Backend TCP/IP soket sunucusundan dönen yanıt veri modeli (DTO).
///
/// Sunucudan dönen [status] alanı: "OK", "UNAUTHORIZED" veya "ERROR" alabilir.
@JsonSerializable(includeIfNull: false)
class DbResponse {
  final String requestId;
  final String status;
  final String? message;
  final dynamic data;

  const DbResponse({
    required this.requestId,
    required this.status,
    this.message,
    this.data,
  });

  /// Yanıt başarılı mı ("OK")
  bool get isOk => status == 'OK';

  /// Yetkilendirme hatası mı ("UNAUTHORIZED")
  bool get isUnauthorized => status == 'UNAUTHORIZED';

  /// Genel hata mı ("ERROR")
  bool get isError => status == 'ERROR';

  factory DbResponse.fromJson(Map<String, dynamic> json) =>
      _$DbResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DbResponseToJson(this);
}
