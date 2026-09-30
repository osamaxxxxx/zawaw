import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/short_category.dart';
import '../../services/shorts_data_seeder.dart';
import '../../services/shorts_service.dart';
import 'shorts_player_screen.dart';

class ShortsCategoriesScreen extends StatefulWidget {
  const ShortsCategoriesScreen({super.key});

  @override
  State<ShortsCategoriesScreen> createState() => _ShortsCategoriesScreenState();
}

class _ShortsCategoriesScreenState extends State<ShortsCategoriesScreen> {
  final ShortsService _shortsService = ShortsService();
  List<ShortCategory> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Ensure the default videos exist before the user chooses a category.
      await ShortsDataSeeder().initializeIfNeeded();
      final categories = await _shortsService.getCategories();

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'حدث خطأ في تحميل الفئات';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
      appBar: AppBar(
        title: Text(
          'شورتس إسلامية',
          style: GoogleFonts.cairo(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadCategories,
                        icon: const Icon(Icons.refresh),
                        label: Text(
                          'إعادة المحاولة',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                )
              : _categories.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد فئات متاحة حالياً',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return _buildCategoryCard(context, category, isDark);
                      },
                    ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    ShortCategory category,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : primaryGold.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ShortsPlayerScreen(category: category),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primaryGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryGold.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: category.iconUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            category.iconUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.play_circle_outline,
                              color: primaryGold,
                              size: 32,
                            ),
                          ),
                        )
                      : const Icon(
                          Icons.play_circle_outline,
                          color: primaryGold,
                          size: 32,
                        ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: GoogleFonts.cairo(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : darkGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.videocam_rounded,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${category.shortsCount} فيديو',
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGold.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: primaryGold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
