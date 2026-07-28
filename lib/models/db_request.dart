import 'package:json_annotation/json_annotation.dart';

part 'db_request.g.dart';

/// Backend TCP/IP soket sunucusuna gönderilen istek veri modeli (DTO).
@JsonSerializable(includeIfNull: false)
class DbRequest {
  final String requestId;
  final String action;
  final String? token;
  final Map<String, dynamic>? payload;
  final String? username;
  final String? password;
  final String? database;
  final String? collection;
  final Map<String, dynamic>? filter;
  final Map<String, dynamic>? document;

  const DbRequest({
    required this.requestId,
    required this.action,
    this.token,
    this.payload,
    this.username,
    this.password,
    this.database,
    this.collection,
    this.filter,
    this.document,
  });

  factory DbRequest.fromJson(Map<String, dynamic> json) =>
      _$DbRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DbRequestToJson(this);
}
