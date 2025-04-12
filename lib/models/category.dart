import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final IconData iconData;
  final Color color;

  const Category({
    required this.id,
    required this.name,
    required this.iconData,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconData': iconData.codePoint,
    'color': color.value,
  };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    iconData: IconData(json['iconData'], fontFamily: 'MaterialIcons'),
    color: Color(json['color']),
  );

  Category copyWith({
    String? id,
    String? name,
    IconData? iconData,
    Color? color,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      iconData: iconData ?? this.iconData,
      color: color ?? this.color,
    );
  }
}