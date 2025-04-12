import 'dart:convert';

class ShoppingItem {
  String id;
  String name;
  String categoryId; // Kategoriye bağlamak için ID
  bool isBought;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.categoryId, // Zorunlu alan
    this.isBought = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'isBought': isBought,
      };

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        // Eski kayıtlarda categoryId olmayabilir diye null check
        categoryId: json['categoryId'] as String? ?? 'uncategorized', // Varsayılan ID
        isBought: json['isBought'] as bool,
      );

   String toJsonString() => jsonEncode(toJson());
   factory ShoppingItem.fromJsonString(String jsonString) =>
      ShoppingItem.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
}