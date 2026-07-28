import 'package:json_annotation/json_annotation.dart';

part 'db_request.g.dart';

/// Backend TCP/IP soket sunucusuna gönderilen istek veri modeli (DTO).
///
/// Yeni Protokol Zarfı:
///   `{"requestId": "...", "action": "...", "username": "...", "password": "...",
///     "database": "...", "collection": "...", "filter": {...}, "document": {...}}`
@JsonSerializable(includeIfNull: false)
class DbRequest {
  final String requestId;
  final String action;
  final String? username;
  final String? password;
  final String? database;
  final String? collection;
  final Map<String, dynamic>? filter;
  final Map<String, dynamic>? document;

  const DbRequest({
    required this.requestId,
    required this.action,
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
