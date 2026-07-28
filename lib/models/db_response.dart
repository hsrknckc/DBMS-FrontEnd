import 'package:json_annotation/json_annotation.dart';

part 'db_response.g.dart';

/// Backend TCP/IP soket sunucusundan dönen yanıt veri modeli (PROTOKOL.md DTO).
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

  /// Yanıt başarılı mı (status == 'OK')
  bool get isOk => status == 'OK';

  /// Yetkilendirme hatası mı
  bool get isUnauthorized => status == 'UNAUTHORIZED';

  /// Hata var mı
  bool get isError => status != 'OK';

  factory DbResponse.fromJson(Map<String, dynamic> json) =>
      _$DbResponseFromJson(json);

  Map<String, dynamic> toJson() => _$DbResponseToJson(this);
}
