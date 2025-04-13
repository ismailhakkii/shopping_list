import 'package:flutter/material.dart';

/// Alışveriş listesindeki her bir ürünü temsil eden sınıf.
/// SOLID prensiplerine uygun olarak sadece ürün verilerini yönetmekten sorumludur.
class ShoppingItem {
  final String id;
  final String name;
  String categoryId;
  bool isBought;
  final DateTime createdAt;
  DateTime? boughtAt;
  String? note;
  int quantity;
  String? unit;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.categoryId,
    this.isBought = false,
    DateTime? createdAt,
    this.boughtAt,
    this.note,
    this.quantity = 1,
    this.unit,
  }) : createdAt = createdAt ?? DateTime.now() {
    validateItem();
  }

  /// Ürün verilerinin doğruluğunu kontrol eder
  void validateItem() {
    if (id.trim().isEmpty) {
      throw ArgumentError('Ürün ID boş olamaz');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Ürün adı boş olamaz');
    }
    if (name.trim().length > 50) {
      throw ArgumentError('Ürün adı 50 karakterden uzun olamaz');
    }
    if (categoryId.trim().isEmpty) {
      throw ArgumentError('Kategori ID boş olamaz');
    }
    if (quantity < 1) {
      throw ArgumentError('Miktar 1\'den küçük olamaz');
    }
    if (note != null && note!.length > 100) {
      throw ArgumentError('Not 100 karakterden uzun olamaz');
    }
  }

  /// Ürünü satın alındı olarak işaretler
  void markAsBought() {
    isBought = true;
    boughtAt = DateTime.now();
  }

  /// Ürünün satın alındı işaretini kaldırır
  void markAsNotBought() {
    isBought = false;
    boughtAt = null;
  }

  /// JSON'dan ShoppingItem nesnesi oluşturur
  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    try {
      return ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        categoryId: json['categoryId'] as String,
        isBought: json['isBought'] as bool? ?? false,
        createdAt: DateTime.parse(json['createdAt'] as String),
        boughtAt: json['boughtAt'] != null 
            ? DateTime.parse(json['boughtAt'] as String)
            : null,
        note: json['note'] as String?,
        quantity: json['quantity'] as int? ?? 1,
        unit: json['unit'] as String?,
      );
    } catch (e) {
      debugPrint('ShoppingItem.fromJson hatası: $e');
      // Hata durumunda varsayılan ürün döndür
      return ShoppingItem(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Hata',
        categoryId: 'error',
      );
    }
  }

  /// ShoppingItem nesnesini JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'categoryId': categoryId,
      'isBought': isBought,
      'createdAt': createdAt.toIso8601String(),
      'boughtAt': boughtAt?.toIso8601String(),
      'note': note,
      'quantity': quantity,
      'unit': unit,
    };
  }

  /// Yeni özelliklerle ShoppingItem kopyası oluşturur
  ShoppingItem copyWith({
    String? id,
    String? name,
    String? categoryId,
    bool? isBought,
    DateTime? createdAt,
    DateTime? boughtAt,
    String? note,
    int? quantity,
    String? unit,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      isBought: isBought ?? this.isBought,
      createdAt: createdAt ?? this.createdAt,
      boughtAt: boughtAt ?? this.boughtAt,
      note: note ?? this.note,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShoppingItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          categoryId == other.categoryId &&
          isBought == other.isBought &&
          createdAt == other.createdAt &&
          boughtAt == other.boughtAt &&
          note == other.note &&
          quantity == other.quantity &&
          unit == other.unit;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      categoryId.hashCode ^
      isBought.hashCode ^
      createdAt.hashCode ^
      boughtAt.hashCode ^
      note.hashCode ^
      quantity.hashCode ^
      unit.hashCode;

  @override
  String toString() =>
      'ShoppingItem(id: $id, name: $name, categoryId: $categoryId, isBought: $isBought, quantity: $quantity${unit != null ? ' $unit' : ''})';
}