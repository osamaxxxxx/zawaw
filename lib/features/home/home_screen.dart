import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../adhkar/adhkar_screen.dart';
import '../prayer/prayer_times_screen.dart';
import '../quran/quran_reader_screen.dart';
import '../bookmarks/bookmarks_screen.dart';
import '../downloads/downloads_screen.dart';
import '../feedback/feedback_screen.dart';
import '../shorts/shorts_categories_screen.dart';
import 'daily_content_screen.dart';
import 'khatm_dua_screen.dart';
import 'ramadan_playlist_screen.dart';
import '../settings/settings_screen.dart';

class HomeSectionItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const HomeSectionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Adhan Countdown Properties
  Timer? _countdownTimer;
  List<PrayerTime> _prayers = [];
  // Ticks every second; only the time-dependent cards listen to it so the
  // rest of the home page is not rebuilt each second.
  final ValueNotifier<DateTime> _clock = ValueNotifier<DateTime>(
    DateTime.now(),
  );
  DateTime get _now => _clock.value;
  int _lastReadPage = 1;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

  // All available sections for customization
  static const List<HomeSectionItem> _allSections = [
    HomeSectionItem(
      id: 'prayer_countdown',
      title: 'مواقيت الصلاة والعد التنازلي',
      subtitle: 'الوقت المتبقي للأذان والصلاة القادمة',
      icon: Icons.notifications_active_rounded,
      color: primaryGold,
    ),
    HomeSectionItem(
      id: 'smart_adhkar',
      title: 'التذكير الذكي بالأذكار',
      subtitle: 'أذكار الصباح والمساء والنوم حسب الوقت الحاضر',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFF1FB6FF),
    ),
    HomeSectionItem(
      id: 'quran_hero',
      title: 'المصحف الشريف ومتابعة القراءة',
      subtitle: 'متابعة التلاوة والصفحة الأخيرة',
      icon: Icons.menu_book_rounded,
      color: primaryGold,
    ),
    HomeSectionItem(
      id: 'adhkar_grid',
      title: 'قسم الأذكار والأدعية',
      subtitle: 'حصن المسلم وأدعية اليوم والليلة',
      icon: Icons.auto_awesome_rounded,
      color: Colors.teal,
    ),
    HomeSectionItem(
      id: 'bookmarks_grid',
      title: 'المحفوظات والعلامات',
      subtitle: 'الصفحات والآيات المحفوظة',
      icon: Icons.bookmarks_rounded,
      color: Colors.amber,
    ),
    HomeSectionItem(
      id: 'daily_ayah_grid',
      title: 'آية وتفسير اليوم',
      subtitle: 'آية كريمة مع تفسيرها الميسر',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF2E7D32),
    ),
    HomeSectionItem(
      id: 'daily_hadith_grid',
      title: 'حديث اليوم النبوي',
      subtitle: 'حديث شريف مع شرحه وبيان معناه',
      icon: Icons.format_quote_rounded,
      color: Color(0xFF765D2A),
    ),
    HomeSectionItem(
      id: 'shorts_grid',
      title: 'شورتس إسلامية',
      subtitle: 'فيديوهات قصيرة ومفيدة',
      icon: Icons.play_circle_outline,
      color: Colors.pink,
    ),
    HomeSectionItem(
      id: 'ramadan_grid',
      title: 'رمضان 2026',
      subtitle: 'تلاوات ليالي رمضان والختمات',
      icon: Icons.nightlight_round,
      color: Colors.indigo,
    ),
    HomeSectionItem(
      id: 'prayer_times_grid',
      title: 'مواقيت الصلوات اليومية',
      subtitle: 'مواقيت الأذان وإمساكية الشهر',
      icon: Icons.access_time_filled_rounded,
      color: Colors.orange,
    ),
    HomeSectionItem(
      id: 'khatm_dua_grid',
      title: 'دعاء ختم المصحف',
      subtitle: 'دعاء الختم المبارك بصوت الشيخ',
      icon: Icons.volunteer_activism_rounded,
      color: Colors.deepPurple,
    ),
    HomeSectionItem(
      id: 'downloads_grid',
      title: 'التنزيلات والمكتبة الصوتية',
      subtitle: 'التلاوات المحملة للاستماع بدون إنترنت',
      icon: Icons.download_for_offline_rounded,
      color: Colors.blue,
    ),
    HomeSectionItem(
      id: 'feedback_card',
      title: 'شاركنا رأيك ومقترحاتك',
      subtitle: 'نسعد بملاحظاتكم لتطوير التطبيق',
      icon: Icons.rate_review_outlined,
      color: Colors.blueGrey,
    ),
  ];

  List<String> _sectionOrder = _allSections.map((s) => s.id).toList();
  Map<String, bool> _sectionVisibility = {
    for (var s in _allSections) s.id: true,
  };

  @override
  void initState() {
    super.initState();
    _loadCustomizationSettings();
    _loadPrayerTimesForCountdown();
    _loadLastReadPage();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _clock.value = DateTime.now();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  Future<void> _loadCustomizationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedOrder = prefs.getStringList('home_section_order_v2');
    final savedVisibilityJson = prefs.getString('home_section_visibility_v2');

    if (mounted) {
      setState(() {
        if (savedOrder != null && savedOrder.isNotEmpty) {
          // Ensure all known sections exist even if newly added
          final completeOrder = List<String>.from(savedOrder);
          for (final section in _allSections) {
            if (!completeOrder.contains(section.id)) {
              completeOrder.add(section.id);
            }
          }
          _sectionOrder = completeOrder;
        }

        if (savedVisibilityJson != null) {
          try {
            final Map<String, dynamic> decoded = jsonDecode(
              savedVisibilityJson,
            );
            for (final section in _allSections) {
              if (decoded.containsKey(section.id)) {
                _sectionVisibility[section.id] = decoded[section.id] == true;
              }
            }
          } catch (_) {}
        }
      });
    }
  }

  Future<void> _saveCustomizationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('home_section_order_v2', _sectionOrder);
    await prefs.setString(
      'home_section_visibility_v2',
      jsonEncode(_sectionVisibility),
    );
  }

  Future<void> _resetCustomizationToDefault() async {
    setState(() {
      _sectionOrder = _allSections.map((s) => s.id).toList();
      _sectionVisibility = {for (var s in _allSections) s.id: true};
    });
    await _saveCustomizationSettings();
  }

  Future<void> _loadLastReadPage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _lastReadPage = (prefs.getInt('last_read_page') ?? 1).clamp(1, 604);
      });
    }
  }

  Future<void> _loadPrayerTimesForCountdown() async {
    final prefs = await SharedPreferences.getInstance();
    final location = UserLocation.fromPrefs(prefs) ?? UserLocation.cairo;

    if (mounted) {
      setState(() {
        _prayers = PrayerTimeCalculator.calculate(
          date: DateTime.now(),
          latitude: location.latitude,
          longitude: location.longitude,
          timezoneOffsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
          countryCode: location.countryCode,
        );
      });
    }
  }

  PrayerTime? _nextPrayer() {
    if (_prayers.isEmpty) return null;
    PrayerTime? next;
    DateTime? nextTime;
    for (final prayer in _prayers) {
      final occurrence = _nextOccurrence(prayer);
      if (nextTime == null || occurrence.isBefore(nextTime)) {
        next = prayer;
        nextTime = occurrence;
      }
    }
    return next;
  }

  DateTime _nextOccurrence(PrayerTime prayer) {
    if (prayer.time.isAfter(_now)) return prayer.time;
    return prayer.time.add(const Duration(days: 1));
  }

  String _formatRemaining(Duration duration) {
    final safeDuration = duration.isNegative ? Duration.zero : duration;
    final hours = safeDuration.inHours.toString().padLeft(2, '0');
    final minutes = safeDuration.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = safeDuration.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$hours:$minutes:$seconds';
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

  // MARK: - Smart Adhkar Time Detection
  Map<String, dynamic> _getCurrentSmartAdhkarInfo() {
    final hour = _now.hour;
    if (hour >= 5 && hour < 12) {
      return {
        'title': 'حان وقت أذكار الصباح ☀️',
        'subtitle':
            'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ..',
        'categoryIndex': 0,
        'icon': Icons.wb_sunny_rounded,
        'color': const Color(0xFF1FB6FF),
        'gradient': const [Color(0xFF0F3B57), Color(0xFF092030)],
      };
    } else if (hour >= 15 && hour < 21) {
      return {
        'title': 'حان وقت أذكار المساء 🌙',
        'subtitle':
            'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ..',
        'categoryIndex': 1,
        'icon': Icons.nights_stay_rounded,
        'color': const Color(0xFFCE93D8),
        'gradient': const [Color(0xFF3F1D4F), Color(0xFF230D2E)],
      };
    } else if (hour >= 21 || hour < 5) {
      return {
        'title': 'أذكار النوم والمساء ⭐',
        'subtitle': 'بِاسْمِكَ رَبِّي وَضَعْتُ جَنْبِي وَبِكَ أَرْفَعُهُ..',
        'categoryIndex': 2,
        'icon': Icons.bedtime_rounded,
        'color': const Color(0xFFB39DDB),
        'gradient': const [Color(0xFF281845), Color(0xFF130926)],
      };
    } else {
      return {
        'title': 'أذكار بعد الصلاة والتسبيح 📿',
        'subtitle':
            'اللَّهُمَّ أَنْتَ السَّلَامُ وَمِنْكَ السَّلَامُ، تَبَارَكْتَ..',
        'categoryIndex': 3,
        'icon': Icons.mosque_rounded,
        'color': const Color(0xFF81C784),
        'gradient': const [Color(0xFF143B25), Color(0xFF091F13)],
      };
    }
  }

  // MARK: - Smart Adhkar Card
  Widget _buildSmartAdhkarCard(BuildContext context) {
    final info = _getCurrentSmartAdhkarInfo();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = info['color'] as Color;
    final gradient = info['gradient'] as List<Color>;
    final categoryIndex = info['categoryIndex'] as int;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? gradient
              : [gradient[0].withValues(alpha: 0.95), gradient[1]],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isDark ? 0.15 : 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AdhkarReaderScreen(
                  category: AdhkarData.categories[categoryIndex],
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 14.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.5)),
                  ),
                  child: Icon(info['icon'] as IconData, color: color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        info['title'] as String,
                        style: GoogleFonts.cairo(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        info['subtitle'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: color.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'قراءة',
                        style: GoogleFonts.cairo(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: color,
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
  }

  // MARK: - Prayer Countdown Card
  Widget _buildPrayerCountdownCard(BuildContext context) {
    final next = _nextPrayer();
    if (next == null) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final occurrence = _nextOccurrence(next);
    final remaining = occurrence.difference(_now);
    final formattedTime = _formatRemaining(remaining);

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF142F24), const Color(0xFF0F1E17)]
              : [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryGold.withValues(alpha: isDark ? 0.12 : 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.45),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrayerTimesScreen(),
              ),
            ).then((_) {
              _loadPrayerTimesForCountdown();
            });
          },
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGold.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: primaryGold,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'الصلاة القادمة: صلاة ${next.name}',
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryGold,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: primaryGold,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'الوقت المتبقي للأذان',
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        formattedTime,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryGold,
                          letterSpacing: 2,
                        ),
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
  }

  // MARK: - Quran Hero Card
  Widget _buildQuranHeroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF222222), const Color(0xFF191919)]
              : [const Color(0xFFFFFFFF), const Color(0xFFFAF7F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: primaryGold.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const QuranReaderScreen(),
              ),
            ).then((_) {
              _loadLastReadPage();
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: primaryGold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: primaryGold.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: primaryGold,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المصحف الشريف',
                        style: GoogleFonts.cairo(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : darkGreen,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            size: 14,
                            color: primaryGold,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'متابعة القراءة من صفحة ${_toArabicNumbers(_lastReadPage)}',
                            style: GoogleFonts.cairo(
                              fontSize: 12.5,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryGold.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 15,
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

  // MARK: - Individual Category Card
  Widget _buildCategoryCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : primaryGold.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: isDark ? Colors.grey[700] : Colors.grey[400],
                      size: 13,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : darkGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Feedback Wide Card
  Widget _buildWideFeedbackCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : primaryGold.withValues(alpha: 0.2),
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
          borderRadius: BorderRadius.circular(18),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FeedbackScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.rate_review_outlined,
                    color: Colors.blueGrey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'شاركنا رأيك ومقترحاتك',
                        style: GoogleFonts.cairo(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : darkGreen,
                        ),
                      ),
                      Text(
                        'نسعد بملاحظاتكم لتطوير التطبيق باستمرار',
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
                  color: isDark ? Colors.grey[700] : Colors.grey[400],
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // MARK: - Section Customization Modal
  void _showCustomizeHomeScreenDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.82,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle & Header
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 8),
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryGold.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.dashboard_customize_rounded,
                              color: primaryGold,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تخصيص وترتيب الواجهة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : darkGreen,
                                  ),
                                ),
                                Text(
                                  'اسحب لإعادة الترتيب أو اضغط لإخفاء/إظهار أي بطاقة',
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _resetCustomizationToDefault();
                              setModalState(() {});
                              setState(() {});
                            },
                            icon: const Icon(
                              Icons.refresh_rounded,
                              size: 16,
                              color: primaryGold,
                            ),
                            label: Text(
                              'استعادة',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // Reorderable list
                    Expanded(
                      child: ReorderableListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        itemCount: _sectionOrder.length,
                        onReorder: (oldIndex, newIndex) {
                          if (newIndex > oldIndex) newIndex -= 1;
                          setModalState(() {
                            final item = _sectionOrder.removeAt(oldIndex);
                            _sectionOrder.insert(newIndex, item);
                          });
                          setState(() {});
                          _saveCustomizationSettings();
                        },
                        itemBuilder: (context, index) {
                          final sectionId = _sectionOrder[index];
                          final section = _allSections.firstWhere(
                            (s) => s.id == sectionId,
                            orElse: () => _allSections.first,
                          );
                          final isVisible =
                              _sectionVisibility[sectionId] ?? true;

                          return Container(
                            key: ValueKey(sectionId),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? (isVisible
                                        ? const Color(0xFF242424)
                                        : const Color(0xFF1B1B1B))
                                  : (isVisible
                                        ? Colors.grey.shade50
                                        : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isVisible
                                    ? primaryGold.withValues(alpha: 0.3)
                                    : Colors.transparent,
                              ),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: section.color.withValues(
                                    alpha: isVisible ? 0.15 : 0.05,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  section.icon,
                                  color: isVisible
                                      ? section.color
                                      : Colors.grey,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                section.title,
                                style: GoogleFonts.cairo(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isVisible
                                      ? (isDark ? Colors.white : Colors.black87)
                                      : Colors.grey,
                                ),
                              ),
                              subtitle: Text(
                                section.subtitle,
                                style: GoogleFonts.cairo(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch.adaptive(
                                    value: isVisible,
                                    activeColor: primaryGold,
                                    onChanged: (val) {
                                      setModalState(() {
                                        _sectionVisibility[sectionId] = val;
                                      });
                                      setState(() {});
                                      _saveCustomizationSettings();
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(
                                      Icons.drag_handle_rounded,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.pop(modalContext),
                          style: FilledButton.styleFrom(
                            backgroundColor: primaryGold,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'تم والحفظ',
                            style: GoogleFonts.cairo(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // MARK: - Section Rendering Router
  Widget _buildSectionById(BuildContext context, String id) {
    if (!(_sectionVisibility[id] ?? true)) return const SizedBox.shrink();

    switch (id) {
      case 'prayer_countdown':
        return ValueListenableBuilder<DateTime>(
          valueListenable: _clock,
          builder: (context, _, _) => _buildPrayerCountdownCard(context),
        );
      case 'smart_adhkar':
        return ValueListenableBuilder<DateTime>(
          valueListenable: _clock,
          builder: (context, _, _) => _buildSmartAdhkarCard(context),
        );
      case 'quran_hero':
        return _buildQuranHeroCard(context);
      case 'adhkar_grid':
        return _buildCategoryCard(
          context,
          title: 'الأذكار والأدعية',
          subtitle: 'حصن المسلم وأذكار اليوم والليلة',
          icon: Icons.auto_awesome_rounded,
          color: Colors.teal,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdhkarScreen()),
          ),
        );
      case 'bookmarks_grid':
        return _buildCategoryCard(
          context,
          title: 'المحفوظات',
          subtitle: 'الصفحات والعلامات المرجعية',
          icon: Icons.bookmarks_rounded,
          color: Colors.amber.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const BookmarksScreen()),
          ).then((_) => _loadLastReadPage()),
        );
      case 'daily_ayah_grid':
        return _buildCategoryCard(
          context,
          title: 'آية وتفسير اليوم',
          subtitle: 'آية عشوائية وتفسيرها الميسر',
          icon: Icons.menu_book_outlined,
          color: const Color(0xFF2E7D32),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DailyContentScreen(type: DailyContentType.ayah),
            ),
          ),
        );
      case 'daily_hadith_grid':
        return _buildCategoryCard(
          context,
          title: 'حديث اليوم',
          subtitle: 'حديث نبوي شريف مع شرحه',
          icon: Icons.format_quote_rounded,
          color: const Color(0xFF765D2A),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const DailyContentScreen(type: DailyContentType.hadith),
            ),
          ),
        );
      case 'shorts_grid':
        return _buildCategoryCard(
          context,
          title: 'شورتس إسلامية',
          subtitle: 'فيديوهات قصيرة ومفيدة',
          icon: Icons.play_circle_outline,
          color: Colors.pink,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ShortsCategoriesScreen()),
          ),
        );
      case 'ramadan_grid':
        return _buildCategoryCard(
          context,
          title: 'رمضان 2026',
          subtitle: 'تلاوات ليالي رمضان والختمات',
          icon: Icons.nightlight_round,
          color: Colors.indigo,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RamadanPlaylistScreen()),
          ),
        );
      case 'prayer_times_grid':
        return _buildCategoryCard(
          context,
          title: 'مواقيت الصلاة',
          subtitle: 'مواقيت الأذان والصلوات اليومية',
          icon: Icons.access_time_filled_rounded,
          color: Colors.orange.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrayerTimesScreen()),
          ).then((_) => _loadPrayerTimesForCountdown()),
        );
      case 'khatm_dua_grid':
        return _buildCategoryCard(
          context,
          title: 'دعاء ختم المصحف',
          subtitle: 'دعاء الختم المبارك بصوت الشيخ',
          icon: Icons.volunteer_activism_rounded,
          color: Colors.deepPurple,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KhatmDuaScreen()),
          ),
        );
      case 'downloads_grid':
        return _buildCategoryCard(
          context,
          title: 'التنزيلات',
          subtitle: 'التلاوات المحملة للاستماع بدون نت',
          icon: Icons.download_for_offline_rounded,
          color: Colors.blue.shade700,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DownloadsScreen()),
          ),
        );
      case 'feedback_card':
        return _buildWideFeedbackCard(context);
      default:
        return const SizedBox.shrink();
    }
  }

  /// Lets people rearrange the home page without entering the customization
  /// sheet. A long press is used so a normal tap still opens the card.
  Widget _buildMovableSection(BuildContext context, String sectionId) {
    final isGridCard = _isGridCard(sectionId);

    void swapWith(String otherSectionId) {
      if (otherSectionId == sectionId) return;
      final sourceIndex = _sectionOrder.indexOf(otherSectionId);
      final destinationIndex = _sectionOrder.indexOf(sectionId);
      if (sourceIndex < 0 || destinationIndex < 0) return;

      setState(() {
        _sectionOrder[sourceIndex] = sectionId;
        _sectionOrder[destinationIndex] = otherSectionId;
      });
      unawaited(_saveCustomizationSettings());
    }

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => details.data != sectionId,
      onAcceptWithDetails: (details) => swapWith(details.data),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: isDropTarget ? 0.96 : 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: isDropTarget
                  ? Border.all(color: primaryGold, width: 2)
                  : null,
            ),
            child: LongPressDraggable<String>(
              data: sectionId,
              delay: const Duration(milliseconds: 350),
              feedback: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width:
                      MediaQuery.sizeOf(context).width *
                      (isGridCard ? 0.43 : 0.9),
                  child: Opacity(
                    opacity: 0.92,
                    child: _buildSectionById(context, sectionId),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.32,
                child: _buildSectionById(context, sectionId),
              ),
              child: _buildSectionById(context, sectionId),
            ),
          ),
        );
      },
    );
  }

  bool _isGridCard(String id) {
    return id.endsWith('_grid');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Group adjacent grid cards into pairs of 2 so they render beautifully
    final List<Widget> renderedWidgets = [];
    int i = 0;
    while (i < _sectionOrder.length) {
      final sectionId = _sectionOrder[i];
      final isVisible = _sectionVisibility[sectionId] ?? true;

      if (!isVisible) {
        i++;
        continue;
      }

      if (_isGridCard(sectionId)) {
        // Collect consecutive visible grid cards
        final List<String> gridGroup = [sectionId];
        int j = i + 1;
        while (j < _sectionOrder.length &&
            _isGridCard(_sectionOrder[j]) &&
            (_sectionVisibility[_sectionOrder[j]] ?? true)) {
          gridGroup.add(_sectionOrder[j]);
          j++;
        }

        // Render gridGroup in pairs
        renderedWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: gridGroup.length,
              itemBuilder: (context, idx) =>
                  _buildMovableSection(context, gridGroup[idx]),
            ),
          ),
        );

        i = j;
      } else {
        renderedWidgets.add(_buildMovableSection(context, sectionId));
        i++;
      }
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : const Color(0xFFFBF8F1),
        appBar: AppBar(
          toolbarHeight: 68.0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'تلاوات الشيخ عبدالرحمن الزواوي',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? primaryGold : darkGreen,
                ),
              ),
              Text(
                'المصحف المرتل والأذكار والمواقيت',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: 'تخصيص الواجهة',
              icon: const Icon(
                Icons.dashboard_customize_outlined,
                color: primaryGold,
              ),
              onPressed: _showCustomizeHomeScreenDialog,
            ),
            IconButton(
              tooltip: 'التنزيلات',
              icon: const Icon(Icons.download_for_offline_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DownloadsScreen()),
              ),
            ),
            IconButton(
              tooltip: 'الإعدادات',
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [...renderedWidgets, const SizedBox(height: 16)],
        ),
      ),
    );
  }
}
