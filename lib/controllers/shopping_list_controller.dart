import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import 'dart:convert'; // jsonDecode için

class ShoppingListController extends ChangeNotifier {
  List<Category> _categories = [];
  List<ShoppingItem> _items = [];

  static const _prefsCategoriesKey = 'shopping_list_categories';
  static const _prefsItemsKey = 'shopping_list_items_v2'; // Anahtar adını değiştirelim

  // Getter'lar
  List<Category> get categories => _categories;
  List<ShoppingItem> get items => _items;

  // Kategorilere göre gruplanmış öğeler için getter
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (var category in _categories) {
      grouped[category.id] = []; // Her kategori için boş liste oluştur
    }
    // Kategorisizler için özel bir anahtar
    grouped['uncategorized'] = [];

    for (var item in _items) {
      // Eğer öğenin kategorisi tanımlı kategorilerde yoksa veya null ise 'uncategorized'a ekle
      if (grouped.containsKey(item.categoryId)) {
        grouped[item.categoryId]!.add(item);
      } else {
         grouped['uncategorized']!.add(item);
      }
    }
    return grouped;
  }

  Category getCategoryById(String id) {
     return _categories.firstWhere((cat) => cat.id == id,
             orElse: () => Category(id: 'uncategorized', name: 'Kategorisiz', iconData: Icons.label_off, color: Colors.grey)); // Bulamazsa varsayılan döndür
  }


  ShoppingListController() {
    _loadData();
  }

  // --- Kategori Yönetimi ---
  void addCategory(String name, IconData icon, Color color) {
      if (name.trim().isEmpty) return;
      final newCategory = Category(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name.trim(),
        iconData: icon,
        color: color,
      );
      _categories.add(newCategory);
      _saveData();
      notifyListeners();
  }

  // (İleride Kategori Silme/Düzenleme eklenebilir)

  // --- Öğe Yönetimi ---
  void addItem(String name, String categoryId) {
    if (name.trim().isEmpty) return;
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      categoryId: categoryId.isEmpty ? 'uncategorized' : categoryId, // Boşsa kategorisize ata
    );
    _items.add(newItem);
    _saveData();
    notifyListeners(); // View'ı güncelle (AnimatedList yoksa bu gerekli)
  }

  void toggleItemStatus(String id) {
    try {
      final item = _items.firstWhere((item) => item.id == id);
      item.isBought = !item.isBought;
      _saveData();
      notifyListeners();
    } catch (e) {
      debugPrint("Toggle Error: Item with id $id not found.");
    }
  }

  ShoppingItem? removeItem(String id) {
     ShoppingItem? removedItem;
     int removeIndex = _items.indexWhere((item) => item.id == id);

     if (removeIndex != -1) {
        removedItem = _items.removeAt(removeIndex);
        _saveData();
        notifyListeners(); // View'ı güncelle
     }
     return removedItem;
  }


  // --- Veri Kaydetme/Yükleme ---
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> categoriesAsString = _categories.map((c) => c.toJsonString()).toList();
    List<String> itemsAsString = _items.map((i) => i.toJsonString()).toList();

    await prefs.setStringList(_prefsCategoriesKey, categoriesAsString);
    await prefs.setStringList(_prefsItemsKey, itemsAsString);
     debugPrint("Data saved!"); // Kaydetme kontrolü
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();

    // Kategorileri yükle
    final categoriesAsString = prefs.getStringList(_prefsCategoriesKey);
    if (categoriesAsString != null) {
      _categories = categoriesAsString
          .map((c) => Category.fromJsonString(c))
          .toList();
    } else {
       // İlk çalıştırmada varsayılan kategoriler
      _categories = _getDefaultCategories();
    }

    // Öğeleri yükle
    final itemsAsString = prefs.getStringList(_prefsItemsKey);
    if (itemsAsString != null) {
      _items = itemsAsString
          .map((i) => ShoppingItem.fromJsonString(i))
          .toList();
    } else {
      _items = [];
    }
     debugPrint("Data loaded! Categories: ${_categories.length}, Items: ${_items.length}"); // Yükleme kontrolü
    notifyListeners();
  }

  // Varsayılan kategoriler (İlk açılış için)
  List<Category> _getDefaultCategories() {
    return [
      Category(id: 'meyve_sebze', name: 'Meyve & Sebze', iconData: Icons.local_florist, color: Colors.green),
      Category(id: 'sut_urunleri', name: 'Süt Ürünleri & Kahvaltılık', iconData: Icons.egg, color: Colors.amber),
      Category(id: 'et_balik', name: 'Et & Balık', iconData: Icons.set_meal, color: Colors.redAccent),
      Category(id: 'temizlik', name: 'Temizlik & Ev Bakım', iconData: Icons.cleaning_services, color: Colors.lightBlue),
      Category(id: 'icecek', name: 'İçecek', iconData: Icons.local_bar, color: Colors.purpleAccent),
      Category(id: 'kisisel_bakim', name: 'Kişisel Bakım', iconData: Icons.spa, color: Colors.pinkAccent),
      Category(id: 'uncategorized', name: 'Diğer', iconData: Icons.label_outline, color: Colors.blueGrey), // Kategorisizler için
    ];
  }
}