import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/tafsir_service.dart';
import '../../services/widget_sync_service.dart';
import 'surah_list_screen.dart';

class MushafScreen extends StatefulWidget {
  final int initialPage;
  const MushafScreen({super.key, this.initialPage = 1});

  @override
  State<MushafScreen> createState() => _MushafScreenState();
}

class _MushafScreenState extends State<MushafScreen> {
  final TafsirService _tafsirService = TafsirService();
  late PageController _pageController;
  int _currentPage = 1;
  bool _isOverlayVisible = true;

  List<Map<String, dynamic>> _savedAyahs = [];

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _pageController = PageController(initialPage: _currentPage - 1);
    _loadSavedAyahs();
  }

  Future<void> _loadSavedAyahs() async {
    final prefs = await SharedPreferences.getInstance();
    final ayahsJson = prefs.getStringList('saved_ayahs') ?? [];
    if (mounted) {
      setState(() {
        _savedAyahs = ayahsJson.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _saveBookmark(int page) async {
    final prefs = await SharedPreferences.getInstance();
    final pageData = quran.getPageData(page);
    String surahName = '';
    if (pageData.isNotEmpty) {
      surahName = quran.getSurahNameArabic(pageData.first['surah'] as int);
    }

    final pagesJson = prefs.getStringList('saved_pages') ?? [];
    List<Map<String, dynamic>> savedPages = pagesJson.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    
    // Check if already exists
    if (!savedPages.any((e) => e['page'] == page)) {
      savedPages.add({'page': page, 'surahName': surahName});
      await prefs.setStringList('saved_pages', savedPages.map((e) => jsonEncode(e)).toList());
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم حفظ الصفحة $page كعلامة مرجعية'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Future<void> _saveAyah(int surah, int ayah, int page) async {
    final prefs = await SharedPreferences.getInstance();
    final ayahsJson = prefs.getStringList('saved_ayahs') ?? [];
    List<Map<String, dynamic>> savedAyahs = ayahsJson.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();
    
    final text = quran.getVerse(surah, ayah, verseEndSymbol: false);
    String? tafsir;
    try {
      tafsir = await _tafsirService.getTafsir(
        surahId: surah,
        ayahNumber: ayah,
      );
    } catch (_) {
      // Saving the verse should still work if the explanation is unavailable.
    }
    
    // Check if already exists
    if (!savedAyahs.any((e) => e['surah'] == surah && e['ayah'] == ayah)) {
      savedAyahs.add({
        'surah': surah,
        'ayah': ayah,
        'text': text,
        'page': page,
        if (tafsir != null && tafsir.isNotEmpty) 'tafsir': tafsir,
      });
      await prefs.setStringList('saved_ayahs', savedAyahs.map((e) => jsonEncode(e)).toList());
      await WidgetSyncService.refresh();
      setState(() {
        _savedAyahs = savedAyahs;
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('تم حفظ الآية في المحفوظات'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showAyahDialog(int surah, int ayah, int page) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('خيارات الآية', textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
          content: Text(
            'سورة ${quran.getSurahNameArabic(surah)} - آية $ayah',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontFamily: 'Amiri'),
          ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _saveAyah(surah, ayah, page);
              },
              child: const Text('حفظ هذه الآية'),
            ),
          ],
        );
      },
    );
  }

  void _toggleOverlay() {
    setState(() {
      _isOverlayVisible = !_isOverlayVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // الألوان المستوحاة من المصحف
    final pageColor = isDark ? Colors.black : const Color(0xFFFDF6E3); // لون كريمي فاتح للمصحف في الوضع الفاتح
    final textColor = isDark ? Colors.white : Colors.black87;
    final frameColor = isDark ? theme.primaryColor : const Color(0xFF8B0000); // إطار ذهبي للداكن، وعنابي للفاتح

    return Scaffold(
      backgroundColor: pageColor,
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: _toggleOverlay,
              child: PageView.builder(
                controller: _pageController,
                itemCount: 604,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index + 1;
                  });
                },
                // المستخدم طلب أن يكون التقليب من الشمال لليمين
                reverse: false,
                itemBuilder: (context, index) {
                  int pageNumber = index + 1;
                  return _buildPage(pageNumber, theme, textColor, frameColor, isDark);
                },
              ),
            ),
            
            // شريط علوي يظهر ويختفي
            if (_isOverlayVisible)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'مصحف التلاوة',
                        style: theme.textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.list),
                            onPressed: () async {
                              final selectedPage = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SurahListScreen(),
                                ),
                              );
                              if (selectedPage != null && selectedPage is int) {
                                _pageController.jumpToPage(selectedPage - 1);
                                setState(() {
                                  _currentPage = selectedPage;
                                });
                              }
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.bookmark_add),
                            onPressed: () => _saveBookmark(_currentPage),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int pageNumber, ThemeData theme, Color textColor, Color frameColor, bool isDark) {
    final pageData = quran.getPageData(pageNumber);
    if (pageData.isEmpty) return const SizedBox();

    int mainSurah = pageData.first['surah'] as int;
    int juz = quran.getJuzNumber(mainSurah, pageData.first['start'] as int);

    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: frameColor, width: 2),
      ),
      child: Column(
        children: [
          // Header (Surah Name and Juz)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: frameColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'سورة ${quran.getSurahNameArabic(mainSurah)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    color: frameColor,
                  ),
                ),
                Text(
                  'الجزء ${_toArabicNumbers(juz)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    color: frameColor,
                  ),
                ),
              ],
            ),
          ),
          
          // Body (Ayahs) - Full width, auto scaling
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 2.0),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calculate font size to fill the full width of the phone
                    double widthBasedSize = constraints.maxWidth / 14.5; 
                    // Calculate based on the full height of the phone
                    double heightBasedSize = constraints.maxHeight / 25.0;
                    double fontSize = widthBasedSize < heightBasedSize ? widthBasedSize : heightBasedSize;
                    
                    // Increase line height to avoid overlapping diacritics
                    double lineHeight = 1.9; 
                    
                    return FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: constraints.maxWidth - 4.0,
                        child: RichText(
                          textAlign: TextAlign.center, 
                          textWidthBasis: TextWidthBasis.parent,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            style: theme.textTheme.titleLarge?.copyWith(
                              height: lineHeight,
                              fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                              fontSize: fontSize,
                              color: textColor,
                            ),
                            children: _buildPageTextSpans(pageData, theme, frameColor, textColor, pageNumber, constraints.maxWidth, fontSize),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Footer (Page Number and Navigation)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: frameColor, width: 1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: pageNumber > 1
                      ? () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back_ios, size: 16),
                  label: const Text('السابقة', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: frameColor),
                ),
                Text(
                  _toArabicNumbers(pageNumber),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: frameColor,
                    fontFamily: 'Amiri',
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: pageNumber < 604
                      ? () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text('التالية', style: TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
                  style: TextButton.styleFrom(foregroundColor: frameColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildPageTextSpans(List<dynamic> pageData, ThemeData theme, Color frameColor, Color textColor, int pageNumber, double maxWidth, double fontSize) {
    List<InlineSpan> spans = [];

    for (int i = 0; i < pageData.length; i++) {
      Map<String, dynamic> data = Map<String, dynamic>.from(pageData[i] as Map);
      int surah = data['surah'] as int;
      int startAyah = data['start'] as int;
      int endAyah = data['end'] as int;

      // If this is the beginning of a Surah (and not Fatihah or Tawbah), show Header and Basmalah
      if (startAyah == 1) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: maxWidth,
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark ? Colors.black : const Color(0xFFFAF1E3),
                border: Border.all(color: frameColor, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(Icons.flare, color: frameColor, size: 20),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Icon(Icons.flare, color: frameColor, size: 20),
                      ),
                    ],
                  ),
                  Text(
                    'سُورَةُ ${quran.getSurahNameArabic(surah)}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                      fontWeight: FontWeight.bold,
                      color: frameColor,
                      fontSize: fontSize * 0.9, 
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        if (surah != 9) {
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Container(
                width: maxWidth,
                padding: const EdgeInsets.only(bottom: 8.0, top: 2.0),
                alignment: Alignment.center,
                child: Text(
                  quran.basmala,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                    fontSize: fontSize * 0.85,
                    color: textColor,
                  ),
                ),
              ),
            ),
          );
        }
      }


      for (int ayah = startAyah; ayah <= endAyah; ayah++) {
        // Skip ayah 1 of Surah 1 because it's already rendered as the Basmalah header
        if (surah == 1 && ayah == 1) continue;

        // For Surah 1, shift the displayed verse number by -1
        int displayAyahNumber = ayah;
        if (surah == 1) {
          displayAyahNumber = ayah - 1;
        }

        bool isSaved = _savedAyahs.any((e) => e['surah'] == surah && e['ayah'] == ayah);
        
        spans.add(
          TextSpan(
            text: '${quran.getVerse(surah, ayah, verseEndSymbol: false)} ',
            style: TextStyle(
              backgroundColor: isSaved ? theme.primaryColor.withValues(alpha: 0.2) : null,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _showAyahDialog(surah, ayah, pageNumber),
          ),
        );
        spans.add(
          TextSpan(
            text: '${quran.getVerseEndSymbol(displayAyahNumber, arabicNumeral: true)}',
            style: TextStyle(
              color: theme.primaryColor, // Golden verse marker
              fontFamily: GoogleFonts.scheherazadeNew().fontFamily, // End symbol looks better with Amiri usually, or default
              fontSize: 22,
              backgroundColor: isSaved ? theme.primaryColor.withValues(alpha: 0.2) : null,
            ),
            recognizer: TapGestureRecognizer()..onTap = () => _showAyahDialog(surah, ayah, pageNumber),
          ),
        );
        
        if (isSaved) {
          spans.add(
            const TextSpan(
              text: ' 🧡 ',
              style: TextStyle(fontSize: 16),
            ),
          );
        } else {
          spans.add(const TextSpan(text: ' '));
        }
      }
    }

    return spans;
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
}
