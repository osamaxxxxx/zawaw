import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/local_quran_service.dart';
import '../../models/surah.dart';
import '../../services/widget_sync_service.dart';
import '../quran/quran_reader_screen.dart';

class BookmarksScreen extends StatefulWidget {
  final int initialTab;
  const BookmarksScreen({super.key, this.initialTab = 0});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  final LocalQuranService _quranService = LocalQuranService();
  List<Surah> _cachedSurahs = [];
  List<Map<String, dynamic>> _savedPages = [];
  List<Map<String, dynamic>> _savedAyahs = [];

  final Color goldColor = const Color(0xFFD4AF37);

  @override
  void initState() {
    super.initState();
    _loadSurahsAndBookmarks();
  }

  Future<void> _loadSurahsAndBookmarks() async {
    _cachedSurahs = await _quranService.getSurahs();

    final prefs = await SharedPreferences.getInstance();

    // Load pages
    final pagesJson = prefs.getStringList('saved_pages') ?? [];
    _savedPages = _decodeBookmarks(pagesJson);

    // Load ayahs
    final ayahsJson = prefs.getStringList('saved_ayahs') ?? [];
    _savedAyahs = _decodeBookmarks(ayahsJson);

    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> _decodeBookmarks(List<String> values) {
    final bookmarks = <Map<String, dynamic>>[];
    for (final value in values) {
      try {
        final decoded = jsonDecode(value);
        if (decoded is Map) bookmarks.add(Map<String, dynamic>.from(decoded));
      } on FormatException {
        // Keep a malformed legacy value from breaking the saved-items screen.
      } on TypeError {
        // The value was valid JSON but not a bookmark object.
      }
    }
    return bookmarks;
  }

  String _getSurahName(int id) {
    try {
      return _cachedSurahs.firstWhere((s) => s.id == id).nameArabic;
    } catch (_) {
      return id.toString();
    }
  }

  Color _savedAyahColor(Map<String, dynamic> item, bool isDark) {
    final colorId = item['color'] as String? ?? 'green';
    final match = kSavedAyahColors.firstWhere(
      (color) => color.id == colorId,
      orElse: () => kSavedAyahColors.first,
    );
    return isDark ? match.darkColor : match.lightColor;
  }

  Future<void> _removePage(int index) async {
    _savedPages.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'saved_pages',
      _savedPages.map((e) => jsonEncode(e)).toList(),
    );
    setState(() {});
  }

  Future<void> _removeAyah(int index) async {
    _savedAyahs.removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'saved_ayahs',
      _savedAyahs.map((e) => jsonEncode(e)).toList(),
    );
    await WidgetSyncService.refresh();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : theme.appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            'المحفوظات',
            style: TextStyle(
              color: isDark ? goldColor : theme.textTheme.titleLarge?.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                indicatorColor: goldColor,
                labelColor: goldColor,
                unselectedLabelColor: isDark ? Colors.grey : Colors.black54,
                tabs: const [
                  Tab(text: 'الصفحات المحفوظة'),
                  Tab(text: 'الآيات المحفوظة'),
                ],
              ),
            ),
          ),
        ),
        body: _cachedSurahs.isEmpty
            ? Center(child: CircularProgressIndicator(color: goldColor))
            : TabBarView(
                children: [
                  _buildPagesList(theme, isDark),
                  _buildAyahsList(theme, isDark),
                ],
              ),
      ),
    );
  }

  Widget _buildPagesList(ThemeData theme, bool isDark) {
    if (_savedPages.isEmpty) {
      return const Center(child: Text('لا توجد صفحات محفوظة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedPages.length,
      itemBuilder: (context, index) {
        final item = _savedPages[index];
        final page = item['page'] as int;
        final surahName = item['surahName'] as String;

        return _buildCard(
          theme: theme,
          isDark: isDark,
          title: 'صفحة $page',
          subtitle: 'سورة $surahName',
          icon: Icons.menu_book,
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuranReaderScreen(initialPage: page),
              ),
            );
            _loadSurahsAndBookmarks();
          },
          onDelete: () => _removePage(index),
        );
      },
    );
  }

  Widget _buildAyahsList(ThemeData theme, bool isDark) {
    if (_savedAyahs.isEmpty) {
      return const Center(child: Text('لا توجد آيات محفوظة'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _savedAyahs.length,
      itemBuilder: (context, index) {
        final item = _savedAyahs[index];
        final surahId = item['surah'] as int;
        final ayah = item['ayah'] as int;
        final text = item['text'] as String;
        final page = item['page'] as int?;
        final bookmarkColor = _savedAyahColor(item, isDark);

        return _buildCard(
          theme: theme,
          isDark: isDark,
          title: 'سورة ${_getSurahName(surahId)} - آية $ayah',
          subtitle: '( $text )',
          icon: Icons.bookmark,
          iconColor: bookmarkColor,
          onTap: () async {
            if (page != null) {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranReaderScreen(
                    initialPage: page,
                    initialHighlightSurahId: surahId,
                    initialHighlightAyahNumber: ayah,
                  ),
                ),
              );
              _loadSurahsAndBookmarks();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('رقم الصفحة غير متوفر لهذه الآية'),
                ),
              );
            }
          },
          onDelete: () => _removeAyah(index),
        );
      },
    );
  }

  Widget _buildCard({
    required ThemeData theme,
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    required VoidCallback onTap,
    required VoidCallback onDelete,
  }) {
    final effectiveIconColor = iconColor ?? goldColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goldColor.withValues(alpha: 0.3), width: 1),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        onTap: onTap,
        title: Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 18,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontFamily: 'UthmanicHafs',
              fontSize: 16,
            ),
          ),
        ),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: effectiveIconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: effectiveIconColor),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          onPressed: onDelete,
        ),
      ),
    );
  }
}
