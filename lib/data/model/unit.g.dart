// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Unit _$UnitFromJson(Map<String, dynamic> json) => Unit(
  id: json['id'] as String,
  name: json['name'] as String,
  points: (json['points'] as num).toInt(),
  faction: json['faction'] as String,
);

Map<String, dynamic> _$UnitToJson(Unit instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'points': instance.points,
  'faction': instance.faction,
};
