import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../restaurant/restaurant.dart'; // Make sure this path is correct
import 'restaurant_detail_page.dart'; // Make sure this path is correct

// Definisi Warna dari Palet yang Diberikan
const Color primaryColor = Color(0xFF8D6B94); // Ungu tua/abu-abu
const Color secondaryColor = Color(0xFFB15A7B); // Merah muda/ungu gelap
const Color accentColor = Color(0xFFC3A29E); // Coklat muda/salmon
const Color lightBackgroundColor = Color(0xFFE8DBC5); // Krem muda
const Color lightestBackgroundColor = Color(0xFFF4E9CE); // Hampir putih

class RestaurantListPage extends StatefulWidget {
  const RestaurantListPage({super.key});

  @override
  State<RestaurantListPage> createState() => _RestaurantListPageState();
}

class _RestaurantListPageState extends State<RestaurantListPage> {
  final List<Restaurant> _restaurants = [];
  final List<Restaurant> _allRestaurants = []; // Menyimpan semua data restaurant
  bool _isLoading = true;
  String _username = 'User';
  String _errorMessage = '';
  bool _hasError = false;

  // Filter variables
  String _selectedCategory = 'Semua';
  Set<String> _availableCategories = {'Semua'};
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUsername(), _loadRestaurants()]);
  }

  Future<void> _loadUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _username = prefs.getString('username') ?? 'User';
      });
    } catch (e) {
      print('Error loading username: $e');
    }
  }

  Future<void> _loadRestaurants() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
        _hasError = false;
      });
    }

    try {
      final data = await ApiService.getRestaurants(); // Updated API call
      if (mounted) {
        setState(() {
          _allRestaurants.clear();
          _allRestaurants.addAll(data);
          _restaurants.clear();
          _restaurants.addAll(data);
          _hasError = false;
          _extractCategories();
        });
      }
    } catch (e) {
      print('Error loading Restaurants: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal memuat data: ${e.toString()}";
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _extractCategories() {
    Set<String> categories = {'Semua'};

    // Extract categories from all restaurants
    for (Restaurant restaurant in _allRestaurants) {
      // Assuming Restaurant model has a list of categories or similar field
      // If your Restaurant model doesn't have categories directly, you might need to adjust this.
      // For simplicity, using city as a 'category' for now.
      categories.add(restaurant.city.trim());
    }

    setState(() {
      _availableCategories = categories;
    });
  }

  Future<void> _searchRestaurantsByCategory(String category) async {
    if (category == 'Semua') {
      setState(() {
        _restaurants.clear();
        _restaurants.addAll(_allRestaurants);
        _selectedCategory = category;
        _isSearching = false;
        _searchQuery = '';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _selectedCategory = category;
      _searchQuery = category;
    });

    try {
      // If there's a search endpoint, use it
      // final searchResults = await ApiService.searchRestaurants(category);

      // For now, use local filter (assuming city is the filterable category)
      final filteredResults = _allRestaurants.where((restaurant) {
        return restaurant.city.toLowerCase().contains(category.toLowerCase());
      }).toList();

      if (mounted) {
        setState(() {
          _restaurants.clear();
          _restaurants.addAll(filteredResults);
          _hasError = false;
        });
      }
    } catch (e) {
      print('Error searching restaurants: $e');
      if (mounted) {
        setState(() {
          _errorMessage = "Gagal mencari restoran: ${e.toString()}";
          _hasError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isSearching = false);
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightestBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                spreadRadius: 2,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Halo, $_username!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 244, 233),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Temukan restoran favoritmu di sini.',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 255, 244, 233)
                          .withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.favorite,
              color: const Color.fromARGB(255, 255, 244, 233),
            ),
            onPressed: () => Navigator.pushNamed(context, '/favorites'),
          ),
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: const Color.fromARGB(255, 255, 244, 233),
            ),
            onPressed: _loadRestaurants,
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: const Color.fromARGB(255, 255, 244, 233),
            ),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text('Logout', style: TextStyle(color: primaryColor)),
                ),
              ];
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                lightBackgroundColor.withOpacity(0.5),
              ),
            ),
          ),
          Column(
            children: [
              _buildCategoryFilter(),
              Expanded(child: _buildBody()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter berdasarkan kota:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableCategories.length,
              itemBuilder: (context, index) {
                final category = _availableCategories.elementAt(index);
                final isSelected = _selectedCategory == category;

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                      category,
                      style: TextStyle(
                        color: isSelected ? Colors.white : primaryColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        _searchRestaurantsByCategory(category);
                      }
                    },
                    backgroundColor: lightBackgroundColor,
                    selectedColor: secondaryColor,
                    checkmarkColor: Colors.white,
                    elevation: isSelected ? 4 : 2,
                    pressElevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected
                            ? secondaryColor
                            : primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_searchQuery.isNotEmpty && _selectedCategory != 'Semua')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text(
                    'Menampilkan hasil untuk: "$_searchQuery"',
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor.withOpacity(0.7),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${_restaurants.length} restoran)',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Memuat data restoran...',
              style: TextStyle(color: primaryColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_isSearching) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: secondaryColor),
            const SizedBox(height: 16),
            Text(
              'Mencari Restoran di $_selectedCategory...',
              style: TextStyle(color: primaryColor.withOpacity(0.7)),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: secondaryColor, size: 60),
            const SizedBox(height: 20),
            Text(
              'Oops! Terjadi kesalahan.',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _errorMessage.contains("SocketException")
                    ? 'Pastikan Anda terhubung ke internet.'
                    : _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              onPressed: () {
                if (_selectedCategory == 'Semua') {
                  _loadRestaurants();
                } else {
                  _searchRestaurantsByCategory(_selectedCategory);
                }
              },
              label: 'Coba Lagi',
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      );
    }

    if (_restaurants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant, size: 60, color: accentColor),
            const SizedBox(height: 20),
            Text(
              _selectedCategory == 'Semua'
                  ? 'Belum ada restoran ditemukan.'
                  : 'Tidak ada restoran di "$_selectedCategory".',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              _selectedCategory == 'Semua'
                  ? 'Coba muat ulang atau periksa koneksi Anda.'
                  : 'Coba pilih kota lain atau muat ulang data.',
              style: TextStyle(
                color: primaryColor.withOpacity(0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildActionButton(
              onPressed: () {
                if (_selectedCategory == 'Semua') {
                  _loadRestaurants();
                } else {
                  _searchRestaurantsByCategory('Semua');
                }
              },
              label: _selectedCategory == 'Semua'
                  ? 'Muat Ulang'
                  : 'Tampilkan Semua',
              backgroundColor: accentColor,
              foregroundColor: primaryColor,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedCategory == 'Semua') {
          await _loadRestaurants();
        } else {
          await _searchRestaurantsByCategory(_selectedCategory);
        }
      },
      color: secondaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _restaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _restaurants[index];
          return _buildRestaurantCard(restaurant);
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Restaurant restaurant) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color.fromARGB(255, 255, 244, 233),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RestaurantDetailPage(restaurantId: restaurant.id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Hero(
                tag: 'restaurantImage_${restaurant.id}',
                child: Image.network(
                  ApiService.getImageUrl(restaurant.pictureId, size: 'medium'), // Updated
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      color: lightBackgroundColor,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: secondaryColor,
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: lightBackgroundColor,
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        size: 80,
                        color: primaryColor.withOpacity(0.6),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: secondaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          restaurant.city,
                          style: TextStyle(
                            color: primaryColor.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.star_rounded,
                        size: 20,
                        color: Colors.amber.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toString(), // Convert double to string
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Removed genre display as it's not applicable to restaurants directly.
                  // If you have a 'category' or 'cuisine' list in your Restaurant model,
                  // you can add similar logic here.
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Removed _getGenreColor as it's specific to restoran.
  // If you need color coding for restaurant categories, you'd add a new function here.

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 5,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      child: Text(label),
    );
  }
}

// Custom Painter untuk pola latar belakang (tetap sama)
class _BackgroundPatternPainter extends CustomPainter {
  final Color patternColor;

  _BackgroundPatternPainter(this.patternColor);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = patternColor;

    final double baseSize = size.width * 0.08;
    final double spacing = size.width * 0.15;

    for (double x = -baseSize; x < size.width + baseSize; x += spacing) {
      for (double y = -baseSize; y < size.height + baseSize; y += spacing) {
        canvas.drawCircle(
          Offset(x + size.width * 0.03, y + size.height * 0.05),
          baseSize * 0.6,
          paint,
        );
        canvas.drawRect(
          Rect.fromLTWH(x, y + baseSize, baseSize * 0.8, baseSize * 0.8),
          paint,
        );
        canvas.drawOval(
          Rect.fromLTWH(
            x + baseSize * 0.5,
            y + baseSize * 1.5,
            baseSize,
            baseSize * 0.5,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
