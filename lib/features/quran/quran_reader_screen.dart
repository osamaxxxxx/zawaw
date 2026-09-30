import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/surah.dart';
import '../../models/ayah.dart';
import '../../services/local_quran_service.dart';
import '../../services/tafsir_service.dart';
import '../../services/audio_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import '../../core/constants/quran_constants.dart';
import '../../core/settings/quran_display_settings.dart';
import '../../core/theme/theme_provider.dart';
import 'package:quran/quran.dart' as quran;
import '../../services/surah_download_service.dart';
import '../../services/widget_sync_service.dart';
import 'quran_index_screen.dart';

class QuranReaderScreen extends StatefulWidget {
  final int? initialPage;
  final int? initialHighlightSurahId;
  final int? initialHighlightAyahNumber;

  const QuranReaderScreen({
    super.key,
    this.initialPage,
    this.initialHighlightSurahId,
    this.initialHighlightAyahNumber,
  });

  @override
  State<QuranReaderScreen> createState() => _QuranReaderScreenState();
}

class _QuranReaderScreenState extends State<QuranReaderScreen> {
  final LocalQuranService _quranService = LocalQuranService();
  final TafsirService _tafsirService = TafsirService();
  late PageController _pageController;
  int _currentPage = 1;
  int? _playingAyahId;
  int? _highlightedAyahId;
  int? _highlightedSurahId;
  int? _highlightedAyahNumber;
  Timer? _highlightTimer;
  List<Surah> _cachedSurahs = [];
  List<Map<String, dynamic>> _savedAyahs = [];
  Set<int> _savedPages = {};
  final Map<int, List<Ayah>> _pageAyahsCache = {};
  final Map<int, Object> _pageLoadErrors = {};
  final Set<int> _loadingPages = {};

  final Color goldColor = const Color(0xFFD4AF37); // Gold

  AudioService? _audioService;

  @override
  void initState() {
    super.initState();
    _currentPage = (widget.initialPage ?? 1).clamp(1, 604);
    _highlightedSurahId = widget.initialHighlightSurahId;
    _highlightedAyahNumber = widget.initialHighlightAyahNumber;
    _pageController = PageController(initialPage: _currentPage - 1);
    _primeFromLoadedQuran();
    _loadSurahs();
    _loadSavedAyahs();
    _loadSavedPages();
    _preloadNearbyPages(_currentPage);
    if (widget.initialPage == null) {
      _restoreLastReadPage();
    } else {
      _saveLastPage(_currentPage);
      if (_highlightedSurahId != null && _highlightedAyahNumber != null) {
        _clearInitialHighlightLater();
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _audioService = Provider.of<AudioService>(context, listen: false);
      _audioService?.addListener(_onAudioServiceChanged);
    });
  }

  void _onAudioServiceChanged() {
    if (_audioService != null) {
      // Clear highlight if not playing or if playing a full Surah (which has a currentSurahId)
      if (!_audioService!.isPlaying || _audioService!.currentSurahId != null) {
        if (_playingAyahId != null) {
          setState(() {
            _playingAyahId = null;
          });
        }
      }
    }
  }

  Future<void> _loadSurahs() async {
    try {
      _cachedSurahs =
          _quranService.getCachedSurahs() ?? await _quranService.getSurahs();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Failed to load surahs for names: $e');
    }
  }

  void _primeFromLoadedQuran() {
    final surahs = _quranService.getCachedSurahs();
    if (surahs != null) {
      _cachedSurahs = surahs;
    }

    for (final pageNumber in [
      _currentPage,
      _currentPage - 2,
      _currentPage - 1,
      _currentPage + 1,
      _currentPage + 2,
    ]) {
      final ayahs = _quranService.getCachedAyahsByPage(pageNumber);
      if (ayahs != null) {
        _pageAyahsCache[pageNumber] = ayahs;
      }
    }
  }

  Future<void> _loadSavedAyahs() async {
    final prefs = await SharedPreferences.getInstance();
    final ayahsJson = prefs.getStringList('saved_ayahs') ?? [];
    _savedAyahs = ayahsJson
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();
    if (mounted) setState(() {});
  }

  Future<void> _loadSavedPages() async {
    final prefs = await SharedPreferences.getInstance();
    final pagesJson = prefs.getStringList('saved_pages') ?? [];
    _savedPages = pagesJson
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .map((page) => page['page'] as int?)
        .whereType<int>()
        .toSet();
    if (mounted) setState(() {});
  }

  Future<void> _loadPageAyahs(int pageNumber, {bool notify = true}) async {
    if (pageNumber < 1 || pageNumber > 604) return;
    if (_pageAyahsCache.containsKey(pageNumber) ||
        _loadingPages.contains(pageNumber)) {
      return;
    }

    _loadingPages.add(pageNumber);
    if (notify && mounted) setState(() {});

    try {
      final ayahs =
          _quranService.getCachedAyahsByPage(pageNumber) ??
          await _quranService.getAyahsByPage(pageNumber);
      _pageAyahsCache[pageNumber] = ayahs;
      _pageLoadErrors.remove(pageNumber);
    } catch (error) {
      _pageLoadErrors[pageNumber] = error;
    } finally {
      _loadingPages.remove(pageNumber);
      if (mounted) setState(() {});
    }
  }

  void _preloadNearbyPages(int pageNumber) {
    _loadPageAyahs(pageNumber);
    for (final nearbyPage in [
      pageNumber - 2,
      pageNumber - 1,
      pageNumber + 1,
      pageNumber + 2,
    ]) {
      _loadPageAyahs(nearbyPage, notify: false);
    }
  }

  String _getSurahName(int surahId) {
    try {
      return _cachedSurahs.firstWhere((s) => s.id == surahId).nameArabic;
    } catch (_) {
      return '';
    }
  }

