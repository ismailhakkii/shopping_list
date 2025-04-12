import 'dart:convert';

class ShoppingItem {
  final String id;
  final String name;
  final String categoryId;
  bool isBought;
  DateTime? addedDate;  // ekleme tarihi
  DateTime? boughtDate; // alınma tarihi

  ShoppingItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.isBought = false,
    this.addedDate,
    this.boughtDate,
  }) {
    // eğer ekleme tarihi verilmemişse şu anı kullan
    addedDate ??= DateTime.now();
  }

  // JSON'a çevirme
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'isBought': isBought,
    'addedDate': addedDate?.toIso8601String(),
    'boughtDate': boughtDate?.toIso8601String(),
  };

  // JSON'dan oluşturma
  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
    id: json['id'],
    name: json['name'],
    categoryId: json['categoryId'],
    isBought: json['isBought'],
    addedDate: json['addedDate'] != null ? DateTime.parse(json['addedDate']) : null,
    boughtDate: json['boughtDate'] != null ? DateTime.parse(json['boughtDate']) : null,
  );

  // JSON string dönüşümleri
  String toJsonString() => jsonEncode(toJson());
  factory ShoppingItem.fromJsonString(String str) => ShoppingItem.fromJson(jsonDecode(str));
}