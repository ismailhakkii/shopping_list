import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
// Removed intl package import
import '../controllers/shopping_list_controller.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../providers/theme_provider.dart';
import '../widgets/color_picker.dart';
import '../widgets/icon_picker.dart';

// Added a custom date formatting function
String formatDateTime(DateTime dateTime) {
  return "${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
}

class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key});

  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> with TickerProviderStateMixin {
  final Map<String, AnimationController> _checkAnimControllers = {};
  final Map<String, Animation<double>> _checkAnimations = {};
  late ShoppingListController _controller;
  bool _isSearching = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = Provider.of<ShoppingListController>(context);
    _prepareCheckAnimations(_controller.items);
  }

  @override
  void dispose() {
    for (var controller in _checkAnimControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              const Text('Yükleniyor...'),
            ],
          ),
        ),
      );
    }

    if (_controller.activeListId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.list_alt_outlined,
                size: 64,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 16),
              Text(
                'Lütfen bir liste seçin veya oluşturun',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showNewListDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Yeni Liste Oluştur'),
              ),
            ],
          ),
        ),
      );
    }

    final activeList = _controller.allLists.firstWhere(
      (list) => list.id == _controller.activeListId,
    );

    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: _isSearching
            ? _buildSearchField()
            : Text(
                activeList.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: _buildAppBarActions(context),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_controller.items.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                child: _buildProgressIndicator(),
              ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).scaffoldBackgroundColor,
                      Theme.of(context).colorScheme.surface,
                    ],
                  ),
                ),
                child: _controller.categories.isEmpty && _controller.items.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () async {
                          await _controller.initializeData();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: _controller.categories.length,
                          itemBuilder: (context, index) {
                            final category = _controller.categories[index];
                            final itemsInCategory = _controller.itemsByCategory[category.id] ?? [];
                            
                            if (_controller.searchTerm.isNotEmpty &&
                                !itemsInCategory.any((item) =>
                                    item.name.toLowerCase().contains(_controller.searchTerm.toLowerCase()) ||
                                    category.name.toLowerCase().contains(_controller.searchTerm.toLowerCase()))) {
                              return const SizedBox.shrink();
                            }
                            
                            return _buildCategoryExpansionTile(category, itemsInCategory);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _controller.items.isEmpty ? 1.2 : 1.0,
        duration: const Duration(milliseconds: 300),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddItemDialog(context, _controller),
          label: const Text('Yeni Öğe'),
          icon: const Icon(Icons.add_shopping_cart),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(_isSearching ? Icons.close : Icons.search),
        onPressed: () {
          setState(() {
            _isSearching = !_isSearching;
            if (!_isSearching) {
              _controller.updateSearchTerm('');
            }
          });
        },
      ),
      PopupMenuButton(
        icon: const Icon(Icons.more_vert),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Geçmiş'),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => _showHistoryDialog(context),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('Yeni Liste'),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => _showNewListDialog(context),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.cleaning_services),
              title: const Text('Listeyi Temizle'),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => _showClearListDialog(context),
          ),
          PopupMenuItem(
            child: ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Yeni Kategori'),
              contentPadding: EdgeInsets.zero,
            ),
            onTap: () => _showAddCategoryDialog(context),
          ),
          PopupMenuItem(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return ListTile(
                  leading: Icon(
                    themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  ),
                  title: Text(
                    themeProvider.isDarkMode ? 'Açık Tema' : 'Koyu Tema',
                  ),
                  contentPadding: EdgeInsets.zero,
                  onTap: () => themeProvider.toggleTheme(),
                );
              },
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Öğe veya kategori ara...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Theme.of(context).hintColor),
      ),
      style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      onChanged: (value) => _controller.updateSearchTerm(value),
    );
  }

  void _showHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Liste Geçmişi'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _controller.listHistory.length,  // _listHistory yerine listHistory getter'ı kullan
            itemBuilder: (context, index) {
              final list = _controller.listHistory[index];  // _listHistory yerine listHistory getter'ı kullan
              return ListTile(
                leading: const Icon(Icons.history),
                title: Text(list.name),
                subtitle: Text(
                  '${list.items.length} öğe • ${formatDateTime(list.createdAt)}',
                ),
                trailing: Text(
                  '%${list.completionPercentage.toStringAsFixed(0)} tamamlandı',
                ),
                onTap: () {
                  _controller.restoreFromHistory(list.id);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${list.name} geri yüklendi'),
                      action: SnackBarAction(
                        label: 'Tamam',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final listId = _controller.activeListId;
    if (listId == null) return const SizedBox.shrink();
    
    final completionPercentage = _controller.getCompletionPercentage();
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tamamlanan: %${completionPercentage.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                'Kalan: ${_controller.items.where((item) => !item.isBought).length} öğe',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: completionPercentage / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              completionPercentage == 100 ? Colors.green : Theme.of(context).primaryColor,
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  void _showNewListDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Liste Oluştur'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: 'Liste adı',
            prefixIcon: Icon(Icons.list_alt),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _controller.createNewList(textController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showClearListDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Listeyi Temizle'),
        content: const Text('Bu listedeki tüm öğeler silinecek. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.clearCurrentList();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;
    IconData selectedIcon = Icons.category;
    String? errorText;
    late BuildContext dialogContext;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        dialogContext = context;
        return StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9, // Responsive width
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView( // Prevents overflow issues
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Yeni Kategori',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Kategori Adı',
                        prefixIcon: const Icon(Icons.label),
                        errorText: errorText,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (value) {
                        if (errorText != null) {
                          setState(() => errorText = null);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Renk Seç',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    ColorPickerWidget(
                      selectedColor: selectedColor,
                      onColorChanged: (color) => setState(() => selectedColor = color),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'İkon Seç',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    IconPickerWidget(
                      selectedIcon: selectedIcon,
                      onIconChanged: (icon) => setState(() => selectedIcon = icon),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            if (nameController.text.trim().isEmpty) {
                              setState(() => errorText = 'Kategori adı boş olamaz');
                              return;
                            }

                            try {
                              await _controller.addCustomCategory(
                                nameController.text,
                                selectedIcon,
                                selectedColor,
                              );
                              
                              if (!mounted) return;
                              
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${nameController.text} kategorisi eklendi'),
                                  backgroundColor: selectedColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => errorText = e.toString());
                            }
                          },
                          child: const Text('Ekle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

   Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/animations/empty_cart.json',
            width: 250,
            height: 250,
            repeat: true,
          ),
          const SizedBox(height: 20),
          Text(
            'Henüz alışveriş listeniz boş',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni öğeler eklemek için + butonuna dokunun',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  // Kategori bazlı öğe listesi
  Widget _buildCategoryExpansionTile(Category category, List<ShoppingItem> items) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: category.color.withAlpha(77),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          key: PageStorageKey(category.id),
          initiallyExpanded: _controller.searchTerm.isNotEmpty,
          leading: CircleAvatar(
            backgroundColor: category.color.withAlpha(25),
            child: Icon(category.iconData, color: category.color),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: category.color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.where((item) => !item.isBought).length}/${items.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: category.color,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          subtitle: items.isNotEmpty
              ? LinearProgressIndicator(
                  value: items.where((item) => item.isBought).length / items.length,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(category.color),
                  minHeight: 2,
                )
              : null,
          children: items.isEmpty 
              ? [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Bu kategoride henüz öğe yok',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                ]
              : items.map((item) => _buildShoppingItemWidget(item)).toList(),
        ),
      ),
    );
  }

  // Alışveriş öğesi widget'ı
  Widget _buildShoppingItemWidget(ShoppingItem item) {
    final category = _controller.getCategoryById(item.categoryId);
    final animController = _checkAnimControllers[item.id];
    final animation = _checkAnimations[item.id];

    if (animController == null || animation == null) {
      return const SizedBox.shrink();
    }

    return Dismissible(
      key: Key('item_${item.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.delete_outline, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              'Sil',
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
      onDismissed: (direction) async {
        final removedItem = await _controller.removeItem(item.id);
        if (!mounted) return;
        
        if (removedItem != null) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} silindi'),
              action: SnackBarAction(
                label: 'Geri Al',
                onPressed: () => _controller.undoDelete(),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).size.height * 0.1,
                left: 16,
                right: 16,
              ),
            ),
          );
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: item.isBought
              ? Theme.of(context).colorScheme.surface
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: item.isBought
                ? Colors.grey.shade300
                : category.color.withAlpha(128), // 0.5 -> 128
            width: 1,
          ),
          boxShadow: [
            if (!item.isBought)
              BoxShadow(
                color: category.color.withAlpha(25), // 0.1 -> 25
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: ScaleTransition(
            scale: animation,
            child: InkWell(
              onTap: () {
                _controller.toggleItemStatus(item.id);
                if (item.isBought) {
                  animController.forward();
                } else {
                  animController.reverse();
                }
              },
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: item.isBought
                      ? category.color.withAlpha(25) // 0.1 -> 25
                      : Colors.transparent,
                  border: Border.all(
                    color: item.isBought
                        ? category.color
                        : Colors.grey.shade400,
                    width: 2,
                  ),
                ),
                child: item.isBought
                    ? Icon(Icons.check, size: 20, color: category.color)
                    : const SizedBox(width: 20, height: 20),
              ),
            ),
          ),
          title: Text(
            item.name,
            style: TextStyle(
              decoration: item.isBought ? TextDecoration.lineThrough : null,
              color: item.isBought ? Colors.grey : null,
            ),
          ),
          trailing: Chip(
            label: Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                color: category.color,
              ),
            ),
            backgroundColor: category.color.withAlpha(25), // 0.1 -> 25
            padding: EdgeInsets.zero,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
    );
  }

  // Yeni öğe ekleme dialogu (Kategori seçimi eklendi)
  void _showAddItemDialog(BuildContext context, ShoppingListController controller) {
    final textController = TextEditingController();
    String? selectedCategoryId = controller.categories.isNotEmpty ? controller.categories.first.id : null;
    int quantity = 1;
    String? unit;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Yeni Öğe Ekle',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Öğe Adı',
                        hintText: 'Örn: Ekmek',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (controller.categories.isNotEmpty)
                      DropdownButtonFormField<String>(
                        value: selectedCategoryId,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: controller.categories.map((category) {
                          return DropdownMenuItem(
                            value: category.id,
                            child: Row(
                              children: [
                                Icon(category.iconData, color: category.color),
                                const SizedBox(width: 8),
                                Text(category.name),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCategoryId = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Miktar',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                quantity = int.tryParse(value) ?? 1;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Birim (Opsiyonel)',
                              hintText: 'Örn: kg, adet',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                unit = value.isEmpty ? null : value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('İptal'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (textController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen bir öğe adı girin'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            if (selectedCategoryId == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Lütfen bir kategori seçin'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            final newItem = ShoppingItem(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              name: textController.text.trim(),
                              categoryId: selectedCategoryId!,
                              quantity: quantity,
                              unit: unit,
                            );

                            controller.addShoppingItem(newItem);
                            Navigator.pop(context);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${newItem.name} eklendi'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Ekle'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _prepareCheckAnimations(List<ShoppingItem> items) {
    // Önce artık kullanılmayan controllerleri dispose et
    final currentIds = items.map((item) => item.id).toSet();
    _checkAnimControllers.keys
        .where((id) => !currentIds.contains(id))
        .toList()
        .forEach((id) {
      _checkAnimControllers[id]?.dispose();
      _checkAnimControllers.remove(id);
      _checkAnimations.remove(id);
    });

    // Her öğe için animasyon controller oluştur
    for (final item in items) {
      if (!_checkAnimControllers.containsKey(item.id)) {
        final controller = AnimationController(
          duration: const Duration(milliseconds: 300),
          vsync: this,
        );
        
        final animation = CurvedAnimation(
          parent: controller,
          curve: Curves.easeInOut,
        );

        _checkAnimControllers[item.id] = controller;
        _checkAnimations[item.id] = animation;

        if (item.isBought) {
          controller.forward();
        }
      }
    }
  }

}
