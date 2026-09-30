import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:provider/provider.dart';
import '../../models/surah.dart';
import '../../services/local_quran_service.dart';
import '../../services/surah_download_service.dart';
import '../../core/constants/quran_constants.dart';

class QuranIndexScreen extends StatefulWidget {
  final int initialTabIndex;
  const QuranIndexScreen({super.key, this.initialTabIndex = 0});

  @override
  State<QuranIndexScreen> createState() => _QuranIndexScreenState();
}

abstract class IndexItem {}

class JuzHeaderItem extends IndexItem {
  final int juzNumber;
  final String juzName;
  JuzHeaderItem(this.juzNumber, this.juzName);
}

class SurahCardItem extends IndexItem {
  final Surah surah;
  final int startPage;
  SurahCardItem(this.surah, this.startPage);
}

class _QuranIndexScreenState extends State<QuranIndexScreen>
    with SingleTickerProviderStateMixin {
  final LocalQuranService _quranService = LocalQuranService();
  late TabController _tabController;
  late Future<List<Surah>> _surahsFuture;
  List<Surah> _allSurahs = [];
  String _surahSearchQuery = '';
  final TextEditingController _surahSearchController = TextEditingController();

  // Ayah Search state
  final TextEditingController _ayahSearchController = TextEditingController();
  Timer? _ayahSearchDebounce;
  List<QuranSearchResult> _ayahSearchResults = [];
  bool _isSearchingAyahs = false;
  String _lastAyahQuery = '';

  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
    _fetchSurahs();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _surahSearchController.dispose();
    _ayahSearchController.dispose();
    _ayahSearchDebounce?.cancel();
    super.dispose();
  }

  void _fetchSurahs() {
    _surahsFuture = _quranService.getSurahs().then((surahs) {
      _allSurahs = surahs;
      return surahs;
    });
  }

  String _toArabicNumbers(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  String _juzToArabicWord(int juz) {
    const juzNames = [
      'الأول',
      'الثاني',
      'الثالث',
      'الرابع',
      'الخامس',
      'السادس',
      'السابع',
      'الثامن',
      'التاسع',
      'العاشر',
      'الحادي عشر',
      'الثاني عشر',
      'الثالث عشر',
      'الرابع عشر',
      'الخامس عشر',
      'السادس عشر',
      'السابع عشر',
      'الثامن عشر',
      'التاسع عشر',
      'العشرون',
      'الحادي والعشرون',
      'الثاني والعشرون',
      'الثالث والعشرون',
      'الرابع والعشرون',
      'الخامس والعشرون',
      'السادس والعشرون',
      'السابع والعشرون',
      'الثامن والعشرون',
      'التاسع والعشرون',
      'الثلاثون',
    ];
    if (juz >= 1 && juz <= 30) {
      return juzNames[juz - 1];
    }
    return juz.toString();
  }

  int _calculateJuz(int pageNumber) {
    if (pageNumber <= 0) return 1;
    if (pageNumber > 604) return 30;

    for (
      var index = QuranConstants.juzStartPages.length - 1;
      index >= 0;
      index--
    ) {
      if (pageNumber >= QuranConstants.juzStartPages[index]) {
        return index + 1;
      }
    }
    return 1;
  }

  void _navigateToPage(BuildContext context, int page) {
    Navigator.pop(context, page);
  }

  void _onAyahQueryChanged(String query) {
    _ayahSearchDebounce?.cancel();
    _ayahSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      _performAyahSearch(query);
    });
  }

  Future<void> _performAyahSearch(String query) async {
    final trimmed = query.trim();
    _lastAyahQuery = trimmed;

    if (trimmed.length < 2) {
      if (!mounted) return;
      setState(() {
        _ayahSearchResults = [];
        _isSearchingAyahs = false;
      });
      return;
    }

    setState(() {
      _isSearchingAyahs = true;
    });

    try {
      final results = await _quranService.searchAyahs(trimmed);
      if (!mounted || _lastAyahQuery != trimmed) return;
      setState(() {
        _ayahSearchResults = results;
        _isSearchingAyahs = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSearchingAyahs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFFBF8F1),
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF121212)
              : const Color(0xFFFBF8F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'فهرس المصحف الشريف',
            style: GoogleFonts.cairo(
              color: isDark ? goldColor : darkGreen,
              fontWeight: FontWeight.bold,
              fontSize: 19,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            // TabBar (46 + 2 indicator) + 8 vertical margin + 2 border.
            preferredSize: const Size.fromHeight(58),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: goldColor.withValues(alpha: 0.3)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: goldColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: isDark ? Colors.black : Colors.white,
                unselectedLabelColor: isDark
                    ? Colors.grey[400]
                    : Colors.black54,
                labelStyle: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
                tabs: const [
                  Tab(text: 'السور'),
                  Tab(text: 'الأجزاء'),
                  Tab(text: 'البحث في الآيات'),
                ],
              ),
            ),
          ),
        ),
        body: FutureBuilder<List<Surah>>(
          future: _surahsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _allSurahs.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: goldColor),
              );
            } else if (snapshot.hasError && _allSurahs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'فشل تحميل الفهرس: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _fetchSurahs();
                      }),
                      child: Text('إعادة المحاولة', style: GoogleFonts.cairo()),
                    ),
                  ],
                ),
              );
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildSurahsTab(isDark),
                _buildJuzTab(isDark),
                _buildAyahsSearchTab(isDark),
              ],
            );
          },
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 1: SURAHS LIST
  // ----------------------------------------------------
  Widget _buildSurahsTab(bool isDark) {
    final filteredSurahs = _allSurahs.where((s) {
      if (_surahSearchQuery.isEmpty) return true;
      final query = _surahSearchQuery.trim();
      return s.nameArabic.contains(query) || s.id.toString() == query;
    }).toList();

    return Column(
      children: [
        _buildSurahSearchBar(isDark),
        Expanded(
          child: filteredSurahs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'لا توجد سورة مطابقة للبحث',
                        style: GoogleFonts.cairo(
                          fontSize: 15,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = filteredSurahs[index];
                    final startPage =
                        QuranConstants.surahStartPage[surah.id] ?? 1;
                    final juzNumber = _calculateJuz(startPage);
                    final isMakkah =
                        quran.getPlaceOfRevelation(surah.id) == 'Makkah';
                    final verseCount = quran.getVerseCount(surah.id);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : goldColor.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.04,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => _navigateToPage(context, startPage),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                // Surah Number Badge
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: goldColor.withValues(alpha: 0.5),
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _toArabicNumbers(surah.id),
                                    style: GoogleFonts.cairo(
                                      color: isDark ? goldColor : darkGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Surah Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'سورة ${surah.nameArabic}',
                                        style: TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1A1A1A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Wrap(
                                        spacing: 8,
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  (isMakkah
                                                          ? Colors.amber
                                                          : Colors.teal)
                                                      .withValues(alpha: 0.15),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              isMakkah ? 'مكية' : 'مدنية',
                                              style: GoogleFonts.cairo(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: isMakkah
                                                    ? Colors.amber[800]
                                                    : Colors.teal[700],
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${_toArabicNumbers(verseCount)} آية',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                          Text(
                                            '• الجزء ${_toArabicNumbers(juzNumber)}',
                                            style: GoogleFonts.cairo(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.grey[400]
                                                  : Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Download Recitation Audio Button
                                Consumer<SurahDownloadService>(
                                  builder: (context, dlService, child) {
                                    final isDownloading = dlService
                                        .isDownloading(surah.id);
                                    final isDownloaded = dlService.isDownloaded(
                                      surah.id,
                                    );
                                    final progress = dlService.getSurahProgress(
                                      surah.id,
                                    );
                                    final percent = (progress * 100).toInt();

                                    return IconButton(
                                      iconSize: 22,
                                      padding: const EdgeInsets.all(6),
                                      constraints: const BoxConstraints(),
                                      tooltip: isDownloading
                                          ? 'جاري التحميل... ($percent%)'
                                          : isDownloaded
                                          ? 'تلاوة محملة (اضغط للحذف)'
                                          : 'تحميل تلاوة السورة للاستماع بدون نت',
                                      icon: isDownloading
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                value: progress > 0
                                                    ? progress
                                                    : null,
                                                strokeWidth: 2,
                                                color: goldColor,
                                              ),
                                            )
                                          : Icon(
                                              isDownloaded
                                                  ? Icons.offline_pin_rounded
                                                  : Icons
                                                        .download_for_offline_outlined,
                                              color: isDownloaded
                                                  ? Colors.green
                                                  : (isDark
                                                        ? Colors.grey[400]
                                                        : goldColor),
                                            ),
                                      onPressed: isDownloading
                                          ? null
                                          : () async {
                                              if (isDownloaded) {
                                                await dlService.remove(
                                                  surah.id,
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(
                                                    context,
                                                  ).showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        'تم حذف تلاوة سورة ${surah.nameArabic}',
                                                        style:
                                                            GoogleFonts.cairo(),
                                                      ),
                                                      duration: const Duration(
                                                        seconds: 2,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              } else {
                                                try {
                                                  await dlService.download(
                                                    surah.id,
                                                  );
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'تم تحميل تلاوة سورة ${surah.nameArabic} بنجاح!',
                                                          style:
                                                              GoogleFonts.cairo(),
                                                        ),
                                                        backgroundColor:
                                                            darkGreen,
                                                        duration:
                                                            const Duration(
                                                              seconds: 2,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                } catch (e) {
                                                  if (context.mounted) {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      SnackBar(
                                                        content: Text(
                                                          'تعذر استكمال تحميل تلاوة سورة ${surah.nameArabic}. يمكنك المحاولة مرة أخرى للاستئناف من حيث توقف.',
                                                          style:
                                                              GoogleFonts.cairo(),
                                                        ),
                                                        backgroundColor:
                                                            Colors.redAccent,
                                                        duration:
                                                            const Duration(
                                                              seconds: 4,
                                                            ),
                                                      ),
                                                    );
                                                  }
                                                }
                                              }
                                            },
                                    );
                                  },
                                ),
                                const SizedBox(width: 6),
                                // Start Page Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: goldColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    'ص ${_toArabicNumbers(startPage)}',
                                    style: GoogleFonts.cairo(
                                      color: isDark ? goldColor : darkGreen,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSurahSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _surahSearchController,
        onChanged: (value) {
          setState(() {
            _surahSearchQuery = value;
          });
        },
        style: GoogleFonts.cairo(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          hintText: 'ابحث باسم السورة أو رقمها...',
          hintStyle: GoogleFonts.cairo(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
            fontSize: 13.5,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: goldColor),
          suffixIcon: _surahSearchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _surahSearchController.clear();
                    setState(() {
                      _surahSearchQuery = '';
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: goldColor.withValues(alpha: 0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: goldColor.withValues(alpha: 0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: goldColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 0,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // TAB 2: JUZ LIST
  // ----------------------------------------------------
  Widget _buildJuzTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 30,
      itemBuilder: (context, index) {
        final juzNumber = index + 1;
        final juzName = _juzToArabicWord(juzNumber);
        final startPage = QuranConstants.juzStartPages[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : goldColor.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _navigateToPage(context, startPage),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: goldColor.withValues(alpha: 0.6),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _toArabicNumbers(juzNumber),
                        style: GoogleFonts.cairo(
                          color: isDark ? goldColor : darkGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الجزء $juzName',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : darkGreen,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'يبدأ من الصفحة ${_toArabicNumbers(startPage)}',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: goldColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'صفحة ${_toArabicNumbers(startPage)}',
                            style: GoogleFonts.cairo(
                              color: isDark ? goldColor : darkGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: goldColor,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------
  // TAB 3: AYAHS FULL-TEXT SEARCH
  // ----------------------------------------------------
  Widget _buildAyahsSearchTab(bool isDark) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _ayahSearchController,
            onChanged: _onAyahQueryChanged,
            style: GoogleFonts.cairo(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'ابحث عن أي كلمة أو آية في القرآن الكريم...',
              hintStyle: GoogleFonts.cairo(
                color: isDark ? Colors.grey[500] : Colors.grey[600],
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(Icons.search_rounded, color: goldColor),
              suffixIcon: _ayahSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _ayahSearchController.clear();
                        _onAyahQueryChanged('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: goldColor.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: goldColor.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: goldColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 16,
              ),
            ),
          ),
        ),
        if (_isSearchingAyahs)
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: CircularProgressIndicator(color: goldColor)),
          )
        else if (_lastAyahQuery.length >= 2 && _ayahSearchResults.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off_rounded,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'لم يتم العثور على آيات مطابقة لـ "$_lastAyahQuery"',
                    style: GoogleFonts.cairo(
                      fontSize: 14.5,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (_ayahSearchResults.isNotEmpty)
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _ayahSearchResults.length,
              itemBuilder: (context, index) {
                final item = _ayahSearchResults[index];
                final ayah = item.ayah;
                final surah = item.surah;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : goldColor.withValues(alpha: 0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.04,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _navigateToPage(context, ayah.pageNumber),
                      child: Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: goldColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'سورة ${surah.nameArabic} • آية ${_toArabicNumbers(ayah.ayahNumber)}',
                                      style: GoogleFonts.cairo(
                                        color: isDark ? goldColor : darkGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'صفحة ${_toArabicNumbers(ayah.pageNumber)}',
                                  style: GoogleFonts.cairo(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              ayah.textUthmani,
                              style: TextStyle(
                                fontFamily: 'UthmanicHafs',
                                fontSize: 18,
                                height: 1.8,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.auto_stories_rounded,
                      size: 56,
                      color: goldColor.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'البحث في القرآن الكريم',
                      style: GoogleFonts.cairo(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : darkGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'اكتب حرفين أو أكثر للبحث في جميع آيات وسور المصحف الشريف والانتقال إليها مباشرةً.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.cairo(
                        fontSize: 13.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
