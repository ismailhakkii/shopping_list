import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../controllers/shopping_list_controller.dart';
import '../providers/theme_provider.dart';  // ThemeProvider'ı ekledik
import 'shopping_list_view.dart';

class ListSelectionView extends StatelessWidget {
  const ListSelectionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listeleri'),
        actions: [
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
      body: Consumer<ShoppingListController>(
        builder: (context, controller, child) {
          if (controller.allLists.isEmpty) {
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
                    'Henüz alışveriş listeniz yok',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Yeni bir liste oluşturmak için + butonuna dokunun',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.allLists.length,
            itemBuilder: (context, index) {
              final list = controller.allLists[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(list.icon != null ? IconData(list.icon!, fontFamily: 'MaterialIcons') : Icons.list_alt),
                  title: Text(list.name),
                  subtitle: Text(
                    '${list.items.length} öğe • %${list.completionPercentage.toStringAsFixed(0)} tamamlandı',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    controller.switchList(list.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ShoppingListView(),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewListDialog(context),
        label: const Text('Yeni Liste'),
        icon: const Icon(Icons.add),
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
            hintText: 'Örnek: Piknik Listesi, Market Alışverişi...',
            prefixIcon: Icon(Icons.list_alt),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                final controller = context.read<ShoppingListController>();
                controller.createNewList(textController.text);
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ShoppingListView(),
                  ),
                );
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}