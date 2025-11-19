import 'package:json_annotation/json_annotation.dart';

part 'unit.g.dart'; // This file will be generated

@JsonSerializable()
class Unit {
  final String id;
  final String name;
  final int points;
  final String faction;
  // ... other fields

  Unit({
    required this.id,
    required this.name,
    required this.points,
    required this.faction,
  });

  factory Unit.fromJson(Map<String, dynamic> json) => _$UnitFromJson(json);
  Map<String, dynamic> toJson() => _$UnitToJson(this);
}
