import 'package:flutter/material.dart';

/// Alışveriş listesi kategorilerini temsil eden sınıf.
/// SOLID prensiplerinden Single Responsibility Principle'a uygun olarak
/// sadece kategori verilerini yönetmekten sorumludur.
class Category {
  final String id;
  final String name;
  final IconData iconData;
  Color _color;

  Category({
    required this.id,
    required this.name,
    required this.iconData,
    required Color color,
  }) : _color = color {
    validateCategory();
  }

  /// Kategori verilerinin doğruluğunu kontrol eder
  void validateCategory() {
    if (id.trim().isEmpty) {
      throw ArgumentError('Kategori ID boş olamaz');
    }
    if (name.trim().isEmpty) {
      throw ArgumentError('Kategori adı boş olamaz');
    }
    if (name.trim().length > 30) {
      throw ArgumentError('Kategori adı 30 karakterden uzun olamaz');
    }
  }

  /// JSON'dan Category nesnesi oluşturur
  factory Category.fromJson(Map<String, dynamic> json) {
    try {
      return Category(
        id: json['id'] as String,
        name: json['name'] as String,
        iconData: IconData(
          json['iconData'] as int,
          fontFamily: 'MaterialIcons',
        ),
        color: Color(json['color'] as int),
      );
    } catch (e) {
      debugPrint('Category.fromJson hatası: $e');
      // Hata durumunda varsayılan kategori döndür
      return Category(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Hata',
        iconData: Icons.error_outline,
        color: Colors.red,
      );
    }
  }

  /// Category nesnesini JSON'a dönüştürür
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconData': iconData.codePoint,
      'color': _color.value,
    };
  }

  /// Yeni özelliklerle Category kopyası oluşturur
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
      color: color ?? this._color,
    );
  }

  Color get color => Color.fromARGB(
        _color.alpha,
        _color.red,
        _color.green,
        _color.blue,
      );

  set color(Color value) {
    _color = value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          iconData.codePoint == other.iconData.codePoint &&
          _color.value == other._color.value;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      iconData.codePoint.hashCode ^
      _color.value.hashCode;

  @override
  String toString() =>
      'Category(id: $id, name: $name, iconData: ${iconData.codePoint}, color: ${_color.value})';
}