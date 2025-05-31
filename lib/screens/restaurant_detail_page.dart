import 'package:app/restaurant/RestaurantDatabase.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../restaurant/restaurant.dart'; // Ensure this imports the correct Restaurant and RestaurantDetail models

// Definisi Warna dari Palet yang Diberikan
const Color primaryColor = Color(0xFF8D6B94); // Ungu tua/abu-abu
const Color secondaryColor = Color(0xFFB15A7B); // Merah muda/ungu gelap
const Color accentColor = Color(0xFFC3A29E); // Coklat muda/salmon
const Color lightBackgroundColor = Color(0xFFE8DBC5); // Krem muda
const Color lightestBackgroundColor = Color(0xFFF4E9CE); // Hampir putih

/*
PENJELASAN STATEFUL vs STATELESS:
- StatefulWidget digunakan ketika widget perlu:
  1. Menyimpan data yang bisa berubah (state)
  2. Memiliki logika bisnis yang kompleks
  3. Berubah tampilannya berdasarkan interaksi/user input
  4. Mengelola lifecycle (initState, dispose, dll)

- StatelessWidget digunakan ketika widget:
  1. Hanya menampilkan data (tidak berubah)
  2. Tidak perlu mengelola state
  3. Bersifat statis/tidak berinteraksi

Dalam halaman ini kita menggunakan StatefulWidget karena:
1. Perlu menyimpan data restaurant yang di-load dari API
2. Perlu mengelola status loading/error
3. Perlu mengubah tampilan saat restaurant di-favoritkan
4. Perlu menyimpan state favorit ke SharedPreferences
*/

// Komponen halaman detail restaurant
class RestaurantDetailPage extends StatefulWidget {
  final String restaurantId; // ID restaurant yang akan ditampilkan, berasal dari navigasi sebelumnya

  const RestaurantDetailPage({super.key, required this.restaurantId});

  @override
  State<RestaurantDetailPage> createState() => _RestaurantDetailPageState();
}

class _RestaurantDetailPageState extends State<RestaurantDetailPage> {
  late RestaurantDetail _restaurant; // Changed from Movie to RestaurantDetail
  bool _isLoading = true;
  bool _isFavorite = false;
  String _errorMessage = '';
  final RestaurantDatabase _restaurantDatabase = RestaurantDatabase(); // Instance RestaurantDatabase

  @override
  void initState() {
    super.initState();
    _loadRestaurantDetail();
    _checkFavoriteStatus(); // Mengecek apakah restaurant ini telah difavoritkan sebelumnya oleh user
  }

