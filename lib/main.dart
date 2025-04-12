import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/shopping_list_controller.dart';
import 'providers/theme_provider.dart';
import 'views/list_selection_view.dart'; // Yeni view

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ShoppingListController()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Alışveriş Listem',
            theme: themeProvider.themeData,
            home: const ListSelectionView(), // ShoppingListView yerine ListSelectionView kullanıyoruz
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}