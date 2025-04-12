import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'controllers/shopping_list_controller.dart';
// import 'views/shopping_list_view.dart'; // Artık direkt bunu çağırmıyoruz
import 'views/splash_screen.dart'; 

void main() {
  WidgetsFlutterBinding.ensureInitialized(); // Gerekli olabilir
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ShoppingListController(),
      child: MaterialApp(
        title: 'Eğlenceli Alışveriş Listem',
        theme: ThemeData(
          primarySwatch: Colors.deepPurple, // Ana tema rengi
          // Genel font ayarı (isteğe bağlı)
          // fontFamily: 'YourCustomFont',
          visualDensity: VisualDensity.adaptivePlatformDensity,
           // Kart temasını biraz özelleştirelim
           cardTheme: CardTheme(
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0))
           ),
           // AppBar temasını ayarlayalım
           appBarTheme: const AppBarTheme(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              elevation: 0, // Splash ile uyum için 0 olabilir veya Scaffold'da ayarlanır
              titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
           ),
           // FAB teması
           floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.black87,
           )
        ),
        // --- DEĞİŞİKLİK: Başlangıç ekranı SplashScreen ---
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}