// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fetch_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FetchResponseModel _$FetchResponseModelFromJson(Map<String, dynamic> json) =>
    FetchResponseModel(
      entities: (json['entities'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, e as List<dynamic>),
      ),
      cursor: json['cursor'] as String?,
      hasMore: json['has_more'] as bool,
    );

Map<String, dynamic> _$FetchResponseModelToJson(FetchResponseModel instance) =>
    <String, dynamic>{
      'entities': instance.entities,
      'cursor': instance.cursor,
      'has_more': instance.hasMore,
    };
