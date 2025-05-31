import 'package:app/restaurant/RestaurantDatabase.dart';
import 'package:app/screens/restaurant_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../restaurant/restaurant.dart';
import '../services/api_service.dart';

const Color primaryColor = Color(0xFF8D6B94);
const Color secondaryColor = Color(0xFFB15A7B);
const Color accentColor = Color(0xFFC3A29E);
const Color lightBackgroundColor = Color(0xFFE8DBC5);
const Color lightestBackgroundColor = Color(0xFFF4E9CE);

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final RestaurantDatabase _restaurantDatabase = RestaurantDatabase();
  List<Restaurant> _favoriteRestaurants = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isSelectionMode = false;
  final Set<String> _selectedRestaurants = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';

    try {
      _favoriteRestaurants = await _restaurantDatabase.getRestaurants(username);
    } catch (e) {
      setState(() {
        _errorMessage = "Gagal memuat favorit: ${e.toString()}";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(String restaurantId) async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';
    await _restaurantDatabase.deleteRestaurant(restaurantId, username);
    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Dihapus dari favorit!'),
          backgroundColor: const Color.fromARGB(255, 209, 47, 47),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  Future<void> _removeSelectedFavorites() async {
    if (_selectedRestaurants.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User ';

    for (final id in _selectedRestaurants) {
      await _restaurantDatabase.deleteRestaurant(id, username);
    }

    await _loadFavorites();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedRestaurants.length} Restoran dihapus dari favorit!'),
          backgroundColor: secondaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(20),
        ),
      );
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedRestaurants.clear();
      }
    });
  }

  void _toggleRestaurantSelection(String restaurantId) {
    setState(() {
      if (_selectedRestaurants.contains(restaurantId)) {
        _selectedRestaurants.remove(restaurantId);
      } else {
        _selectedRestaurants.add(restaurantId);
      }

      if (_selectedRestaurants.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightestBackgroundColor,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                lightBackgroundColor.withOpacity(0.5),
              ),
            ),
          ),
          _buildBody(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: primaryColor,
      foregroundColor: lightestBackgroundColor,
      elevation: 0,
      title: _isSelectionMode
          ? Text('${_selectedRestaurants.length} dipilih',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.8,
              ))
          : const Text(
              'Restoran Favorit',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
            ),
      centerTitle: true,
      actions: [
        if (_favoriteRestaurants.isNotEmpty && !_isLoading && _errorMessage.isEmpty)
          IconButton(
            icon: Icon(_isSelectionMode ? Icons.close : Icons.select_all),
            onPressed: _toggleSelectionMode,
            tooltip: _isSelectionMode ? 'Batal' : 'Pilih',
          ),
        if (_isSelectionMode && _selectedRestaurants.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _removeSelectedFavorites,
            tooltip: 'Hapus yang dipilih',
          ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: secondaryColor));
    }

    if (_errorMessage.isNotEmpty) {
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
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: primaryColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Coba Lagi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
    }

    if (_favoriteRestaurants.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: secondaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        itemCount: _favoriteRestaurants.length,
        itemBuilder: (context, index) {
          final restaurant = _favoriteRestaurants[index];
          final isSelected = _selectedRestaurants.contains(restaurant.id);
          return _isSelectionMode
              ? _buildSelectableRestaurantCard(restaurant, isSelected)
              : _buildDismissibleRestaurantCard(restaurant);
        },
      ),
    );
  }

  Widget _buildSelectableRestaurantCard(Restaurant restaurant, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleRestaurantSelection(restaurant.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? secondaryColor : Colors.transparent,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            _buildRestaurantCardContent(restaurant),
            if (isSelected)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: secondaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 80, color: accentColor),
          const SizedBox(height: 24),
          Text(
            'Belum ada restoran favorit.',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Tambahkan beberapa dari daftar restoran utama Anda!',
            style: TextStyle(
              fontSize: 16,
              color: primaryColor.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: secondaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Jelajahi Restoran', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleRestaurantCard(Restaurant restaurant) {
    return Dismissible(
      key: Key(restaurant.id),
      background: Container(
        decoration: BoxDecoration(
          color: secondaryColor.withOpacity(0.8),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 20),
        child: Icon(Icons.delete, color: lightestBackgroundColor, size: 30),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: lightestBackgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Hapus dari Favorit?',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Anda yakin ingin menghapus ${restaurant.name} dari daftar favorit?',
              style: TextStyle(color: primaryColor.withOpacity(0.8)),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Batal',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondaryColor,
                  foregroundColor: lightestBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) => _removeFavorite(restaurant.id),
      child: _buildRestaurantCardContent(restaurant),
    );
  }

  Widget _buildRestaurantCardContent(Restaurant restaurant) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: lightBackgroundColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: _isSelectionMode
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailPage(restaurantId: restaurant.id),
                  ),
                ).then((_) => _loadFavorites());
              },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'restaurantImage_${restaurant.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: Image.network(
                  ApiService.getImageUrl(restaurant.pictureId, size: 'medium'), // Changed from imgUrl to pictureId
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      height: 220,
                      color: lightestBackgroundColor,
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
                      color: lightestBackgroundColor,
                      child: Icon(
                        Icons.restaurant_menu_outlined,
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
                          restaurant.city, // Changed from restpram.releaseDate to restaurant.city
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
                        restaurant.rating.toStringAsFixed(1), // Display rating with 1 decimal place
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Removed priceRange and contact as they are not directly in the base Restaurant model
                  // If you need to display these, you'd need to fetch RestaurantDetail or include them in the base Restaurant model.
                  if (restaurant is RestaurantDetail && restaurant.categories != null && restaurant.categories!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: restaurant.categories!.map((category) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getCategoryColor(category.name).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _getCategoryColor(category.name).withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: _getCategoryColor(category.name),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Renamed _getCuisineColor to _getCategoryColor to align with RestaurantDetail
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'italian':
        return Colors.green.shade700;
      case 'modern american':
        return Colors.blue.shade700;
      case 'korean':
        return Colors.red.shade700;
      case 'cafe':
        return Colors.brown.shade700;
      case 'asia':
        return Colors.orange.shade700;
      // Add more cases for other categories if needed
      default:
        return primaryColor;
    }
  }
}

// Custom Painter untuk pola latar belakang (Tidak ada perubahan)
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