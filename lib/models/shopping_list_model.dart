import 'package:flutter/material.dart';
import 'shopping_item.dart';

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
  });

  double get completionPercentage {
    if (items.isEmpty) return 0;
    return items.where((item) => item.isBought).length / items.length * 100;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'items': items.map((item) => item.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'icon': icon,
    'color': color?.value,
  };

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
    id: json['id'],
    name: json['name'],
    items: (json['items'] as List).map((i) => ShoppingItem.fromJson(i)).toList(),
    createdAt: DateTime.parse(json['createdAt']),
    icon: json['icon'],
    color: json['color'] != null ? Color(json['color']) : null,
  );
}