  Future<void> _saveLastPage(int page) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_read_page', page);
  }

  Future<void> _restoreLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    final page = (prefs.getInt('last_read_page') ?? 1).clamp(1, 604);
    if (!mounted || page == _currentPage) return;

    _pageController.jumpToPage(page - 1);
    setState(() {
      _currentPage = page;
    });
    _preloadNearbyPages(page);
  }

  void _clearInitialHighlightLater() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      setState(() {
        _highlightedSurahId = null;
        _highlightedAyahNumber = null;
      });
    });
  }

  Future<void> _openQuranIndex() async {
    final selectedPage = await Navigator.push<int>(
      context,
      MaterialPageRoute(builder: (context) => const QuranIndexScreen()),
    );

    if (!mounted || selectedPage == null) return;

    final page = selectedPage.clamp(1, 604);
    _pageController.jumpToPage(page - 1);
    setState(() {
      _currentPage = page;
    });
    _preloadNearbyPages(page);
    await _saveLastPage(page);
  }

  Future<void> _openSearchResult(QuranSearchResult result) async {
    final page = result.ayah.pageNumber.clamp(1, 604);

    _highlightTimer?.cancel();
    _pageController.jumpToPage(page - 1);
    setState(() {
      _currentPage = page;
      _highlightedAyahId = result.ayah.id;
      _highlightedSurahId = null;
      _highlightedAyahNumber = null;
    });
    _preloadNearbyPages(page);
    await _saveLastPage(page);

    _highlightTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || _highlightedAyahId != result.ayah.id) return;
      setState(() {
        _highlightedAyahId = null;
      });
    });
  }

  String? _quranFontFamily(QuranDisplaySettings settings) {
    return _quranFontFamilyForId(settings.fontFamilyId);
  }

  String? _quranFontFamilyForId(String fontFamilyId) {
    switch (fontFamilyId) {
      case 'uthmanic_hafs':
        return 'UthmanicHafs';
      case 'amiri_quran':
        return GoogleFonts.amiriQuran().fontFamily;
      case 'noto_naskh':
        return GoogleFonts.notoNaskhArabic().fontFamily;
      case 'amiri':
        return GoogleFonts.amiri().fontFamily;
      case 'lateef':
        return GoogleFonts.lateef().fontFamily;
      case 'tajawal':
        return GoogleFonts.tajawal().fontFamily;
      case 'almarai':
        return GoogleFonts.almarai().fontFamily;
      case 'el_messiri':
        return GoogleFonts.elMessiri().fontFamily;
      case 'aref_ruqaa':
        return GoogleFonts.arefRuqaa().fontFamily;
      case 'reem_kufi':
        return GoogleFonts.reemKufi().fontFamily;
      case 'cairo':
        return GoogleFonts.cairo().fontFamily;
      case 'scheherazade':
      default:
        return GoogleFonts.scheherazadeNew().fontFamily;
    }
  }

  void _showQuranSettingsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        const goldColor = Color(0xFFD4AF37);
        const darkGreen = Color(0xFF1B4332);

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.88,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: goldColor.withValues(alpha: isDark ? 0.2 : 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Consumer<QuranDisplaySettings>(
                builder: (context, settings, child) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Drag Handle & Header
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Column(
                          children: [
                            Container(
                              width: 42,
                              height: 4.5,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white24 : Colors.black26,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.settings_suggest_rounded,
                                    color: goldColor,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'إعدادات المصحف والقراءة',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: isDark ? Colors.white : darkGreen,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () =>
                                      Navigator.of(sheetContext).pop(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Scrollable Body
                      Flexible(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 12,
                          ),
                          children: [
                            // 1. Ayah Search Panel
                            _QuranAyahSearchPanel(
                              quranService: _quranService,
                              toArabicNumbers: _toArabicNumbers,
                              onResultSelected: (result) {
                                Navigator.of(sheetContext).pop();
                                _openSearchResult(result);
                              },
                            ),
                            const SizedBox(height: 16),

                            // 2. Live Verse Preview Box
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0xFF1E1E1E)
                                    : const Color(0xFFFAF7EE),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: goldColor.withValues(alpha: 0.35),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    'معاينة الخط الحيّة',
                                    style: GoogleFonts.cairo(
                                      fontSize: 11.5,
                                      color: goldColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '( وَإِذَا قُرِئَ ٱلْقُرْءَانُ فَٱسْتَمِعُوا۟ لَهُۥ وَأَنصِتُوا۟ لَعَلَّكُمْ تُرْحَمُونَ )',
                                    textAlign: TextAlign.center,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      fontFamily: _quranFontFamilyForId(
                                        settings.fontFamilyId,
                                      ),
                                      fontSize: (20.0 * settings.fontScale)
                                          .clamp(14.0, 32.0),
                                      height: 1.7,
                                      color: isDark
                                          ? Colors.white
                                          : const Color(0xFF1B4332),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 3. Font Size Slider
                            Row(
                              children: [
                                const Icon(
                                  Icons.format_size_rounded,
                                  color: goldColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'حجم خط الآيات',
                                  style: GoogleFonts.cairo(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : darkGreen,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: goldColor.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${(settings.fontScale * 100).toInt()}%',
                                    style: GoogleFonts.cairo(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? goldColor : darkGreen,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: settings.fontScale,
                              min: QuranDisplaySettings.minFontScale,
                              max: QuranDisplaySettings.maxFontScaleWithScroll,
                              divisions: 24,
                              activeColor: goldColor,
                              inactiveColor: isDark
                                  ? Colors.grey[800]
                                  : Colors.grey[300],
                              onChanged: (value) {
                                settings.setFontScale(value);
                              },
                            ),
                            const SizedBox(height: 12),

                            // 4. Dark Mode Switch
                            Consumer<ThemeProvider>(
                              builder: (context, themeProvider, child) {
                                final isDarkMode =
                                    themeProvider.themeMode == ThemeMode.dark ||
                                    (themeProvider.themeMode ==
                                            ThemeMode.system &&
                                        MediaQuery.of(
                                              context,
                                            ).platformBrightness ==
                                            Brightness.dark);
                                return Container(
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF1E1E1E)
                                        : const Color(0xFFF9F9F9),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white10
                                          : Colors.black12,
                                    ),
                                  ),
                                  child: SwitchListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    title: Text(
                                      'المظهر الداكن (Dark Mode)',
                                      style: GoogleFonts.cairo(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    secondary: Icon(
                                      isDarkMode
                                          ? Icons.dark_mode_rounded
                                          : Icons.light_mode_rounded,
                                      color: goldColor,
                                      size: 22,
                                    ),
                                    activeThumbColor: goldColor,
                                    value: isDarkMode,
                                    onChanged: (value) {
                                      themeProvider.toggleTheme(value);
                                    },
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),

                            // 5. Quran Font Selection
                            Text(
                              'نوع خط المصحف (12 خط متوفر):',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: isDark ? Colors.white : darkGreen,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...QuranDisplaySettings.fontOptions.map((option) {
                              final isSelected =
                                  settings.fontFamilyId == option.id;
                              return InkWell(
                                onTap: () => settings.setFontFamily(option.id),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? goldColor.withValues(alpha: 0.12)
                                        : (isDark
                                              ? const Color(0xFF1E1E1E)
                                              : const Color(0xFFF9F9F9)),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected
                                          ? goldColor
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.black12),
                                      width: isSelected ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked_rounded
                                            : Icons.radio_button_off_rounded,
                                        color: isSelected
                                            ? goldColor
                                            : Colors.grey,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              option.name,
                                              style: GoogleFonts.cairo(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13.5,
                                                color: isSelected
                                                    ? goldColor
                                                    : (isDark
                                                          ? Colors.white
                                                          : Colors.black87),
                                              ),
                                            ),
                                            Text(
                                              option.preview,
                                              textDirection: TextDirection.rtl,
                                              style: TextStyle(
                                                fontFamily:
                                                    _quranFontFamilyForId(
                                                      option.id,
                                                    ),
                                                fontSize: 15,
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
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

  String _toArabicNumbers(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }

  void _playAyahAudio(BuildContext context, Ayah ayah) async {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final surahId = ayah.surahId;

    try {
      final savedPositionSec = await SharedPrefsHelper.getSurahPosition(
        surahId,
      );
      if (savedPositionSec != null && savedPositionSec > 0) {
        if (context.mounted) {
          _onSurahLongPress(context, surahId);
        }
      } else {
        await audioService.playSurah(surahId, startPosition: Duration.zero);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تشغيل التلاوة: $e')),
        );
      }
    }
  }

  void _onSurahLongPress(BuildContext context, int surahId) async {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final surahName = _getSurahName(surahId);
    final savedPositionSec = await SharedPrefsHelper.getSurahPosition(surahId);
    final verseCount = quran.getVerseCount(surahId);
    final isMakkah = quran.getPlaceOfRevelation(surahId) == 'Makkah';
    final revelationText = isMakkah ? 'مَكِّيَّة' : 'مَدَنِيَّة';
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);

    if (!context.mounted) return;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181818) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: goldColor.withValues(alpha: isDark ? 0.25 : 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Consumer<SurahDownloadService>(
              builder: (ctx, dlService, _) {
                final isDownloading = dlService.isDownloading(surahId);
                final isDownloaded = dlService.isDownloaded(surahId);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Surah Header Card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFFAF7EE),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: goldColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: goldColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: goldColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'سُورَةُ $surahName',
                                  style: GoogleFonts.amiri(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? goldColor : darkGreen,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$revelationText • ${_toArabicNumbers(verseCount)} آية',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    color: isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.of(sheetContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 1. Play Recitation Card
                    Container(
                      decoration: BoxDecoration(
                        color: goldColor.withValues(
                          alpha: isDark ? 0.12 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: goldColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: goldColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: goldColor.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        title: Text(
                          'تشغيل تلاوة السورة',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 15.5,
                            color: isDark ? Colors.white : darkGreen,
                          ),
                        ),
                        subtitle: Text(
                          savedPositionSec != null && savedPositionSec > 0
                              ? 'استئناف من ${_formatDuration(Duration(seconds: savedPositionSec))}'
                              : 'بصوت الشيخ عبدالرحمن الزواوي',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[700],
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: goldColor,
                        ),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          audioService.playSurah(
                            surahId,
                            startPosition:
                                (savedPositionSec != null &&
                                    savedPositionSec > 0)
                                ? Duration(seconds: savedPositionSec)
                                : Duration.zero,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 2. Download Recitation Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF222222)
                            : const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDownloaded
                              ? Colors.green.withValues(alpha: 0.5)
                              : (isDark ? Colors.white12 : Colors.black12),
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isDownloaded ? Colors.green : goldColor)
                                .withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: isDownloading
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    value: dlService.getSurahProgress(surahId) > 0 ? dlService.getSurahProgress(surahId) : null,
                                    strokeWidth: 2.5,
                                    color: goldColor,
                                  ),
                                )
                              : Icon(
                                  isDownloaded
                                      ? Icons.check_circle_rounded
                                      : Icons.download_for_offline_rounded,
                                  color: isDownloaded
                                      ? Colors.green
                                      : goldColor,
                                  size: 24,
                                ),
                        ),
                        title: Text(
                          isDownloading
                              ? 'جاري تحميل التلاوة... (${(dlService.getSurahProgress(surahId) * 100).toInt()}%)'
                              : isDownloaded
                              ? 'التلاوة محملة (جاهزة للاستماع بدون نت)'
                              : 'تحميل التلاوة للاستماع دون إنترنت',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: isDownloaded
                                ? Colors.green
                                : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isDownloading
                                  ? 'يتم حفظ السورة بجهازك للاستماع بدون إنترنت'
                                  : isDownloaded
                                  ? 'الملف محفوظ بجهازك. اضغط للحذف إن أردت.'
                                  : 'حفظ السورة لتشغيلها في أي وقت بدون إنترنت',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            if (isDownloading) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: dlService.getSurahProgress(surahId) > 0 ? dlService.getSurahProgress(surahId) : null,
                                  backgroundColor: (isDark ? Colors.white12 : Colors.black12),
                                  color: goldColor,
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: isDownloaded
                            ? IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  color: Colors.redAccent,
                                ),
                                tooltip: 'حذف من الجهاز',
                                onPressed: () async {
                                  await dlService.remove(surahId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم حذف تلاوة سورة $surahName من الجهاز',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        backgroundColor: darkGreen,
                                      ),
                                    );
                                  }
                                },
                              )
                            : null,
                        onTap: isDownloading
                            ? null
                            : () async {
                                if (isDownloaded) {
                                  await dlService.remove(surahId);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم حذف تلاوة سورة $surahName',
                                          style: GoogleFonts.cairo(),
                                        ),
                                        backgroundColor: darkGreen,
                                      ),
                                    );
                                  }
                                } else {
                                  try {
                                    await dlService.download(surahId);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'تم تحميل تلاوة سورة $surahName بنجاح!',
                                            style: GoogleFonts.cairo(),
                                          ),
                                          backgroundColor: darkGreen,
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
                                            'تعذر استكمال تحميل التلاوة. يمكنك الضغط مجدداً للمتابعة من حيث توقف.',
                                            style: GoogleFonts.cairo(),
                                          ),
                                          backgroundColor: Colors.redAccent,
                                          duration: const Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _toggleCurrentPageSave(String surahName) async {
    final prefs = await SharedPreferences.getInstance();
    final pagesJson = prefs.getStringList('saved_pages') ?? [];
    List<Map<String, dynamic>> savedPages = pagesJson
        .map((e) => jsonDecode(e) as Map<String, dynamic>)
        .toList();

    final savedPageIndex = savedPages.indexWhere(
      (page) => page['page'] == _currentPage,
    );
    if (savedPageIndex != -1) {
      savedPages.removeAt(savedPageIndex);
      await prefs.setStringList(
        'saved_pages',
        savedPages.map((e) => jsonEncode(e)).toList(),
      );
      _savedPages.remove(_currentPage);
      if (mounted) setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إلغاء حفظ الصفحة',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
      return;
    }

    // Check if page already exists
    if (!savedPages.any((p) => p['page'] == _currentPage)) {
      savedPages.add({
        'page': _currentPage,
        'surahName': surahName,
        'timestamp': DateTime.now().toIso8601String(),
      });
      await prefs.setStringList(
        'saved_pages',
        savedPages.map((e) => jsonEncode(e)).toList(),
      );
      _savedPages.add(_currentPage);
      if (mounted) setState(() {});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'تم حفظ الصفحة بنجاح',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: goldColor,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'هذه الصفحة محفوظة مسبقاً',
              style: TextStyle(
                fontFamily: 'Cairo',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: goldColor.withValues(alpha: 0.85),
          ),
        );
      }
    }
  }

  void _showColorPickerDialog(BuildContext context, Ayah ayah) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 16.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'اختر لون حفظ الآية',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: kSavedAyahColors.map((colorOption) {
                    final color =
                        Theme.of(context).brightness == Brightness.dark
                        ? colorOption.darkColor
                        : colorOption.lightColor;
                    return InkWell(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _saveAyahWithColor(ayah, colorOption.id);
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            colorOption.nameArabic,
                            style: const TextStyle(
                              fontFamily: 'Cairo',
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveAyahWithColor(Ayah ayah, String colorId) async {
    final prefs = await SharedPreferences.getInstance();

    _savedAyahs.removeWhere(
      (a) => a['surah'] == ayah.surahId && a['ayah'] == ayah.ayahNumber,
    );

    _savedAyahs.add({
      'surah': ayah.surahId,
      'ayah': ayah.ayahNumber,
      'text': ayah.textUthmani,
      'page': ayah.pageNumber,
      'color': colorId,
    });

    await prefs.setStringList(
      'saved_ayahs',
      _savedAyahs.map((e) => jsonEncode(e)).toList(),
    );
    await WidgetSyncService.refresh();
    setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'تم حفظ الآية باللون المختار',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: goldColor,
        ),
      );
    }
  }

  Color? _getSavedAyahColor(Ayah ayah, bool isDark) {
    for (var saved in _savedAyahs) {
      if (saved['surah'] == ayah.surahId && saved['ayah'] == ayah.ayahNumber) {
        final colorId = saved['color'] as String? ?? 'green';
        final match = kSavedAyahColors.firstWhere(
          (c) => c.id == colorId,
          orElse: () => kSavedAyahColors.first,
        );
        return isDark ? match.darkColor : match.lightColor;
      }
    }
    return null;
  }

  Future<void> _showStableTafsirSheet(Ayah ayah) async {
    final surahName = _getSurahName(ayah.surahId);
    final ayahNumberArabic = _toArabicNumbers(ayah.ayahNumber);
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF161616) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: goldColor.withValues(alpha: isDark ? 0.25 : 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 42,
                        height: 4.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : Colors.black26,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),

                    // Header Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: goldColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: goldColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تفسير الآية الكريمة',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : darkGreen,
                              ),
                            ),
                            Text(
                              'سورة $surahName • الآية $ayahNumberArabic',
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                color: isDark ? goldColor : darkGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(sheetContext).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Scrollable Tafsir Content
                    Flexible(
                      child: FutureBuilder<String>(
                        future: _tafsirService.getTafsir(
                          surahId: ayah.surahId,
                          ayahNumber: ayah.ayahNumber,
                        ),
                        builder: (context, snapshot) {
                          final isLoading =
                              snapshot.connectionState ==
                              ConnectionState.waiting;

                          return ListView(
                            children: [
                              // 1. Ayah Preview Card
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 14,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1F1F1F)
                                      : const Color(0xFFFAF7EE),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: goldColor.withValues(alpha: 0.35),
                                    width: 1.0,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: goldColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'نص الآية الكريمة',
                                          style: GoogleFonts.cairo(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                            color: goldColor,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          width: 5,
                                          height: 5,
                                          decoration: const BoxDecoration(
                                            color: goldColor,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '( ${ayah.textUthmani} )',
                                      textAlign: TextAlign.center,
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 20,
                                        height: 1.7,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1B4332),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // 2. Tafsir Explanation Box
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF1E1E1E)
                                      : const Color(0xFFFBFBFB),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.black12,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(
                                              alpha: 0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            'التفسير الميسّر',
                                            style: GoogleFonts.cairo(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        if (snapshot.hasData &&
                                            snapshot.data!.isNotEmpty)
                                          IconButton(
                                            icon: const Icon(
                                              Icons.copy_rounded,
                                              size: 18,
                                              color: goldColor,
                                            ),
                                            tooltip: 'نسخ نص التفسير',
                                            onPressed: () {
                                              Clipboard.setData(
                                                ClipboardData(
                                                  text:
                                                      '(${ayah.textUthmani}) [سورة $surahName: ${ayah.ayahNumber}]\n\nالتفسير الميسر:\n${snapshot.data}',
                                                ),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'تم نسخ الآية مع التفسير بنجاح',
                                                    style: GoogleFonts.cairo(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor: darkGreen,
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    if (isLoading)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: Center(
                                          child: Column(
                                            children: [
                                              CircularProgressIndicator(
                                                color: goldColor,
                                                strokeWidth: 2.5,
                                              ),
                                              SizedBox(height: 12),
                                              Text(
                                                'جارٍ تحميل التفسير الميسر...',
                                                style: TextStyle(
                                                  fontFamily: 'Cairo',
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    else if (snapshot.hasError)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 20,
                                        ),
                                        child: Column(
                                          children: [
                                            const Icon(
                                              Icons.wifi_off_rounded,
                                              size: 36,
                                              color: Colors.orangeAccent,
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'تعذر جلب التفسير. يرجى التحقق من الاتصال بالإنترنت.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.cairo(
                                                fontSize: 13.5,
                                                color: isDark
                                                    ? Colors.grey[300]
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    else
                                      Text(
                                        snapshot.data ?? '',
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          fontFamily: 'Cairo',
                                          fontSize: 16.5,
                                          height: 1.85,
                                          color: isDark
                                              ? Colors.grey[200]
                                              : const Color(0xFF2C3E50),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                          );
                        },
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

  void _showAyahOptions(BuildContext context, Ayah ayah) {
    final isSaved = _isAyahSaved(ayah);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const goldColor = Color(0xFFD4AF37);
    const darkGreen = Color(0xFF1B4332);
    final surahName = _getSurahName(ayah.surahId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.82,
            ),
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF181818) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              border: Border.all(
                color: goldColor.withValues(alpha: isDark ? 0.25 : 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4.5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Ayah Header Preview Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF222222)
                          : const Color(0xFFFAF7EE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: goldColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: goldColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'سورة $surahName • آية ${_toArabicNumbers(ayah.ayahNumber)}',
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                  color: isDark ? goldColor : darkGreen,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '( ${ayah.textUthmani} )',
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 18,
                            height: 1.6,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1B4332),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Action 1: Tafsir
                  _buildAyahActionTile(
                    context: sheetContext,
                    icon: Icons.auto_stories_rounded,
                    title: 'تفسير هذه الآية',
                    subtitle: 'عرض التفسير الميسر وبيان معاني الكلمات',
                    color: Colors.teal,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showStableTafsirSheet(ayah);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Action 2: Bookmark / Color
                  _buildAyahActionTile(
                    context: sheetContext,
                    icon: isSaved
                        ? Icons.color_lens_rounded
                        : Icons.bookmark_add_rounded,
                    title: isSaved
                        ? 'تغيير لون العلامة المحفوظة'
                        : 'حفظ الآية بعلامة مرجعية',
                    subtitle: isSaved
                        ? 'تعديل لون التمييز المحفوظ للآية'
                        : 'إضافة الآية إلى محفوظاتك للرجوع إليها',
                    color: Colors.amber.shade700,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showColorPickerDialog(context, ayah);
                    },
                  ),
                  const SizedBox(height: 8),

                  // Action 3: Copy Ayah
                  _buildAyahActionTile(
                    context: sheetContext,
                    icon: Icons.copy_all_rounded,
                    title: 'نسخ الآية الكريمة',
                    subtitle: 'نسخ نص الآية مع التوثيق باسم السورة ورقمها',
                    color: Colors.blue.shade700,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Clipboard.setData(
                        ClipboardData(
                          text:
                              '(${ayah.textUthmani}) [سورة ${_getSurahName(ayah.surahId)}: ${ayah.ayahNumber}]',
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'تم نسخ الآية الكريمة بنجاح',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: darkGreen,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  // Action 4: Audio
                  _buildAyahActionTile(
                    context: sheetContext,
                    icon: Icons.volume_up_rounded,
                    title: 'الاستماع إلى سورة $surahName',
                    subtitle: 'تشغيل أو تحميل التلاوة بصوت الشيخ',
                    color: goldColor,
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _onSurahLongPress(context, ayah.surahId);
                    },
                  ),

                  // Action 5: Remove Bookmark if saved
                  if (isSaved) ...[
                    const SizedBox(height: 8),
                    _buildAyahActionTile(
                      context: sheetContext,
                      icon: Icons.bookmark_remove_rounded,
                      title: 'إلغاء حفظ هذه الآية',
                      subtitle:
                          'إزالة الآية من قائمة المحفوظات والعلامات المرجعية',
                      color: Colors.redAccent,
                      isDark: isDark,
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        await _removeSavedAyah(ayah);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAyahActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : const Color(0xFFF9F9F9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B4332),
                        ),
                      ),
                      Text(
                        subtitle,
                        style: GoogleFonts.cairo(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _removeSavedAyah(Ayah ayah) async {
    final prefs = await SharedPreferences.getInstance();
    _savedAyahs.removeWhere(
      (a) => a['surah'] == ayah.surahId && a['ayah'] == ayah.ayahNumber,
    );
    await prefs.setStringList(
      'saved_ayahs',
      _savedAyahs.map((e) => jsonEncode(e)).toList(),
    );
    await WidgetSyncService.refresh();
    if (mounted) setState(() {});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم إلغاء حفظ الآية',
            style: TextStyle(
              fontFamily: 'Cairo',
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  bool _isAyahSaved(Ayah ayah) {
    return _savedAyahs.any(
      (a) => a['surah'] == ayah.surahId && a['ayah'] == ayah.ayahNumber,
    );
  }

  bool get _isCurrentPageSaved => _savedPages.contains(_currentPage);

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _audioService?.removeListener(_onAudioServiceChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageColor = isDark ? Colors.black : const Color(0xFFFDF6E3);
    final displaySettings = context.watch<QuranDisplaySettings>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: pageColor,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 4.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: goldColor, size: 28),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'العودة للفهرس',
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.settings_outlined,
                        color: goldColor,
                        size: 26,
                      ),
                      onPressed: _showQuranSettingsSheet,
                      tooltip: 'إعدادات المصحف',
                    ),
                  ],
                ),
              ),
              // Page View
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  allowImplicitScrolling: true,
                  itemCount: 604,
                  onPageChanged: (index) {
                    final newPage = index + 1;
                    setState(() {
                      _currentPage = newPage;
                    });
                    _preloadNearbyPages(newPage);
                    _saveLastPage(newPage);
                  },
                  itemBuilder: (context, index) {
                    return _buildPageContent(
                      context,
                      index + 1,
                      theme,
                      isDark,
                      displaySettings,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageContent(
    BuildContext context,
    int pageNumber,
    ThemeData theme,
    bool isDark,
    QuranDisplaySettings displaySettings,
  ) {
    final textColor = isDark ? Colors.white : Colors.black87;

    if (!_pageAyahsCache.containsKey(pageNumber) &&
        !_loadingPages.contains(pageNumber)) {
      _loadPageAyahs(pageNumber);
    }

    final error = _pageLoadErrors[pageNumber];
    if (error != null) {
      return Center(
        child: Text(
          'Load error: $error',
          style: TextStyle(color: textColor, fontFamily: 'Amiri'),
        ),
      );
    }

    final ayahs =
        _pageAyahsCache[pageNumber] ??
        _quranService.getCachedAyahsByPage(pageNumber);
    if (ayahs == null) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4, color: goldColor),
        ),
      );
    }

    if (ayahs.isEmpty) {
      return const Center(child: Text('لا توجد آيات في هذه الصفحة'));
    }

    final primarySurahId = ayahs.first.surahId;
    final surahName = _getSurahName(primarySurahId);
    final juzNumber = _calculateJuz(pageNumber);

    final Map<int, List<Ayah>> ayahsBySurah = {};
    for (var ayah in ayahs) {
      if (!ayahsBySurah.containsKey(ayah.surahId)) {
        ayahsBySurah[ayah.surahId] = [];
      }
      ayahsBySurah[ayah.surahId]!.add(ayah);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mushaf Top App Bar (Surah RIGHT, Juz LEFT in RTL)
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Right side (First child in RTL): Surah Name interactive button
                Tooltip(
                  message: 'اضغط لفتح فهرس السور والبحث',
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _openQuranIndex,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: goldColor.withValues(
                            alpha: isDark ? 0.16 : 0.12,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: goldColor.withValues(alpha: 0.55),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'سورة $surahName',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 19,
                                color: goldColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: goldColor,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Middle: Save Page Button
                IconButton(
                  icon: Icon(
                    _isCurrentPageSaved
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: goldColor,
                    size: 28,
                  ),
                  onPressed: () => _toggleCurrentPageSave(surahName),
                  tooltip: 'حفظ الصفحة',
                ),

                // Left side (Last child in RTL): Juz
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: isDark ? 0.08 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'الجزء ${_toArabicNumbers(juzNumber)}',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      color: goldColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Decorative gold divider
          Divider(color: goldColor, thickness: 1.5),
          const SizedBox(height: 8),

          // Content Area (No vertical scrolling, takes remaining space)
          // Content Area (No vertical scrolling, takes remaining space)
          Expanded(
            child: _buildQuranBody(
              ayahs: ayahs,
              ayahsBySurah: ayahsBySurah,
              theme: theme,
              isDark: isDark,
              displaySettings: displaySettings,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageNumberSideDecoration(color: goldColor, reverse: true),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: goldColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.symmetric(
                      horizontal: BorderSide(color: goldColor, width: 1.1),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _toArabicNumbers(pageNumber),
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: goldColor,
                    ),
                  ),
                ),
                _PageNumberSideDecoration(color: goldColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuranBody({
    required List<Ayah> ayahs,
    required Map<int, List<Ayah>> ayahsBySurah,
    required ThemeData theme,
    required bool isDark,
    required QuranDisplaySettings displaySettings,
  }) {
    final pageContent = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 650),
      child: QuranPageContentWidget(
        ayahs: ayahs,
        ayahsBySurah: ayahsBySurah,
        getSurahName: _getSurahName,
        toArabicNumbers: _toArabicNumbers,
        getSavedAyahColor: (ayah) => _getSavedAyahColor(ayah, isDark),
        playingAyahId: _playingAyahId,
        highlightedAyahId: _highlightedAyahId,
        highlightedSurahId: _highlightedSurahId,
        highlightedAyahNumber: _highlightedAyahNumber,
        playAyahAudio: _playAyahAudio,
        showAyahOptions: _showAyahOptions,
        onSurahLongPress: _onSurahLongPress,
        theme: theme,
        isDark: isDark,
        quranFontFamily: _quranFontFamily(displaySettings),
        quranFontSize: displaySettings.quranFontSize,
        ayahNumberFontSize: displaySettings.ayahNumberFontSize,
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: displaySettings.scrollMode
            ? Alignment.topCenter
            : Alignment.center,
        child: pageContent,
      ),
    );
  }
}

class _QuranAyahSearchPanel extends StatefulWidget {
  final LocalQuranService quranService;
  final String Function(int) toArabicNumbers;
  final ValueChanged<QuranSearchResult> onResultSelected;

  const _QuranAyahSearchPanel({
    required this.quranService,
    required this.toArabicNumbers,
    required this.onResultSelected,
  });

  @override
  State<_QuranAyahSearchPanel> createState() => _QuranAyahSearchPanelState();
}

class _QuranAyahSearchPanelState extends State<_QuranAyahSearchPanel> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  List<QuranSearchResult> _results = const [];
  bool _isSearching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _search(value);
    });
  }

  Future<void> _search(String query) async {
    final trimmedQuery = query.trim();
    _lastQuery = trimmedQuery;

    if (trimmedQuery.length < 2) {
      if (!mounted) return;
      setState(() {
        _results = const [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await widget.quranService.searchAyahs(trimmedQuery);
    if (!mounted || _lastQuery != trimmedQuery) return;

    setState(() {
      _results = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const goldColor = Color(0xFFD4AF37);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: goldColor.withValues(alpha: 0.5)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontFamily: 'Cairo'),
          decoration: InputDecoration(
            hintText: 'ابحث عن آية',
            hintStyle: TextStyle(
              fontFamily: 'Cairo',
              color: theme.hintColor.withValues(alpha: 0.75),
            ),
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _debounceTimer?.cancel();
                      _controller.clear();
                      setState(() {
                        _results = const [];
                        _isSearching = false;
                      });
                    },
                  ),
            enabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: goldColor, width: 1.4),
            ),
            isDense: true,
          ),
          onChanged: (value) {
            setState(() {});
            _onQueryChanged(value);
          },
        ),
        if (_isSearching)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
            ),
          )
        else if (_controller.text.trim().length >= 2 && _results.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'لا توجد نتائج',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Cairo', color: theme.hintColor),
            ),
          )
        else if (_results.isNotEmpty)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              padding: const EdgeInsets.only(top: 10),
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (context, index) =>
                  Divider(height: 1, color: goldColor.withValues(alpha: 0.18)),
              itemBuilder: (context, index) {
                final result = _results[index];
                final ayah = result.ayah;
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    ayah.textUthmani,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: _quranFontFamilyForSearchPreview(),
                      fontSize: 20,
                      height: 1.45,
                    ),
                  ),
                  subtitle: Text(
                    'سورة ${result.surah.nameArabic} - آية ${widget.toArabicNumbers(ayah.ayahNumber)} - صفحة ${widget.toArabicNumbers(ayah.pageNumber)}',
                    style: const TextStyle(fontFamily: 'Cairo'),
                  ),
                  trailing: const Icon(
                    Icons.arrow_back_ios_new,
                    size: 16,
                    color: goldColor,
                  ),
                  onTap: () => widget.onResultSelected(result),
                );
              },
            ),
          ),
      ],
    );
  }

  String? _quranFontFamilyForSearchPreview() {
    return GoogleFonts.scheherazadeNew().fontFamily;
  }
}

class _PageNumberSideDecoration extends StatelessWidget {
  final Color color;
  final bool reverse;

  const _PageNumberSideDecoration({required this.color, this.reverse = false});

  @override
  Widget build(BuildContext context) {
    final children = [
      Container(
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.75),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 5),
      Transform.rotate(
        angle: 0.785398,
        child: Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            border: Border.all(color: color.withValues(alpha: 0.8), width: 1),
          ),
        ),
      ),
      const SizedBox(width: 6),
      SizedBox(
        width: 30,
        child: Divider(color: color.withValues(alpha: 0.55), thickness: 1),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: reverse ? children.reversed.toList() : children,
    );
  }
}

class QuranPageContentWidget extends StatefulWidget {
  final List<Ayah> ayahs;
  final Map<int, List<Ayah>> ayahsBySurah;
  final String Function(int) getSurahName;
  final String Function(int) toArabicNumbers;
  final Color? Function(Ayah) getSavedAyahColor;
  final int? playingAyahId;
  final int? highlightedAyahId;
  final int? highlightedSurahId;
  final int? highlightedAyahNumber;
  final void Function(BuildContext, Ayah) playAyahAudio;
  final void Function(BuildContext, Ayah) showAyahOptions;
  final void Function(BuildContext, int) onSurahLongPress;
  final ThemeData theme;
  final bool isDark;
  final String? quranFontFamily;
  final double quranFontSize;
  final double ayahNumberFontSize;

  const QuranPageContentWidget({
    super.key,
    required this.ayahs,
    required this.ayahsBySurah,
    required this.getSurahName,
    required this.toArabicNumbers,
    required this.getSavedAyahColor,
    required this.playingAyahId,
    required this.highlightedAyahId,
    required this.highlightedSurahId,
    required this.highlightedAyahNumber,
    required this.playAyahAudio,
    required this.showAyahOptions,
    required this.onSurahLongPress,
    required this.theme,
    required this.isDark,
    required this.quranFontFamily,
    required this.quranFontSize,
    required this.ayahNumberFontSize,
  });

  @override
  State<QuranPageContentWidget> createState() => _QuranPageContentWidgetState();
}

class _QuranPageContentWidgetState extends State<QuranPageContentWidget> {
  final Map<int, TapAndLongPressGestureRecognizer> _recognizers = {};
  static const Set<String> _sajdaOverlineAyahs = {
    '7:206',
    '13:15',
    '16:49',
    '17:109',
    '19:58',
    '22:18',
    '22:77',
    '25:60',
    '27:25',
    '32:15',
    '38:24',
    '41:37',
    '53:62',
    '84:21',
    '96:19',
  };

  @override
  void initState() {
    super.initState();
    _initRecognizers();
  }

  @override
  void didUpdateWidget(QuranPageContentWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ayahs != oldWidget.ayahs) {
      _disposeRecognizers();
      _initRecognizers();
    }
  }

  void _initRecognizers() {
    for (var ayah in widget.ayahs) {
      _recognizers[ayah.id] = TapAndLongPressGestureRecognizer()
        ..onLongPress = () {
          widget.showAyahOptions(context, ayah);
        };
    }
  }

  void _disposeRecognizers() {
    for (var recognizer in _recognizers.values) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  String _stripArabicMarks(String text) {
    return text
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll('\u0640', '');
  }

  bool _isSajdaCandidate(Ayah ayah, String word) {
    final clean = _stripArabicMarks(word);
    if (ayah.surahId == 17 && ayah.ayahNumber == 109) {
      return clean.contains('\u062e\u0631');
    }
    if (ayah.surahId == 38 && ayah.ayahNumber == 24) {
      return clean.contains('\u062e\u0631');
    }
    if (ayah.surahId == 41 && ayah.ayahNumber == 37) {
      return clean.contains('\u0633\u062c\u062f') &&
          !clean.contains('\u062a\u0633\u062c\u062f\u0648\u0627');
    }
    return clean.contains('\u0633\u062c\u062f');
  }

  Set<int> _sajdaWordIndexes(Ayah ayah, List<String> words) {
    final hasSajdaOverline = _sajdaOverlineAyahs.contains(
      '${ayah.surahId}:${ayah.ayahNumber}',
    );
    if (!hasSajdaOverline) return const {};

    final indexes = <int>{};
    for (var index = 0; index < words.length; index++) {
      if (_isSajdaCandidate(ayah, words[index])) {
        if (ayah.surahId == 25 && ayah.ayahNumber == 60) {
          final wordClean = _stripArabicMarks(words[index]);
          if (wordClean == '\u0623\u0646\u0633\u062c\u062f' ||
              wordClean == '\u0627\u0646\u0633\u062c\u062f' ||
              wordClean.endsWith('\u0646\u0633\u062c\u062f')) {
            continue;
          }
        }
        indexes.add(index);
      }
    }

    return indexes;
  }

  List<InlineSpan> _buildAyahTextSpans({
    required Ayah ayah,
    required TextStyle baseStyle,
    required TextStyle ayahNumberStyle,
    required GestureRecognizer? recognizer,
  }) {
    final words = ayah.textUthmani.split(' ');
    final sajdaIndexes = _sajdaWordIndexes(ayah, words);
    final spans = <InlineSpan>[];

    for (var index = 0; index < words.length; index++) {
      final word = words[index];
      if (word.isEmpty) {
        spans.add(const TextSpan(text: ' '));
        continue;
      }

      final isSajdaWord = sajdaIndexes.contains(index);
      spans.add(
        TextSpan(
          text: '$word ',
          style: isSajdaWord
              ? baseStyle.copyWith(
                  decoration: TextDecoration.overline,
                  decorationColor: baseStyle.color,
                  decorationThickness: 1.6,
                )
              : baseStyle,
          recognizer: recognizer,
        ),
      );
    }

    spans.add(
      TextSpan(
        text: '\uFD3F${widget.toArabicNumbers(ayah.ayahNumber)}\uFD3E',
        style: ayahNumberStyle,
        recognizer: recognizer,
      ),
    );
    spans.add(const TextSpan(text: ' '));

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = widget.isDark ? Colors.white : Colors.black87;
    const goldColor = Color(0xFFD4AF37);

    return Column(
      children: widget.ayahsBySurah.entries.map((entry) {
        final surahId = entry.key;
        final surahAyahs = entry.value;
        final bool isSurahStart = surahAyahs.any((a) => a.ayahNumber == 1);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSurahStart) ...[
              // Elegant Islamic Surah Header Ornament
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: InkWell(
                  onTap: () => widget.onSurahLongPress(context, surahId),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1E1E1E)
                          : const Color(0xFFFFFDF5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: goldColor.withValues(alpha: 0.85),
                        width: 1.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldColor.withValues(
                            alpha: widget.isDark ? 0.08 : 0.14,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: goldColor.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: goldColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    goldColor.withValues(alpha: 0.1),
                                    goldColor.withValues(alpha: 0.9),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Text(
                            '( سُورَةُ ${widget.getSurahName(surahId)} )',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: widget.isDark
                                  ? goldColor
                                  : const Color(0xFF1B4332),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Container(
                              height: 1.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    goldColor.withValues(alpha: 0.9),
                                    goldColor.withValues(alpha: 0.1),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: goldColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // Basmalah
              if (surahId != 9)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Center(
                    child: Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: widget.quranFontFamily,
                        fontSize: widget.quranFontSize,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
            ],

            // Ayahs Block
            RichText(
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              text: TextSpan(
                style: TextStyle(
                  height: 1.8,
                  fontFamily: widget.quranFontFamily,
                  fontSize: widget.quranFontSize,
                  color: textColor,
                ),
                children: surahAyahs.map((ayah) {
                  final isPlaying = widget.playingAyahId == ayah.id;
                  final isHighlighted =
                      widget.highlightedAyahId == ayah.id ||
                      (widget.highlightedSurahId == ayah.surahId &&
                          widget.highlightedAyahNumber == ayah.ayahNumber);
                  final savedColor = widget.getSavedAyahColor(ayah);
                  final isSaved = savedColor != null;
                  final recognizer = _recognizers[ayah.id];
                  final ayahBackgroundColor = isPlaying
                      ? widget.theme.primaryColor.withValues(alpha: 0.2)
                      : isHighlighted
                      ? goldColor.withValues(alpha: 0.16)
                      : Colors.transparent;
                  final ayahTextStyle = TextStyle(
                    backgroundColor: ayahBackgroundColor,
                    color: isPlaying
                        ? widget.theme.primaryColor
                        : (savedColor ?? textColor),
                  );
                  final ayahNumberStyle = TextStyle(
                    color: isSaved ? savedColor : goldColor,
                    backgroundColor: ayahBackgroundColor,
                    fontFamily: widget.quranFontFamily,
                    fontSize: widget.ayahNumberFontSize * 1.04,
                    fontWeight: FontWeight.w900,
                  );

                  return TextSpan(
                    children: _buildAyahTextSpans(
                      ayah: ayah,
                      baseStyle: ayahTextStyle,
                      ayahNumberStyle: ayahNumberStyle,
                      recognizer: recognizer,
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

class TapAndLongPressGestureRecognizer extends TapGestureRecognizer {
  VoidCallback? onLongPress;
  Timer? _longPressTimer;
  bool _isLongPress = false;

  TapAndLongPressGestureRecognizer({super.debugOwner}) {
    onTapDown = (details) {
      _isLongPress = false;
      _longPressTimer?.cancel();
      _longPressTimer = Timer(const Duration(milliseconds: 500), () {
        _isLongPress = true;
        if (onLongPress != null) {
          onLongPress!();
        }
      });
    };
    onTapCancel = () {
      _longPressTimer?.cancel();
    };
  }

  GestureTapCallback? _customOnTap;

  @override
  GestureTapCallback? get onTap => _customOnTap;

  @override
  set onTap(GestureTapCallback? value) {
    _customOnTap = value;
    super.onTap = () {
      _longPressTimer?.cancel();
      if (!_isLongPress && _customOnTap != null) {
        _customOnTap!();
      }
    };
  }

  @override
  void dispose() {
    _longPressTimer?.cancel();
    super.dispose();
  }
}

class SavedAyahColor {
  final String id;
  final String nameArabic;
  final Color lightColor;
  final Color darkColor;

  const SavedAyahColor({
    required this.id,
    required this.nameArabic,
    required this.lightColor,
    required this.darkColor,
  });
}

const List<SavedAyahColor> kSavedAyahColors = [
  SavedAyahColor(
    id: 'green',
    nameArabic: 'أخضر',
    lightColor: Color(0xFF2E7D32),
    darkColor: Color(0xFF4AAF57),
  ),
  SavedAyahColor(
    id: 'blue',
    nameArabic: 'أزرق',
    lightColor: Color(0xFF1565C0),
    darkColor: Color(0xFF29B6F6),
  ),
  SavedAyahColor(
    id: 'red',
    nameArabic: 'أحمر',
    lightColor: Color(0xFFC62828),
    darkColor: Color(0xFFEF5350),
  ),
  SavedAyahColor(
    id: 'orange',
    nameArabic: 'برتقالي',
    lightColor: Color(0xFFEF6C00),
    darkColor: Color(0xFFFF9800),
  ),
  SavedAyahColor(
    id: 'purple',
    nameArabic: 'بنفسجي',
    lightColor: Color(0xFF6A1B9A),
    darkColor: Color(0xFFAB47BC),
  ),
];
