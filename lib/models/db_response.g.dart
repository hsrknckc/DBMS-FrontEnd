// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbResponse _$DbResponseFromJson(Map<String, dynamic> json) => DbResponse(
      requestId: json['requestId'] as String,
      ok: json['ok'] as bool?,
      data: json['data'],
      error: json['error'] as String?,
      status: json['status'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$DbResponseToJson(DbResponse instance) {
  final val = <String, dynamic>{
    'requestId': instance.requestId,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('ok', instance.ok);
  writeNotNull('data', instance.data);
  writeNotNull('error', instance.error);
  writeNotNull('status', instance.status);
  writeNotNull('message', instance.message);
  return val;
}
