import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../controllers/shopping_list_controller.dart';
import '../models/shopping_list_model.dart';
import '../providers/theme_provider.dart';
import 'shopping_list_view.dart';

class ListSelectionView extends StatefulWidget {
  const ListSelectionView({super.key});

  @override
  State<ListSelectionView> createState() => _ListSelectionViewState();
}

class _ListSelectionViewState extends State<ListSelectionView> with TickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  late AnimationController _backgroundController;
  int _currentColorIndex = 0;

  @override
  void initState() {
    super.initState();
    _backgroundController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    _backgroundController.addListener(() {
      if (_backgroundController.value >= 1.0) {
        setState(() {
          _currentColorIndex = (_currentColorIndex + 1) % ThemeProvider.colorPalette.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _createNewList(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Liste Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Liste Adı',
                hintText: 'Liste için bir isim girin',
              ),
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  context.read<ShoppingListController>().createList(value);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final text = _searchController.text.trim();
              if (text.isNotEmpty) {
                context.read<ShoppingListController>().createList(text);
                Navigator.pop(context);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showColorPaletteDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Renk Seç',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ThemeProvider.colorPalette.entries.map((entry) {
                  return InkWell(
                    onTap: () {
                      context.read<ThemeProvider>().setPrimaryColor(entry.value);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: entry.value,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: entry.value.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: context.watch<ThemeProvider>().primaryColor == entry.value
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final controller = context.watch<ShoppingListController>();
    final lists = controller.lists;
    
    final filteredLists = lists.where((list) =>
        list.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listeleri'),
        actions: [
          IconButton(
            icon: const Icon(Icons.palette),
            onPressed: _showColorPaletteDialog,
          ),
          IconButton(
            icon: Icon(themeProvider.isDarkMode 
                ? Icons.light_mode 
                : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Animasyonlu arka plan gradyanı
          AnimatedBuilder(
            animation: _backgroundController,
            builder: (context, child) {
              final colors = ThemeProvider.colorPalette.values.toList();
              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors[_currentColorIndex].withOpacity(0.1),
                      colors[(_currentColorIndex + 1) % colors.length].withOpacity(0.1),
                    ],
                  ),
                ),
              );
            },
          ),
          // Liste içeriği
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Liste ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: filteredLists.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.asset(
                                'assets/animations/empty_cart.json',
                                width: 200,
                                height: 200,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                lists.isEmpty
                                    ? 'Henüz liste oluşturmadınız'
                                    : 'Arama sonucu bulunamadı',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredLists.length,
                          itemBuilder: (context, index) {
                            final list = filteredLists[index];
                            return _buildListCard(context, list, controller);
                          },
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewList(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildListCard(BuildContext context, ShoppingList list, ShoppingListController controller) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: list.color ?? Theme.of(context).primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            list.icon != null
                ? IconData(list.icon!, fontFamily: 'MaterialIcons')
                : Icons.list,
            color: Colors.white,
          ),
        ),
        title: Text(list.name),
        subtitle: Text(
          '${list.items.length} ürün - %${list.completionPercentage.toStringAsFixed(0)} tamamlandı',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _editList(context, list),
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteList(context, list),
            ),
          ],
        ),
        onTap: () {
          controller.setCurrentList(list.id);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ShoppingListView(),
            ),
          );
        },
      ),
    );
  }

  void _editList(BuildContext context, ShoppingList list) {
    final nameController = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Liste Adı',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                final updatedList = list.copyWith(name: newName);
                context.read<ShoppingListController>().updateList(updatedList);
                Navigator.pop(context);
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _deleteList(BuildContext context, ShoppingList list) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi Sil'),
        content: Text('${list.name} listesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              context.read<ShoppingListController>().deleteList(list.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}