// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DbResponse _$DbResponseFromJson(Map<String, dynamic> json) => DbResponse(
      requestId: json['requestId'] as String? ?? '',
      status: json['status'] as String?,
      message: json['message'] as String?,
      data: json['data'],
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

  writeNotNull('status', instance.status);
  writeNotNull('message', instance.message);
  writeNotNull('data', instance.data);
  return val;
}
