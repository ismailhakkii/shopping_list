import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../controllers/shopping_list_controller.dart';
import '../models/category.dart';
import '../models/shopping_item.dart';
import '../providers/theme_provider.dart';
import '../widgets/color_picker.dart';
import '../widgets/icon_picker.dart';


class ShoppingListView extends StatefulWidget {
  const ShoppingListView({super.key});

  @override
  State<ShoppingListView> createState() => _ShoppingListViewState();
}

class _ShoppingListViewState extends State<ShoppingListView> with TickerProviderStateMixin {
  final _dateFormat = DateFormat('dd.MM.yyyy HH:mm');
   // Checked animasyonu için kontrolcüler
   final Map<String, AnimationController> _checkAnimControllers = {};
   final Map<String, Animation<double>> _checkAnimations = {};

   // Controller'a erişim kolaylığı için
   late ShoppingListController _controller;

   bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // initState içinde context kullanmak riskli olabilir, didChangeDependencies daha güvenli
    // _controller = Provider.of<ShoppingListController>(context, listen: false);
  }

   @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Controller'ı burada alalım
     _controller = Provider.of<ShoppingListController>(context);
     // Mevcut öğeler için animasyon kontrolcülerini hazırla (opsiyonel)
     _prepareCheckAnimations(_controller.items);
  }

  @override
  void dispose() {
    // Animasyon kontrolcülerini temizle
    _checkAnimControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }

  // Öğeler değiştikçe animasyon kontrolcülerini güncellemek için
  void _prepareCheckAnimations(List<ShoppingItem> items) {
     items.forEach((item) {
      if (!_checkAnimControllers.containsKey(item.id)) {
        final animController = AnimationController(
          duration: const Duration(milliseconds: 300), // Animasyon süresi
          vsync: this,
        );
        _checkAnimControllers[item.id] = animController;
        // Scale animasyonu (1.0 -> 1.3 -> 1.0)
        _checkAnimations[item.id] = TweenSequence<double>([
            TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 1.3).chain(CurveTween(curve: Curves.easeOut)), weight: 50),
            TweenSequenceItem(tween: Tween<double>(begin: 1.3, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 50),
        ]).animate(animController);
      }
      // Başlangıç durumunu ayarla (alınmışsa animasyonun sonunda olsun)
      if(item.isBought) {
         _checkAnimControllers[item.id]?.value = 1.0;
      } else {
          _checkAnimControllers[item.id]?.value = 0.0;
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching 
          ? _buildSearchField()
          : const Text('Alışveriş Listem', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Arama butonu
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
          // Liste menüsü
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.history),
                  title: Text('Geçmiş'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _showHistoryDialog(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.playlist_add),
                  title: Text('Yeni Liste'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _showNewListDialog(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.cleaning_services),
                  title: Text('Listeyi Temizle'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _showClearListDialog(context),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Yeni Kategori'),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => _showAddCategoryDialog(context),
              ),
            ],
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // İlerleme göstergesi
          if (_controller.items.isNotEmpty) _buildProgressIndicator(),
          
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.secondary.withAlpha(77),
                  ],
                ),
              ),
              child: _controller.categories.isEmpty && _controller.items.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _controller.categories.length,
                      itemBuilder: (context, index) {
                        final category = _controller.categories[index];
                        final itemsInCategory = _controller.itemsByCategory[category.id] ?? [];
                        return _buildCategoryExpansionTile(category, itemsInCategory);
                      },
                    ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddItemDialog(context, _controller),
        label: const Text('Yeni Öğe'),
        icon: const Icon(Icons.add_shopping_cart),
      ),
    );
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
                  '${list.items.length} öğe • ${_dateFormat.format(list.createdAt)}',
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
    final completionPercentage = _controller.getCompletionPercentage(_controller.activeListId);
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Yeni Kategori'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Kategori Adı',
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Renk Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                ColorPickerWidget(
                  selectedColor: selectedColor,
                  onColorChanged: (color) => setState(() => selectedColor = color),
                ),
                const SizedBox(height: 20),
                const Text('İkon Seç', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                const SizedBox(height: 10),
                IconPickerWidget(
                  selectedIcon: selectedIcon,
                  onIconChanged: (icon) => setState(() => selectedIcon = icon),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  _controller.addCustomCategory(
                    nameController.text,
                    selectedIcon,
                    selectedColor,
                  );
                  Navigator.pop(context);
                  // Başarılı mesajı göster
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${nameController.text} kategorisi eklendi'),
                      backgroundColor: selectedColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
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
          color: category.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        key: PageStorageKey(category.id),
        leading: CircleAvatar(
          backgroundColor: category.color.withOpacity(0.1),
          child: Icon(category.iconData, color: category.color),
        ),
        title: Row(
          children: [
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: category.color.withOpacity(0.1),
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
        subtitle: items.isNotEmpty ? LinearProgressIndicator(
          value: items.where((item) => item.isBought).length / items.length,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(category.color),
          minHeight: 2,
        ) : null,
        children: items.map((item) => _buildShoppingItemWidget(item)).toList(),
      ),
    );
  }

  // Alışveriş öğesi widget'ı
  Widget _buildShoppingItemWidget(ShoppingItem item) {
    final animController = _checkAnimControllers[item.id];
    final animation = _checkAnimations[item.id];
    final category = _controller.getCategoryById(item.categoryId);

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
      onDismissed: (direction) {
        final removedItem = _controller.removeItem(item.id);
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
            ),
          );
        }
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        elevation: item.isBought ? 0 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: item.isBought ? Colors.grey.shade300 : category.color.withOpacity(0.5),
            width: 1,
          ),
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
                  color: item.isBought ? category.color.withOpacity(0.1) : Colors.transparent,
                  border: Border.all(
                    color: item.isBought ? category.color : Colors.grey.shade400,
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
            backgroundColor: category.color.withOpacity(0.1),
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.8,
                  maxWidth: MediaQuery.of(context).size.width * 0.9,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Yeni Öğe Ekle',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: textController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: "Alınacak öğe...",
                                prefixIcon: const Icon(Icons.shopping_basket_outlined),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              textCapitalization: TextCapitalization.sentences,
                            ),
                            const SizedBox(height: 15),
                            // Kategori Seçimi Dropdown
                            if (controller.categories.isNotEmpty) // Kategori varsa göster
                              DropdownButtonFormField<String>(
                                value: selectedCategoryId,
                                decoration: InputDecoration(
                                  labelText: 'Kategori Seçin',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  prefixIcon: selectedCategoryId != null
                                      ? Icon(controller.getCategoryById(selectedCategoryId!).iconData, color: controller.getCategoryById(selectedCategoryId!).color)
                                      : const Icon(Icons.category_outlined),
                                ),
                                items: controller.categories.map((Category category) {
                                  return DropdownMenuItem<String>(
                                    value: category.id,
                                    child: Row(
                                      children: [
                                        Icon(category.iconData, color: category.color, size: 20),
                                        const SizedBox(width: 10),
                                        Text(category.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  // Dropdown değiştiğinde dialogun state'ini güncelle
                                  setState(() {
                                    selectedCategoryId = newValue;
                                  });
                                },
                              )
                            else
                              const Text("Önce kategori eklemelisiniz!"), // Kategori yoksa uyarı
                          ],
                        ),
                      ),
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

}
