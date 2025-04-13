import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'shopping_item.dart';

/// Alışveriş listesini temsil eden sınıf.
/// Her bir liste benzersiz bir ID'ye, isme ve ürünler listesine sahiptir.
class ShoppingList {
  final String id;
  final String name;
  final List<ShoppingItem> items;
  final DateTime createdAt;
  final int? icon;
  final Color? color;

  ShoppingList({
    required this.id,
    required this.name,
    required this.items,
    required this.createdAt,
    this.icon,
    this.color,
  }) {
    validateList();
  }

  /// Liste verilerinin doğruluğunu kontrol eder
  void validateList() {
    if (id.trim().isEmpty) {
      throw ArgumentError('Liste ID boş olamaz');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Liste adı boş olamaz');
    }
    if (name.trim().length > 50) {
      throw ArgumentError('Liste adı 50 karakterden uzun olamaz');
    }
  }

  /// Listenin tamamlanma yüzdesini hesaplar
  double get completionPercentage {
    if (items.isEmpty) return 0;
    final boughtItems = items.where((item) => item.isBought).length;
    return (boughtItems / items.length) * 100;
  }

  /// Listedeki toplam ürün sayısını döndürür
  int get totalItems => items.length;

  /// Listedeki satın alınmış ürün sayısını döndürür
  int get boughtItems => items.where((item) => item.isBought).length;

  /// Listedeki satın alınmamış ürün sayısını döndürür
  int get remainingItems => totalItems - boughtItems;

  /// Kategoriye göre ürünleri gruplar
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final grouped = <String, List<ShoppingItem>>{};
    for (var item in items) {
      grouped.putIfAbsent(item.categoryId, () => []).add(item);
    }
    return grouped;
  }

  /// JSON'dan ShoppingList nesnesi oluşturur
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    try {
      return ShoppingList(
        id: json['id'] as String,
        name: json['name'] as String,
        items: (json['items'] as List<dynamic>?)
                ?.map((item) => ShoppingItem.fromJson(item as Map<String, dynamic>))
                .toList() ??
            [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        icon: json['icon'] as int?,
        color: json['color'] != null
            ? Color(json['color'] as int)
            : null,
      );
    } catch (e) {
      debugPrint('ShoppingList.fromJson hatası: $e');
      // Hata durumunda varsayılan liste döndür
      return ShoppingList(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Hata',
        items: [],
        createdAt: DateTime.now(),
      );
    }
  }

  /// ShoppingList nesnesini JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'icon': icon,
      'color': color?.value,
    };
  }

  /// Yeni özelliklerle ShoppingList kopyası oluşturur
  ShoppingList copyWith({
    String? id,
    String? name,
    List<ShoppingItem>? items,
    DateTime? createdAt,
    int? icon,
    Color? color,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      items: items ?? List.from(this.items),
      createdAt: createdAt ?? this.createdAt,
      icon: icon ?? this.icon,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingList &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          createdAt == other.createdAt &&
          icon == other.icon &&
          color?.value == other.color?.value &&
          listEquals(items, other.items);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      items.hashCode ^
      createdAt.hashCode ^
      icon.hashCode ^
      (color?.value ?? 0).hashCode;

  @override
  String toString() =>
      'ShoppingList(id: $id, name: $name, items: ${items.length}, completion: ${completionPercentage.toStringAsFixed(1)}%)';
}