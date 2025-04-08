// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ShoppingListModel(),
      child: const ShoppingListApp(),
    ),
  );
}

class ShoppingListApp extends StatelessWidget {
  const ShoppingListApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alışveriş Listem',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

// Model Sınıfları
class ShoppingItem {
  final String id;
  final String name;
  final String category;
  final String? note;
  bool isCompleted;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.category,
    this.note,
    this.isCompleted = false,
  });

  ShoppingItem copyWith({
    String? name,
    String? category,
    String? note,
    bool? isCompleted,
  }) {
    return ShoppingItem(
      id: this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      note: note ?? this.note,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'note': note,
      'isCompleted': isCompleted,
    };
  }

  factory ShoppingItem.fromJson(Map<String, dynamic> json) {
    return ShoppingItem(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      note: json['note'],
      isCompleted: json['isCompleted'],
    );
  }
}

class ShoppingListModel extends ChangeNotifier {
  List<ShoppingItem> _items = [];
  Set<String> _categories = {'Gıda', 'Temizlik', 'Kişisel Bakım', 'Diğer'};

  List<ShoppingItem> get items => _items;
  Set<String> get categories => _categories;

  ShoppingListModel() {
    loadData();
  }

  Future<void> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = prefs.getString('items');
    final categoriesJson = prefs.getString('categories');

    if (itemsJson != null) {
      final List<dynamic> decodedItems = jsonDecode(itemsJson);
      _items = decodedItems.map((item) => ShoppingItem.fromJson(item)).toList();
    }

    if (categoriesJson != null) {
      final List<dynamic> decodedCategories = jsonDecode(categoriesJson);
      _categories = Set<String>.from(decodedCategories);
    }

    notifyListeners();
  }

  Future<void> saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final itemsJson = jsonEncode(_items.map((item) => item.toJson()).toList());
    final categoriesJson = jsonEncode(_categories.toList());

    await prefs.setString('items', itemsJson);
    await prefs.setString('categories', categoriesJson);
  }

  void addItem(ShoppingItem item) {
    _items.add(item);
    saveData();
    notifyListeners();
  }

  void updateItem(ShoppingItem item) {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index != -1) {
      _items[index] = item;
      saveData();
      notifyListeners();
    }
  }

  void toggleItemCompletion(String id) {
    final index = _items.indexWhere((element) => element.id == id);
    if (index != -1) {
      _items[index] = _items[index].copyWith(isCompleted: !_items[index].isCompleted);
      saveData();
      notifyListeners();
    }
  }

  void removeItem(String id) {
    _items.removeWhere((element) => element.id == id);
    saveData();
    notifyListeners();
  }

  void addCategory(String category) {
    _categories.add(category);
    saveData();
    notifyListeners();
  }

  void removeCategory(String category) {
    _categories.remove(category);
    // Kategori silindiyse, o kategorideki öğeleri "Diğer" kategorisine taşı
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].category == category) {
        _items[i] = _items[i].copyWith(category: 'Diğer');
      }
    }
    saveData();
    notifyListeners();
  }

  List<ShoppingItem> getItemsByCategory(String category) {
    return _items.where((item) => item.category == category).toList();
  }
}

// Ana Sayfa
class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CategoryManagementPage()),
              );
            },
          ),
        ],
      ),
      body: const CategoryTabsView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AddItemDialog(),
    );
  }
}

// Kategori Sekmeli Görünüm
class CategoryTabsView extends StatelessWidget {
  const CategoryTabsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ShoppingListModel>(context);
    final categories = model.categories.toList();

    return DefaultTabController(
      length: categories.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: categories.map((category) => Tab(text: category)).toList(),
          ),
          Expanded(
            child: TabBarView(
              children: categories.map((category) => ItemListView(category: category)).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Öğe Listesi Görünümü
class ItemListView extends StatelessWidget {
  final String category;

  const ItemListView({Key? key, required this.category}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ShoppingListModel>(context);
    final categoryItems = model.getItemsByCategory(category);

    if (categoryItems.isEmpty) {
      return const Center(
        child: Text('Bu kategoride hiç öğe yok.'),
      );
    }

    return ListView.builder(
      itemCount: categoryItems.length,
      itemBuilder: (context, index) {
        final item = categoryItems[index];
        return Dismissible(
          key: Key(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) {
            model.removeItem(item.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${item.name} silindi')),
            );
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              title: Text(
                item.name,
                style: TextStyle(
                  decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: item.note != null && item.note!.isNotEmpty
                  ? Text(
                      item.note!,
                      style: TextStyle(
                        decoration: item.isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    )
                  : null,
              leading: Checkbox(
                value: item.isCompleted,
                onChanged: (value) {
                  model.toggleItemCompletion(item.id);
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  _showEditItemDialog(context, item);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEditItemDialog(BuildContext context, ShoppingItem item) {
    showDialog(
      context: context,
      builder: (context) => EditItemDialog(item: item),
    );
  }
}

// Öğe Ekleme İletişim Kutusu
class AddItemDialog extends StatefulWidget {
  const AddItemDialog({Key? key}) : super(key: key);

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();
  String _selectedCategory = 'Gıda';

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ShoppingListModel>(context);
    final categories = model.categories.toList();
    _selectedCategory = categories.first;

    return AlertDialog(
      title: const Text('Yeni Öğe Ekle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir ürün adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Not (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final newItem = ShoppingItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                category: _selectedCategory,
                note: _noteController.text.isNotEmpty ? _noteController.text : null,
              );
              model.addItem(newItem);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}

// Öğe Düzenleme İletişim Kutusu
class EditItemDialog extends StatefulWidget {
  final ShoppingItem item;

  const EditItemDialog({Key? key, required this.item}) : super(key: key);

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _noteController;
  late String _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _noteController = TextEditingController(text: widget.item.note ?? '');
    _selectedCategory = widget.item.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ShoppingListModel>(context);
    final categories = model.categories.toList();

    return AlertDialog(
      title: const Text('Öğeyi Düzenle'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Ürün Adı',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir ürün adı girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  border: OutlineInputBorder(),
                ),
                items: categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Not (İsteğe Bağlı)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final updatedItem = widget.item.copyWith(
                name: _nameController.text,
                category: _selectedCategory,
                note: _noteController.text.isNotEmpty ? _noteController.text : null,
              );
              model.updateItem(updatedItem);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}

// Kategori Yönetim Sayfası
class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({Key? key}) : super(key: key);

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final _categoryController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<ShoppingListModel>(context);
    final categories = model.categories.toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kategorileri Yönet'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Yeni Kategori',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final category = _categoryController.text.trim();
                    if (category.isNotEmpty && !categories.contains(category)) {
                      model.addCategory(category);
                      _categoryController.clear();
                    }
                  },
                  child: const Text('Ekle'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                // "Diğer" kategorisini silmeye izin verme
                final canDelete = category != 'Diğer';
                
                return ListTile(
                  title: Text(category),
                  trailing: canDelete
                      ? IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            _showDeleteCategoryDialog(context, category);
                          },
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog(BuildContext context, String category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategoriyi Sil'),
        content: Text(
          'Bu kategoriyi silmek istediğinizden emin misiniz? Bu kategorideki tüm öğeler "Diğer" kategorisine taşınacaktır.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final model = Provider.of<ShoppingListModel>(context, listen: false);
              model.removeCategory(category);
              Navigator.of(context).pop();
            },
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}