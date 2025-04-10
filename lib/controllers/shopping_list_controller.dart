import 'package:flutter/foundation.dart'; // ChangeNotifier için
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_item.dart';

class ShoppingListController extends ChangeNotifier {
  List<ShoppingItem> _items = [];
  static const _prefsKey = 'shopping_list_items'; // Kayıt için anahtar

  List<ShoppingItem> get items => _items; // View'ın erişeceği getter

  ShoppingListController() {
    _loadItems(); // Uygulama başlarken listeyi yükle
  }

  // Öğeyi listeye ekleme
  void addItem(String name) {
    if (name.trim().isEmpty) return; // Boş öğe eklenmesin

    final newItem = ShoppingItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(), // Basit unique ID
      name: name.trim(),
    );
    _items.add(newItem);
    _saveItems(); // Değişikliği kaydet
    notifyListeners(); // View'ı güncellemesi için haber ver
  }

  // Öğenin durumunu değiştirme (alındı/alınmadı)
  void toggleItemStatus(String id) {
    try {
      final item = _items.firstWhere((item) => item.id == id);
      item.isBought = !item.isBought;
      _saveItems();
      notifyListeners();
    } catch (e) {
      // Öğe bulunamazsa (nadir durum)
      if (kDebugMode) {
        print("Toggle Error: Item with id $id not found.");
      }
    }
  }

  // Öğeyi listeden silme
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    _saveItems();
    notifyListeners();
  }

  // Listeyi SharedPreferences'a kaydetme
  Future<void> _saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    // Her bir öğeyi JSON string'ine çevirip liste olarak kaydet
    List<String> itemsAsString =
        _items.map((item) => item.toJsonString()).toList();
    await prefs.setStringList(_prefsKey, itemsAsString);
  }

  // Listeyi SharedPreferences'dan yükleme
  Future<void> _loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsAsString = prefs.getStringList(_prefsKey);

    if (itemsAsString != null) {
      _items = itemsAsString
          .map((itemString) => ShoppingItem.fromJsonString(itemString))
          .toList();
    } else {
      _items = []; // Kayıtlı veri yoksa boş liste ile başla
    }
    notifyListeners(); // Yükleme sonrası View'ı güncelle
  }
}