  // Mengambil detail restaurant dari API
  Future<void> _loadRestaurantDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Assuming ApiService.getRestaurantDetail exists and returns RestaurantDetail
      final data = await ApiService.getRestaurantDetail(widget.restaurantId);
      setState(() => _restaurant = data);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst("Exception: ", ""));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Mengecek apakah restaurant ini sudah ada dalam daftar favorit di SharedPreferences
  Future<void> _checkFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'User';
    final favoriteRestaurants = await _restaurantDatabase.getRestaurants(username); // Changed to getRestaurants

    setState(() {
      _isFavorite = favoriteRestaurants.any((restaurant) => restaurant.id == widget.restaurantId); // Cek apakah restaurant ada di daftar
    });
  }

  // Menambahkan atau menghapus restaurant dari daftar favorit user
  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username') ?? 'default_user';

    setState(() => _isFavorite = !_isFavorite); // Toggle status favorit

    if (_isFavorite) {
      // Jika ditambahkan ke favorit
      await _restaurantDatabase.addRestaurant(_restaurant, username); // Simpan restaurant ke Hive
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restoran ditambahkan ke favorit!'),
            backgroundColor: Color.fromARGB(255, 67, 102, 70),
          ),
        );
      }
    } else {
      // Jika dihapus dari favorit
      await _restaurantDatabase.deleteRestaurant(_restaurant.id, username); // Hapus restaurant dari Hive
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Restoran dihapus dari favorit!'),
            backgroundColor: Color.fromARGB(255, 209, 47, 47),
          ),
        );
      }
    }
  }

  // Helper method untuk format tanggal (if needed for reviews, etc.)
  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Tidak diketahui';
    }
    try {
      final DateTime dateTime = DateTime.parse(date);
      final DateFormat formatter = DateFormat('dd MMM yyyy');
      return formatter.format(dateTime);
    } catch (e) {
      return date; // Return original string jika parsing gagal
    }
  }

  // Membangun UI utama halaman
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightestBackgroundColor,
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: secondaryColor)) // Tampilkan loading saat memuat data
          : _errorMessage.isNotEmpty
              ? _buildErrorState() // Jika error, tampilkan pesan error
              : _buildDetailBody(), // Jika sukses, tampilkan detail restaurant
    );
  }

  // UI ketika terjadi kesalahan dalam mengambil data
  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: secondaryColor, size: 60),
          const SizedBox(height: 20),
          Text(
            'Oops! Terjadi kesalahan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _errorMessage.contains("SocketException")
                  ? 'Pastikan Anda terhubung ke internet dan coba lagi.'
                  : _errorMessage,
              style: TextStyle(color: primaryColor.withOpacity(0.7), fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadRestaurantDetail,
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

  // UI utama yang menampilkan detail restaurant setelah data berhasil dimuat
  Widget _buildDetailBody() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320, // Tinggi maksimum saat dibuka penuh
          pinned: true, // Tetap terlihat saat di-scroll
          backgroundColor: primaryColor,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _restaurant.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 255, 255, 255),
                shadows: [
                  Shadow(
                    offset: Offset(1, 1),
                    blurRadius: 3,
                    color: Color.fromARGB(49, 255, 255, 255),
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                Hero(
                  tag: 'restaurantImage_${_restaurant.id}',
                  child: Image.network(
                    ApiService.getImageUrl(_restaurant.pictureId, size: 'large'), // Use pictureId for restaurants
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: lightBackgroundColor,
                        child: Icon(
                          Icons.restaurant, // Changed icon to restaurant
                          size: 80,
                          color: primaryColor.withOpacity(0.6),
                        ),
                      );
                    },
                  ),
                ),
                // Gradient overlay untuk readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
                size: 28,
              ),
              onPressed: _toggleFavorite, // Aksi ketika ikon favorit ditekan
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoCard(),
                const SizedBox(height: 20),
                _buildSectionHeader('Deskripsi'),
                _buildDescriptionCard(),
                const SizedBox(height: 20),
                if (_restaurant.address.isNotEmpty) ...[
                  _buildSectionHeader('Alamat'),
                  _buildAddressCard(),
                  const SizedBox(height: 20),
                ],
                if (_restaurant.categories != null && _restaurant.categories!.isNotEmpty) ...[
                  _buildSectionHeader('Kategori'),
                  _buildCategoriesCard(),
                  const SizedBox(height: 20),
                ],
                if (_restaurant.menus != null && (_restaurant.menus!.foods!.isNotEmpty || _restaurant.menus!.drinks!.isNotEmpty)) ...[
                  _buildSectionHeader('Menu'),
                  _buildMenusCard(),
                  const SizedBox(height: 20),
                ],
                if (_restaurant.customerReviews != null && _restaurant.customerReviews!.isNotEmpty) ...[
                  _buildSectionHeader('Ulasan Pelanggan'),
                  _buildCustomerReviewsCard(),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Membuat teks judul bagian
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }

  // Menampilkan informasi dasar restaurant dalam kartu
  Widget _buildBasicInfoCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Rating dan Kota
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(
                  icon: Icons.star_rounded,
                  iconColor: Colors.amber.shade600,
                  label: 'Rating',
                  value: '${_restaurant.rating}/5.0', // Assuming rating out of 5
                ),
                _buildInfoItem(
                  icon: Icons.location_city,
                  iconColor: secondaryColor,
                  label: 'Kota',
                  value: _restaurant.city,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: primaryColor.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Menampilkan deskripsi restaurant dalam kartu
  Widget _buildDescriptionCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          _restaurant.description,
          style: TextStyle(
            fontSize: 16,
            color: primaryColor,
            height: 1.6,
          ),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  // Menampilkan alamat restaurant dalam kartu
  Widget _buildAddressCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.map, color: primaryColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _restaurant.address,
                style: TextStyle(
                  fontSize: 16,
                  color: primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Menampilkan daftar kategori restaurant sebagai chip
  Widget _buildCategoriesCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: _restaurant.categories!.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _getCategoryColor(category.name).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getCategoryColor(category.name).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                category.name,
                style: TextStyle(
                  color: _getCategoryColor(category.name),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Menampilkan daftar menu (makanan dan minuman)
  Widget _buildMenusCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_restaurant.menus?.foods != null && _restaurant.menus!.foods!.isNotEmpty) ...[
              Text(
                'Makanan:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: _restaurant.menus!.foods!.map((food) => Chip(
                  label: Text(food.name),
                  backgroundColor: lightBackgroundColor,
                  labelStyle: TextStyle(color: primaryColor),
                )).toList(),
              ),
              const SizedBox(height: 16),
            ],
            if (_restaurant.menus?.drinks != null && _restaurant.menus!.drinks!.isNotEmpty) ...[
              Text(
                'Minuman:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 6,
                children: _restaurant.menus!.drinks!.map((drink) => Chip(
                  label: Text(drink.name),
                  backgroundColor: lightBackgroundColor,
                  labelStyle: TextStyle(color: primaryColor),
                )).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Menampilkan ulasan pelanggan
  Widget _buildCustomerReviewsCard() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _restaurant.customerReviews!.map((review) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_pin, color: secondaryColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        review.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: primaryColor,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDate(review.date),
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.review,
                    style: TextStyle(
                      fontSize: 14,
                      color: primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // Fungsi helper untuk mendapatkan warna berdasarkan kategori
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'italian':
        return Colors.green.shade700;
      case 'japanese':
        return Colors.red.shade700;
      case 'western':
        return Colors.blue.shade700;
      case 'asian':
        return Colors.orange.shade700;
      case 'fast food':
        return Colors.brown.shade700;
      case 'cafe':
        return Colors.teal.shade700;
      case 'sushi':
        return Colors.indigo.shade700;
      default:
        return primaryColor;
    }
  }
}