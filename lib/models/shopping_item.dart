import 'dart:convert';

class ShoppingItem {
  String id;
  String name;
  bool isBought;

  ShoppingItem({required this.id, required this.name, this.isBought = false});

  // JSON'a dönüştürme
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isBought': isBought,
    };
  }

  // JSON'dan objeye dönüştürme
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'] as String,
      name: json['name'] as String,
      isBought: json['isBought'] as bool,
    );
  }

  // String (JSON) formatına dönüştürme (SharedPreferences için)
  String toJsonString() => jsonEncode(toJson());

  // String (JSON) formatından objeye dönüştürme (SharedPreferences için)
  factory ShoppingItem.fromJsonString(String jsonString) =>
      ShoppingItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}