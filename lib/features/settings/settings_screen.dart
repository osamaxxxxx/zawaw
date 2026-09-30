import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/settings/quran_display_settings.dart';
import '../../core/theme/theme_provider.dart';
import '../onboarding/onboarding_screen.dart';
import '../feedback/feedback_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'إعدادات التطبيق',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: isDark ? primaryGold : darkGreen,
            ),
          ),
          centerTitle: true,
        ),
        body: Consumer<QuranDisplaySettings>(
          builder: (context, quranSettings, child) {
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Theme Section
                _buildSectionHeader('المظهر والسمة', Icons.palette_outlined, isDark),
                Container(
                  decoration: _cardBoxDecoration(isDark),
                  child: Consumer<ThemeProvider>(
                    builder: (context, themeProvider, child) {
                      final isDarkMode =
                          themeProvider.themeMode == ThemeMode.dark ||
                          (themeProvider.themeMode == ThemeMode.system &&
                              MediaQuery.of(context).platformBrightness ==
                                  Brightness.dark);

                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        title: Text(
                          'المظهر الداكن (Dark Mode)',
                          style: GoogleFonts.cairo(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF222222),
                          ),
                        ),
                        subtitle: Text(
                          isDarkMode ? 'مفعل لقراءة مريحة للعين ليلًا' : 'المظهر الفاتح الطبيعي',
                          style: GoogleFonts.cairo(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                            color: primaryGold,
                            size: 22,
                          ),
                        ),
                        activeThumbColor: primaryGold,
                        value: isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme(value);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Quran Display Section
                _buildSectionHeader('خط وتنسيق المصحف الشريف', Icons.menu_book_rounded, isDark),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: _cardBoxDecoration(isDark),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Live Verse Preview Box
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF161616) : const Color(0xFFFAF7EE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: primaryGold.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          children: [
                            Text(
                              'معاينة الخط الحيّة',
                              style: GoogleFonts.cairo(
                                fontSize: 11.5,
                                color: primaryGold,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '( وَإِذَا قُرِئَ ٱلْقُرْءَانُ فَٱسْتَمِعُوا۟ لَهُۥ وَأَنصِتُوا۟ لَعَلَّكُمْ تُرْحَمُونَ )',
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                              style: TextStyle(
                                fontFamily: _quranFontFamilyForId(quranSettings.fontFamilyId),
                                fontSize: (22.0 * quranSettings.fontScale).clamp(16.0, 36.0),
                                height: 1.8,
                                color: isDark ? Colors.white : const Color(0xFF1B4332),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Font Size Slider
                      Row(
                        children: [
                          const Icon(Icons.format_size_rounded, color: primaryGold, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'حجم خط الآيات:',
                            style: GoogleFonts.cairo(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? Colors.white : darkGreen,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                            decoration: BoxDecoration(
                              color: primaryGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${(quranSettings.fontScale * 100).toInt()}%',
                              style: GoogleFonts.cairo(
                                fontWeight: FontWeight.bold,
                                color: isDark ? primaryGold : darkGreen,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: quranSettings.fontScale,
                        min: QuranDisplaySettings.minFontScale,
                        max: QuranDisplaySettings.maxFontScaleWithScroll,
                        divisions: 24,
                        activeColor: primaryGold,
                        inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
                        onChanged: (value) {
                          quranSettings.setFontScale(value);
                        },
                      ),
                      const Divider(height: 24),

                      // Font Family Selection Cards
                      Text(
                        'نوع خط المصحف:',
                        style: GoogleFonts.cairo(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : darkGreen,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...QuranDisplaySettings.fontOptions.map((option) {
                        final isSelected = quranSettings.fontFamilyId == option.id;
                        return InkWell(
                          onTap: () => quranSettings.setFontFamily(option.id),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? primaryGold.withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF242424) : const Color(0xFFFBFBFB)),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? primaryGold
                                    : (isDark ? Colors.white10 : Colors.black12),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.radio_button_off_rounded,
                                  color: isSelected ? primaryGold : Colors.grey,
                                  size: 22,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.name,
                                        style: GoogleFonts.cairo(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: isSelected ? primaryGold : (isDark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        option.preview,
                                        textDirection: TextDirection.rtl,
                                        style: TextStyle(
                                          fontFamily: _quranFontFamilyForId(option.id),
                                          fontSize: 16,
                                          height: 1.4,
                                          color: isDark ? Colors.grey[300] : Colors.grey[800],
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
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. App Info & Help
                _buildSectionHeader('المساعدة وحول التطبيق', Icons.info_outline_rounded, isDark),
                Container(
                  decoration: _cardBoxDecoration(isDark),
                  child: Column(
                    children: [
                      ListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                        ),
                        leading: const Icon(Icons.help_outline_rounded, color: primaryGold),
                        title: Text('دليل الاستخدام والتعليمات', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        subtitle: Text('شرح أدوات المصحف والبحث ومواقيت الصلاة', style: GoogleFonts.cairo(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OnboardingScreen(
                                onComplete: () async => Navigator.of(context).pop(),
                              ),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        leading: const Icon(Icons.rate_review_outlined, color: primaryGold),
                        title: Text('شاركنا رأيك ومقترحاتك', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        subtitle: Text('تقييم التطبيق وإرسال الملاحظات لفريق العمل', style: GoogleFonts.cairo(fontSize: 12)),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const FeedbackScreen()),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      ListTile(
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(bottom: Radius.circular(18)),
                        ),
                        leading: const Icon(Icons.verified_rounded, color: primaryGold),
                        title: Text('تطبيق تلاوات الشيخ عبدالرحمن الزواوي', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
                        subtitle: Text('الإصدار 1.0.0 • جميع الحقوق محفوظة', style: GoogleFonts.cairo(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: primaryGold, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? primaryGold : darkGreen,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardBoxDecoration(bool isDark) {
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : primaryGold.withValues(alpha: 0.2),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
