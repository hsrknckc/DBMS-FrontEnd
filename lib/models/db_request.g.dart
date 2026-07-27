// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbRequest _$DbRequestFromJson(Map<String, dynamic> json) => DbRequest(
      requestId: json['requestId'] as String,
      action: json['action'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      database: json['database'] as String?,
      collection: json['collection'] as String?,
      filter: json['filter'] as Map<String, dynamic>?,
      document: json['document'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$DbRequestToJson(DbRequest instance) {
  final val = <String, dynamic>{
    'requestId': instance.requestId,
    'action': instance.action,
    'username': instance.username,
    'password': instance.password,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('database', instance.database);
  writeNotNull('collection', instance.collection);
  writeNotNull('filter', instance.filter);
  writeNotNull('document', instance.document);
  return val;
}
