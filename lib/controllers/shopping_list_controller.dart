import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list_model.dart';
import 'dart:convert';

class ShoppingListController extends ChangeNotifier {
  static const String _prefsCategoriesKey = 'categories';
  static const String _prefsListsKey = 'shopping_lists';
  
  // Liste yönetimi
  final Map<String, List<ShoppingItem>> _shoppingLists = {};
  String? _activeListId;
  
  // Tüm listelerin bilgisi
  final List<ShoppingList> _allLists = [];
  List<ShoppingList> get allLists => _allLists;
  
  // Kategoriler
  final List<Category> _categories = [];
  List<Category> get categories => _categories;
  
  // Geçmiş listeler
  List<ShoppingList> _listHistory = [];
  List<ShoppingList> get listHistory => _listHistory;
  
  // Silinen öğeler
  final List<ShoppingItem> _deletedItems = [];
  
  // Getter'lar
  List<ShoppingItem> get items => _shoppingLists[_activeListId] ?? [];
  String? get activeListId => _activeListId;
  
  // Arama için
  String _searchTerm = '';
  String get searchTerm => _searchTerm;
  
  // Kategori bazlı öğeler
  Map<String, List<ShoppingItem>> get itemsByCategory {
    final Map<String, List<ShoppingItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.categoryId)) {
        grouped[item.categoryId] = [];
      }
      grouped[item.categoryId]!.add(item);
    }
    return grouped;
  }

  // Constructor
  ShoppingListController() {
    _loadData();
  }

  // Kategori işlemleri
  Category getCategoryById(String id) {
    return _categories.firstWhere(
      (cat) => cat.id == id,
      orElse: () => Category(
        id: 'uncategorized',
        name: 'Kategorisiz',
        iconData: Icons.help_outline,
        color: Colors.grey,
      ),
    );
  }

  void addCustomCategory(String name, IconData iconData, Color color) {
    final newCategory = Category(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      iconData: iconData,
      color: color,
    );
    _categories.add(newCategory);
    _saveData();
    notifyListeners();
  }

  // Liste işlemleri
  void createNewList(String name) {
    final listId = 'list_${DateTime.now().millisecondsSinceEpoch}';
    _shoppingLists[listId] = [];
    
    final newList = ShoppingList(
      id: listId,
      name: name,
      items: [],
      createdAt: DateTime.now(),
      icon: Icons.list_alt.codePoint,
    );
    
    _allLists.add(newList);
    _activeListId = listId;
    _saveData();
    notifyListeners();
  }

  void switchList(String listId) {
    if (_shoppingLists.containsKey(listId)) {
      _activeListId = listId;
      notifyListeners();
    }
  }

  void deleteList(String listId) {
    _shoppingLists.remove(listId);
    _allLists.removeWhere((list) => list.id == listId);
    if (_activeListId == listId) {
      _activeListId = _shoppingLists.isNotEmpty ? _shoppingLists.keys.first : null;
    }
    _saveData();
    notifyListeners();
  }

  void clearCurrentList() {
    _shoppingLists[_activeListId]?.clear();
    _saveData();
    notifyListeners();
  }

  // Öğe işlemleri
  void addItem(String name, String categoryId) {
    if (name.trim().isEmpty || _activeListId == null) return;
    
    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      categoryId: categoryId,
    );
    
    _shoppingLists[_activeListId]?.add(newItem);
    
    // Aktif listeyi güncelle
    final index = _allLists.indexWhere((list) => list.id == _activeListId);
    if (index != -1) {
      _allLists[index] = ShoppingList(
        id: _allLists[index].id,
        name: _allLists[index].name,
        items: _shoppingLists[_activeListId] ?? [],
        createdAt: _allLists[index].createdAt,
        icon: _allLists[index].icon,
      );
    }
    
    _saveData();
    notifyListeners();
  }

  void toggleItemStatus(String id) {
    final items = _shoppingLists[_activeListId];
    if (items == null) return;
    
    final index = items.indexWhere((item) => item.id == id);
    if (index != -1) {
      items[index].isBought = !items[index].isBought;
      _saveData();
      notifyListeners();
    }
  }

  ShoppingItem? removeItem(String id) {
    final items = _shoppingLists[_activeListId];
    if (items == null) return null;
    
    final index = items.indexWhere((item) => item.id == id);
    if (index != -1) {
      final item = items.removeAt(index);
      _deletedItems.add(item);
      _saveData();
      notifyListeners();
      return item;
    }
    return null;
  }

  // Arama işlemleri
  void updateSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  List<ShoppingItem> get filteredItems {
    if (_searchTerm.isEmpty) return items;
    return items.where((item) =>
      item.name.toLowerCase().contains(_searchTerm.toLowerCase()) ||
      getCategoryById(item.categoryId).name.toLowerCase().contains(_searchTerm.toLowerCase())
    ).toList();
  }

  // Geri alma işlemleri
  void undoDelete() {
    if (_deletedItems.isEmpty) return;
    
    final item = _deletedItems.removeLast();
    _shoppingLists[_activeListId]?.add(item);
    _saveData();
    notifyListeners();
  }

  // Geçmiş işlemleri
  void saveToHistory() {
    if (items.isEmpty) return;
    
    _listHistory.add(ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Liste ${_listHistory.length + 1}',
      items: List.from(items),
      createdAt: DateTime.now(),
    ));
    _saveData();
  }

  void restoreFromHistory(String listId) {
    final historicList = _listHistory.firstWhere((list) => list.id == listId);
    _shoppingLists[_activeListId]?.clear();
    _shoppingLists[_activeListId]?.addAll(historicList.items);
    _saveData();
    notifyListeners();
  }

  // İlerleme yüzdesi hesaplama
  double getCompletionPercentage(String listId) {
    final items = _shoppingLists[listId];
    if (items == null || items.isEmpty) return 0;
    return (items.where((item) => item.isBought).length / items.length) * 100;
  }

  // Veri kaydetme/yükleme
  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Kategorileri kaydet
    await prefs.setStringList(
      _prefsCategoriesKey,
      _categories.map((c) => jsonEncode(c.toJson())).toList(),
    );
    
    // Tüm listeleri kaydet
    await prefs.setStringList(
      _prefsListsKey,
      _allLists.map((list) => jsonEncode(list.toJson())).toList(),
    );
    
    // Her listenin öğelerini kaydet
    for (final listId in _shoppingLists.keys) {
      await prefs.setStringList(
        'list_items_$listId',
        _shoppingLists[listId]?.map((item) => jsonEncode(item.toJson())).toList() ?? [],
      );
    }
    
    // Liste geçmişini kaydet
    await prefs.setStringList(
      'list_history',
      _listHistory.map((list) => jsonEncode(list.toJson())).toList(),
    );
    
    // Silinen öğeleri kaydet
    await prefs.setStringList(
      'deleted_items',
      _deletedItems.map((item) => jsonEncode(item.toJson())).toList(),
    );
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Kategorileri yükle
    final categoriesJson = prefs.getStringList(_prefsCategoriesKey);
    if (categoriesJson != null) {
      _categories.clear();
      _categories.addAll(
        categoriesJson.map((json) => Category.fromJson(jsonDecode(json))),
      );
    } else {
      _categories.addAll(_getDefaultCategories());
    }
    
    // Tüm listeleri yükle
    final listsJson = prefs.getStringList(_prefsListsKey);
    if (listsJson != null) {
      _allLists.clear();
      _allLists.addAll(
        listsJson.map((json) => ShoppingList.fromJson(jsonDecode(json))),
      );
      
      // Her listenin öğelerini yükle
      for (final list in _allLists) {
        final itemsJson = prefs.getStringList('list_items_${list.id}');
        if (itemsJson != null) {
          _shoppingLists[list.id] = itemsJson
              .map((json) => ShoppingItem.fromJson(jsonDecode(json)))
              .toList();
        } else {
          _shoppingLists[list.id] = [];
        }
      }
      
      // Aktif listeyi ayarla
      if (_allLists.isNotEmpty && _activeListId == null) {
        _activeListId = _allLists.first.id;
      }
    }
    
    // Liste geçmişini yükle
    final historyJson = prefs.getStringList('list_history');
    if (historyJson != null) {
      _listHistory = historyJson
          .map((json) => ShoppingList.fromJson(jsonDecode(json)))
          .toList();
    }
    
    // Silinen öğeleri yükle
    final deletedJson = prefs.getStringList('deleted_items');
    if (deletedJson != null) {
      _deletedItems.addAll(
        deletedJson.map((json) => ShoppingItem.fromJson(jsonDecode(json))),
      );
    }
    
    notifyListeners();
  }

  List<Category> _getDefaultCategories() => [
    Category(id: 'meyve_sebze', name: 'Meyve & Sebze', iconData: Icons.local_florist, color: Colors.green),
    Category(id: 'sut_urunleri', name: 'Süt & Kahvaltılık', iconData: Icons.egg, color: Colors.amber),
    Category(id: 'et_balik', name: 'Et & Balık', iconData: Icons.set_meal, color: Colors.redAccent),
    Category(id: 'elektronik', name: 'Elektronik', iconData: Icons.devices, color: Colors.blue),
    Category(id: 'kirtasiye', name: 'Kırtasiye', iconData: Icons.edit, color: Colors.purple),
    Category(id: 'temizlik', name: 'Temizlik', iconData: Icons.cleaning_services, color: Colors.cyan),
    Category(id: 'giyim', name: 'Giyim', iconData: Icons.checkroom, color: Colors.pink),
    Category(id: 'kozmetik', name: 'Kozmetik', iconData: Icons.face, color: Colors.orange),
    Category(id: 'oyuncak', name: 'Oyuncak & Hobi', iconData: Icons.toys, color: Colors.deepPurple),
    Category(id: 'ev_esyalari', name: 'Ev Eşyaları', iconData: Icons.chair, color: Colors.brown),
    Category(id: 'diger', name: 'Diğer', iconData: Icons.more_horiz, color: Colors.grey),
  ];
}