import 'package:flutter/material.dart';
import 'dart:convert';

class Category {
  String id;
  String name;
  // İkon ve renk ekleyerek görselleştirelim
  IconData iconData;
  Color color;

  Category({
    required this.id,
    required this.name,
    this.iconData = Icons.category, // Varsayılan ikon
    this.color = Colors.blueGrey,  // Varsayılan renk
  });

  // Renk ve ikonu da JSON'a/JSON'dan çevirme (IconData biraz dolaylı olacak)
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconCodePoint': iconData.codePoint, // İkon kod noktası
        'iconFontFamily': iconData.fontFamily, // İkon font ailesi
        'colorValue': color.value, // Renk değeri
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        iconData: IconData(
          json['iconCodePoint'] as int? ?? Icons.category.codePoint,
          fontFamily: json['iconFontFamily'] as String? ?? Icons.category.fontFamily,
        ),
        color: Color(json['colorValue'] as int? ?? Colors.blueGrey.value),
      );

   String toJsonString() => jsonEncode(toJson());
   factory Category.fromJsonString(String jsonString) =>
      Category.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}