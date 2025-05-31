// lib/api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../restaurant/restaurant.dart'; // Import the new Restaurant model

class ApiService {
  // Dicoding Restaurant API base URLs
  static const String _baseUrl = 'https://restaurant-api.dicoding.dev';
  static const String _listUrl = '$_baseUrl/list';
  static const String _detailUrl = '$_baseUrl/detail/'; // Note the trailing slash
  static const String _searchUrl = '$_baseUrl/search?q=';
  static const String _smallImageUrl = '$_baseUrl/images/small/';
  static const String _mediumImageUrl = '$_baseUrl/images/medium/';
  static const String _largeImageUrl = '$_baseUrl/images/large/';

  static const Duration _timeoutDuration = Duration(seconds: 10);

  // Get all restaurants
  static Future<List<Restaurant>> getRestaurants() async {
    try {
      print('Fetching restaurants from: $_listUrl');

      final response = await http
          .get(
            Uri.parse(_listUrl),
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      print('API Response Status: ${response.statusCode}');
      print('API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Check for "error": false and "restaurants" key as per Dicoding API structure
        if (data is Map && data['error'] == false && data['restaurants'] != null) {
          final List<dynamic> restaurantsJson = data['restaurants'];
          return restaurantsJson
              .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
              .toList();
        } else {
          // If response format is unexpected or error is true
          throw Exception('Unexpected response format or API error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in getRestaurants: $e');
      throw _handleNetworkError(e);
    }
  }

  // Search restaurants
  static Future<List<Restaurant>> searchRestaurants(String query) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_searchUrl$query'), // Use the search URL
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      print('Search API Response: ${response.statusCode}');
      print('Search API Body: ${response.body}');

      if (response.statusCode == 200) {
        final dynamic data = json.decode(response.body);

        // Dicoding search API returns `error: true` if no results are found.
        if (data is Map && data['error'] == false && data['restaurants'] != null) {
          final List<dynamic> restaurantsJson = data['restaurants'];
          return restaurantsJson
              .map((json) => Restaurant.fromJson(json as Map<String, dynamic>))
              .toList();
        } else if (data is Map && data['error'] == true) {
          // If search yields no results, API returns error:true with message.
          // In this case, we return an empty list, which is often more user-friendly.
          print('Search returned no results: ${data['message']}');
          return [];
        } else {
          throw Exception('Unexpected response format or API error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in searchRestaurants: $e');
      throw _handleNetworkError(e);
    }
  }

  // Get restaurant by ID (using RestaurantDetail model for full data)
  static Future<RestaurantDetail> getRestaurantDetail(String id) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_detailUrl$id'), // Use the detail URL
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      print('Detail API Response: ${response.statusCode}');
      print('Detail API Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        // Check for "error": false and "restaurant" key
        if (data['error'] == false && data['restaurant'] != null) {
          return RestaurantDetail.fromJson(data['restaurant']);
        } else {
          throw Exception('Unexpected response format or API error: ${data['message'] ?? 'Unknown error'}');
        }
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in getRestaurantDetail: $e');
      throw _handleNetworkError(e);
    }
  }

  // Dicoding API for restaurants does not support POST, PUT, DELETE for public use.
  // These methods are commented out as they are not applicable for this API.
  /*
  // Add new restaurant (if API supports it)
  static Future<Restaurant> addRestaurant(Restaurant restaurant) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/api/v1/restaurant'), // Adjust endpoint if needed
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(restaurant.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Restaurant.fromJson(data);
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in addRestaurant: $e');
      throw _handleNetworkError(e);
    }
  }

  // Update restaurant (if API supports it)
  static Future<Restaurant> updateRestaurant(String id, Restaurant restaurant) async {
    try {
      final response = await http
          .put(
            Uri.parse('$_baseUrl/api/v1/restaurant/$id'), // Adjust endpoint if needed
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(restaurant.toJson()),
          )
          .timeout(_timeoutDuration);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Restaurant.fromJson(data);
      } else {
        throw _handleError(response.statusCode, response.body);
      }
    } catch (e) {
      print('Error in updateRestaurant: $e');
      throw _handleNetworkError(e);
    }
  }

  // Delete restaurant (if API supports it)
  static Future<bool> deleteRestaurant(String id) async {
    try {
      final response = await http
          .delete(
            Uri.parse('$_baseUrl/api/v1/restaurant/$id'), // Adjust endpoint if needed
            headers: {
              'Content-Type': 'application/json',
            },
          )
          .timeout(_timeoutDuration);

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Error in deleteRestaurant: $e');
      return false;
    }
  }
  */

  // Get image URL helper for Dicoding API
  static String getImageUrl(String pictureId, {String size = 'small'}) {
    switch (size.toLowerCase()) {
      case 'small':
        return '$_smallImageUrl$pictureId';
      case 'medium':
        return '$_mediumImageUrl$pictureId';
      case 'large':
        return '$_largeImageUrl$pictureId';
      default:
        // Fallback to small if an invalid size is provided
        return '$_smallImageUrl$pictureId';
    }
  }

  // Error handling
  static Exception _handleError(int statusCode, String responseBody) {
    switch (statusCode) {
      case 400:
        return Exception('Bad request: $responseBody');
      case 401:
        return Exception('Unauthorized access');
      case 403:
        return Exception('Forbidden access');
      case 404:
        return Exception('Resource not found');
      case 500:
        return Exception('Internal server error');
      case 502:
        return Exception('Bad gateway');
      case 503:
        return Exception('Service unavailable');
      default:
        return Exception('HTTP Error $statusCode: $responseBody');
    }
  }

  static Exception _handleNetworkError(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return Exception('Request timeout. Please check your internet connection.');
    } else if (error.toString().contains('SocketException')) {
      return Exception('No internet connection available.');
    } else if (error.toString().contains('FormatException')) {
      return Exception('Invalid data format received from server.');
    } else if (error is http.ClientException) {
      // Handle http client specific errors like network unreachable etc.
      return Exception('HTTP Client Error: ${error.message}');
    } else if (error is Exception) {
      return error;
    } else {
      return Exception('Unknown network error: ${error.toString()}');
    }
  }
}