import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/shopping_list_controller.dart';
import '../models/shopping_item.dart';

class ShoppingListView extends StatelessWidget {
  const ShoppingListView({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'a erişim (Provider aracılığıyla)
    // `watch` kullanmak, Controller'daki değişikliklerde build metodunun tekrar çalışmasını sağlar
    final controller = context.watch<ShoppingListController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alışveriş Listesi'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: controller.items.isEmpty
          ? const Center(
              child: Text(
              'Listeniz boş.\nEklemek için (+) butonuna dokunun.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ))
          : ListView.builder(
              itemCount: controller.items.length,
              itemBuilder: (context, index) {
                final item = controller.items[index];
                return _buildShoppingItemTile(context, item, controller);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddItemDialog(context, controller),
        tooltip: 'Yeni Öğe Ekle',
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Liste öğesi için widget
  Widget _buildShoppingItemTile(BuildContext context, ShoppingItem item,
      ShoppingListController controller) {
    return ListTile(
      leading: Checkbox(
        value: item.isBought,
        onChanged: (bool? value) {
          controller.toggleItemStatus(item.id);
        },
        activeColor: Colors.green,
      ),
      title: Text(
        item.name,
        style: TextStyle(
          decoration: item.isBought
              ? TextDecoration.lineThrough // Üstünü çiz
              : TextDecoration.none,
          color: item.isBought ? Colors.grey : Colors.black,
          fontSize: 17
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
        tooltip: 'Sil',
        onPressed: () => _showDeleteConfirmationDialog(context, item, controller),
      ),
      onTap: () {
         controller.toggleItemStatus(item.id); // Satıra tıklayınca da işaretle/kaldır
      },
    );
  }

   // Yeni öğe ekleme dialogu
  void _showAddItemDialog(BuildContext context, ShoppingListController controller) {
    final TextEditingController textController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Yeni Öğe Ekle'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(hintText: "Öğe adını girin"),
            onSubmitted: (_) { // Enter'a basınca da eklesin
               _submitAddItem(context, controller, textController);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Ekle'),
              onPressed: () => _submitAddItem(context, controller, textController),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent)
            ),
          ],
        );
      },
    );
  }

  void _submitAddItem(BuildContext context, ShoppingListController controller, TextEditingController textController) {
       final String itemName = textController.text;
       if (itemName.isNotEmpty) {
           controller.addItem(itemName);
           Navigator.of(context).pop(); // Dialogu kapat
        }
        // İsteğe bağlı: Boşsa uyarı gösterilebilir
        // else {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(content: Text('Lütfen bir öğe adı girin!'))
        //   );
        // }
  }

  // Silme onayı dialogu
  void _showDeleteConfirmationDialog(BuildContext context, ShoppingItem item, ShoppingListController controller) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Öğeyi Sil'),
          content: Text('"${item.name}" öğesini silmek istediğinizden emin misiniz?'),
          actions: <Widget>[
            TextButton(
              child: const Text('İptal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Sil', style: TextStyle(color: Colors.red)),
              onPressed: () {
                controller.removeItem(item.id);
                Navigator.of(context).pop(); // Dialogu kapat
                 ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"${item.name}" silindi.'), duration: const Duration(seconds: 2),)
                  );
              },
            ),
          ],
        );
      },
    );
  }
}