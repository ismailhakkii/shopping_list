import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'controllers/shopping_list_controller.dart';
import 'providers/theme_provider.dart';
import 'views/splash_screen.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    
    final prefs = await SharedPreferences.getInstance();
    
    // Sistem UI ayarları
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Ekran yönlendirmesi sabitleme
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    runApp(MyApp(prefs: prefs));
  } catch (e) {
    debugPrint('Uygulama başlatılırken hata: $e');
  }
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({
    required this.prefs,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          lazy: false, // ShoppingListController'ı hemen başlat
          create: (_) => ShoppingListController(prefs),
        ),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Alışveriş Listem',
            theme: themeProvider.getThemeData(false),
            darkTheme: themeProvider.getThemeData(true),
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              return ScrollConfiguration(
                behavior: const ScrollBehavior().copyWith(
                  physics: const BouncingScrollPhysics(),
                  overscroll: false,
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}