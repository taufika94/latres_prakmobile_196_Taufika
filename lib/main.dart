import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:app/restaurant/restaurant.dart'; // Pastikan ini diimpor
import 'package:app/screens/auth_page.dart';
import 'package:app/screens/restaurant_list_page.dart';
import 'package:app/screens/favorites_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Daftarkan semua adapter yang digenerate oleh Hive
  Hive.registerAdapter(RestaurantAdapter()); // Untuk kelas Restaurant
  Hive.registerAdapter(
    RestaurantDetailAdapter(),
  ); // Untuk kelas RestaurantDetail
  Hive.registerAdapter(CategoryAdapter()); // Untuk kelas Category
  Hive.registerAdapter(MenusAdapter()); // Untuk kelas Menus
  Hive.registerAdapter(MenuItemAdapter()); // Untuk kelas MenuItem
  Hive.registerAdapter(CustomerReviewAdapter()); // Untuk kelas CustomerReview

  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Restaurant App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.deepOrange,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const AuthPage(),
      routes: {
        '/home': (context) => const RestaurantListPage(),
        '/favorites': (context) => const FavoritesPage(),
      },
    );
  }
}
