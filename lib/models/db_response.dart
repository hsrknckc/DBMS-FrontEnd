import 'package:json_annotation/json_annotation.dart';

part 'db_response.g.dart';

/// Backend TCP/IP soket sunucusundan dönen yanıt veri modeli (DTO).
@JsonSerializable(includeIfNull: false)
class DbResponse {
  final String requestId;
  final bool? ok;
  final String? error;
  final String? status;
  final String? message;
  final dynamic data;

  const DbResponse({
    required this.requestId,
    this.ok,
    this.error,
    this.status,
    this.message,
    this.data,
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
