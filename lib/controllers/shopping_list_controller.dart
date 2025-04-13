import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../models/shopping_list_model.dart';
import 'dart:convert';

class ShoppingListController extends ChangeNotifier {
  final List<ShoppingList> _lists = [];
  final List<Category> _categories = [];
  ShoppingList? _currentList;
  final SharedPreferences _prefs;
  bool _isLoading = true;

  ShoppingListController(this._prefs) {
    Future.microtask(() => _loadData());
  }

  // Getters
  List<ShoppingList> get lists => List.unmodifiable(_lists);
  List<Category> get categories => List.unmodifiable(_categories);
  ShoppingList? get currentList => _currentList;
  bool get hasLists => _lists.isNotEmpty;
  List<ShoppingItem> get items => _currentList?.items ?? [];
  String? get activeListId => _currentList?.id; // Null olabileceğini belirtiyoruz
  List<ShoppingList> get allLists => List.unmodifiable(_lists);
  bool get isLoading => _isLoading;
  String get searchTerm => _searchTerm;
  List<ShoppingList> get listHistory => _listHistory;

  // Fields
  String _searchTerm = '';
  final List<ShoppingList> _listHistory = [];
  ShoppingItem? _lastDeletedItem;

  // Load saved data
  Future<void> _loadData() async {
    try {
      // Load categories
      final categoriesJson = _prefs.getStringList('categories') ?? [];
      _categories.clear();
      if (categoriesJson.isEmpty) {
        // Varsayılan kategorileri ekle
        _categories.addAll([
          Category(
            id: 'groceries',
            name: 'Gıda',
            iconData: Icons.shopping_basket,
            color: Colors.green,
          ),
          Category(
            id: 'electronics',
            name: 'Elektronik',
            iconData: Icons.devices,
            color: Colors.blue,
          ),
          Category(
            id: 'clothing',
            name: 'Giyim',
            iconData: Icons.checkroom,
            color: Colors.purple,
          ),
          Category(
            id: 'home',
            name: 'Ev',
            iconData: Icons.home,
            color: Colors.orange,
          ),
        ]);
        await _saveData(); // Varsayılan kategorileri kaydet
      } else {
        _categories.addAll(
          categoriesJson
              .map((json) => Category.fromJson(Map<String, dynamic>.from(
                  const JsonDecoder().convert(json))))
              .toList(),
        );
      }

      // Load shopping lists
      final listsJson = _prefs.getStringList('shopping_lists') ?? [];
      _lists.clear();
      _lists.addAll(
        listsJson
            .map((json) => ShoppingList.fromJson(
                Map<String, dynamic>.from(const JsonDecoder().convert(json))))
            .toList(),
      );

      // Load current list
      final currentListId = _prefs.getString('current_list_id');
      if (currentListId != null && _lists.isNotEmpty) {
        _currentList = _lists.firstWhere(
          (list) => list.id == currentListId,
          orElse: () => _lists.first,
        );
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  // Save all data
  Future<void> _saveData() async {
    try {
      // Save categories
      await _prefs.setStringList(
        'categories',
        _categories
            .map((category) => const JsonEncoder().convert(category.toJson()))
            .toList(),
      );

      // Save shopping lists
      await _prefs.setStringList(
        'shopping_lists',
        _lists
            .map((list) => const JsonEncoder().convert(list.toJson()))
            .toList(),
      );

      // Save current list ID
      if (_currentList != null) {
        await _prefs.setString('current_list_id', _currentList!.id);
      } else {
        await _prefs.remove('current_list_id');
      }
    } catch (e) {
      debugPrint('Veri kaydetme hatası: $e');
      // Handle error appropriately
    }
  }

  // List management
  Future<void> createList(String name, {int? icon, Color? color}) async {
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      items: [],
      createdAt: DateTime.now(),
      icon: icon,
      color: color,
    );

    _lists.add(newList);
    _currentList = newList;
    await _saveData();
    notifyListeners();
  }

  Future<void> updateList(ShoppingList list) async {
    final index = _lists.indexWhere((l) => l.id == list.id);
    if (index != -1) {
      _lists[index] = list;
      if (_currentList?.id == list.id) {
        _currentList = list;
      }
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> deleteList(String listId) async {
    _lists.removeWhere((list) => list.id == listId);
    if (_currentList?.id == listId) {
      _currentList = _lists.isNotEmpty ? _lists.first : null;
    }
    await _saveData();
    notifyListeners();
  }

  Future<void> setCurrentList(String listId) async {
    final list = _lists.firstWhere((l) => l.id == listId);
    _currentList = list;
    await _saveData();
    notifyListeners();
  }

  // Category management
  Future<void> addCategory(Category category) async {
    if (!_categories.any((c) => c.id == category.id)) {
      _categories.add(category);
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> updateCategory(Category category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((category) => category.id == categoryId);
    // Update items with deleted category
    for (var list in _lists) {
      for (var item in list.items) {
        if (item.categoryId == categoryId) {
          item.categoryId = 'uncategorized';
        }
      }
    }
    await _saveData();
    notifyListeners();
  }

  // Item management
  Future<void> addShoppingItem(ShoppingItem item) async {
    if (_currentList != null) {
      final updatedList = _currentList!.copyWith(
        items: [..._currentList!.items, item],
      );
      await updateList(updatedList);
    }
  }

  // Öğe ekleme - String ve categoryId parametreleriyle
  Future<void> addItem(String name, String categoryId) async {
    if (_currentList != null) {
      final newItem = ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        categoryId: categoryId,
        createdAt: DateTime.now(),
      );
      await addShoppingItem(newItem);
    }
  }

  Future<ShoppingItem?> removeItem(String itemId) async {
    if (_currentList != null) {
      final items = List<ShoppingItem>.from(_currentList!.items);
      final index = items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        _lastDeletedItem = items[index];
        items.removeAt(index);
        final updatedList = _currentList!.copyWith(items: items);
        await updateList(updatedList);
        return _lastDeletedItem;
      }
    }
    return null;
  }

  Future<void> updateItem(ShoppingItem item) async {
    if (_currentList != null) {
      final items = List<ShoppingItem>.from(_currentList!.items);
      final index = items.indexWhere((i) => i.id == item.id);
      if (index != -1) {
        items[index] = item;
        final updatedList = _currentList!.copyWith(items: items);
        await updateList(updatedList);
      }
    }
  }

  Future<void> deleteItem(String itemId) async {
    if (_currentList != null) {
      final items = _currentList!.items.where((item) => item.id != itemId).toList();
      final updatedList = _currentList!.copyWith(items: items);
      await updateList(updatedList);
    }
  }

  Future<void> toggleItemStatus(String itemId) async {
    if (_currentList != null) {
      final items = List<ShoppingItem>.from(_currentList!.items);
      final index = items.indexWhere((item) => item.id == itemId);
      if (index != -1) {
        final item = items[index];
        if (item.isBought) {
          item.markAsNotBought();
        } else {
          item.markAsBought();
        }
        final updatedList = _currentList!.copyWith(items: items);
        await updateList(updatedList);
      }
    }
  }

  // Statistics and filtering
  List<ShoppingItem> getItemsByCategory(String categoryId) {
    return _currentList?.items
            .where((item) => item.categoryId == categoryId)
            .toList() ??
        [];
  }

  int getCompletedItemsCount() {
    return _currentList?.items.where((item) => item.isBought).length ?? 0;
  }

  double getCompletionPercentage() {
    if (_currentList == null) return 0.0;
    final totalItems = _currentList!.items.length;
    if (totalItems == 0) return 0.0;
    final completedItems = _currentList!.items.where((item) => item.isBought).length;
    return (completedItems / totalItems) * 100;
  }

  // Sort and filter options
  void sortItemsByName({bool ascending = true}) {
    if (_currentList != null) {
      final items = List<ShoppingItem>.from(_currentList!.items)
        ..sort((a, b) => ascending
            ? a.name.compareTo(b.name)
            : b.name.compareTo(a.name));
      final updatedList = _currentList!.copyWith(items: items);
      updateList(updatedList);
    }
  }

  void sortItemsByCategory() {
    if (_currentList != null) {
      final items = List<ShoppingItem>.from(_currentList!.items)
        ..sort((a, b) => a.categoryId.compareTo(b.categoryId));
      final updatedList = _currentList!.copyWith(items: items);
      updateList(updatedList);
    }
  }

  List<ShoppingItem> filterItems({
    String? searchQuery,
    String? categoryId,
    bool? isBought,
  }) {
    if (_currentList == null) return [];

    return _currentList!.items.where((item) {
      if (searchQuery != null &&
          !item.name.toLowerCase().contains(searchQuery.toLowerCase())) {
        return false;
      }
      if (categoryId != null && item.categoryId != categoryId) {
        return false;
      }
      if (isBought != null && item.isBought != isBought) {
        return false;
      }
      return true;
    }).toList();
  }

  void updateSearchTerm(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  Future<void> createNewList(String name) async {
    await createList(name);
  }

  void clearCurrentList() {
    if (_currentList != null) {
      final clearedList = _currentList!.copyWith(items: []);
      updateList(clearedList);
    }
  }

  void undoDelete() {
    if (_lastDeletedItem != null && _currentList != null) {
      addShoppingItem(_lastDeletedItem!);
      _lastDeletedItem = null;
      notifyListeners();
    }
  }

  Future<bool> initializeData() async {
    await _loadData();
    return true;
  }

  Map<String, List<ShoppingItem>> get itemsByCategory {
    if (_currentList == null) return {};
    return _currentList!.itemsByCategory;
  }

  double getListCompletionPercentage(String listId) {
    final list = _lists.firstWhere((l) => l.id == listId);
    return list.completionPercentage;
  }

  void restoreFromHistory(String listId) {
    // Implement restore functionality
  }

  Category getCategoryById(String categoryId) {
    return _categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(
        id: 'uncategorized',
        name: 'Kategorisiz',
        color: Colors.grey,
        iconData: Icons.category_outlined,
      ),
    );
  }

  Future<void> addCustomCategory(String name, IconData icon, Color color) async {
    final category = Category(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name, 
      color: color,
      iconData: icon,
    );
    await addCategory(category);
  }
}