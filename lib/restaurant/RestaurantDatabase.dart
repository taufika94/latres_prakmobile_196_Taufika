// lib/restaurant/restaurant_database.dart (rename from movie_database.dart)
import 'package:hive/hive.dart';
import 'package:app/restaurant/restaurant.dart'; // Import the new Restaurant model

class RestaurantDatabase {
  static const String boxName = 'restaurantsBox'; // Changed box name

  Future<void> addRestaurant(Restaurant restaurant, String username) async {
    final box = await Hive.openBox<Restaurant>(boxName);
    // Use username as part of the key for user-specific data
    await box.put(
      '${username}_${restaurant.id}',
      restaurant,
    );
    print('Added restaurant to Hive: ${restaurant.name} for user: $username');
  }

  Future<List<Restaurant>> getRestaurants(String username) async {
    final box = await Hive.openBox<Restaurant>(boxName);
    final userRestaurants = box.keys
        .where((key) => key.startsWith('${username}_')) // Filter by username prefix
        .map((key) => box.get(key))
        .whereType<Restaurant>() // Ensure it's a Restaurant type
        .toList();
    print('Fetched ${userRestaurants.length} restaurants for user: $username');
    return userRestaurants;
  }

  Future<void> deleteRestaurant(String id, String username) async {
    final box = await Hive.openBox<Restaurant>(boxName);
    await box.delete('${username}_$id'); // Delete using the user-specific key
    print('Deleted restaurant from Hive with ID: $id for user: $username');
  }

  Future<void> clearAllRestaurants() async {
    final box = await Hive.openBox<Restaurant>(boxName);
    await box.clear(); // Clears all restaurants from the box
    print('Cleared all restaurants from Hive.');
  }

  // You might want a method to check if a restaurant is already favorited
  Future<bool> isRestaurantFavorited(String id, String username) async {
    final box = await Hive.openBox<Restaurant>(boxName);
    return box.containsKey('${username}_$id');
  }
}