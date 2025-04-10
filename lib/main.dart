import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/shopping_list_controller.dart';
import 'views/shopping_list_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller'ı Provider ile sağlıyoruz
    return ChangeNotifierProvider(
      create: (context) => ShoppingListController(), // Controller örneğini oluştur
      child: MaterialApp(
        title: 'Alışveriş Listesi',
        theme: ThemeData(
          primarySwatch: Colors.blue, // Ana renk teması
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ShoppingListView(), // Başlangıç ekranı olarak View'ı göster
        debugShowCheckedModeBanner: false, // Debug etiketini kaldır
      ),
    );
  }
}