// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'key.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Key _$KeyFromJson(Map<String, dynamic> json) {
  return Key()
    ..publicKey = json['publicKey'] as String
    ..privateKey = json['privateKey'] as String;
}

Map<String, dynamic> _$KeyToJson(Key instance) => <String, dynamic>{
      'publicKey': instance.publicKey,
      'privateKey': instance.privateKey,
    };
