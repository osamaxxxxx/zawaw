import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QuranDisplaySettings extends ChangeNotifier {
  static const String _fontScaleKey = 'quran_font_scale';
  static const String _fontFamilyKey = 'quran_font_family';
  static const double minFontScale = 0.5;
  static const double maxFontScaleWithoutScroll = 1.05;
  static const double maxFontScaleWithScroll = 1.7;

  static const List<QuranFontOption> fontOptions = [
    QuranFontOption(
      id: 'uthmanic_hafs',
      name: 'عثماني حفص (مصحف المدينة)',
      preview: 'فَاقْرَءُوا مَا تَيَسَّرَ مِنَ الْقُرْآنِ',
    ),
    QuranFontOption(
      id: 'amiri_quran',
      name: 'الأميري القرآني (Amiri Quran)',
      preview: 'وَرَتِّلِ الْقُرْآنَ تَرْتِيلًا',
    ),
    QuranFontOption(
      id: 'noto_naskh',
      name: 'النسخ القرآني (Noto Naskh)',
      preview: 'إِنَّ هَٰذَا الْقُرْآنَ يَهْدِي لِلَّتِي هِيَ أَقْوَمُ',
    ),
    QuranFontOption(
      id: 'scheherazade',
      name: 'خط شهرزاد (Scheherazade New)',
      preview: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
    ),
    QuranFontOption(
      id: 'amiri',
      name: 'الخط الأميري (Amiri)',
      preview: 'وَإِذَا قُرِئَ الْقُرْآنُ فَاسْتَمِعُوا لَهُ',
    ),
    QuranFontOption(
      id: 'lateef',
      name: 'خط لطيف (Lateef)',
      preview: 'تَبَارَكَ الَّذِي نَزَّلَ الْفُرْقَانَ عَلَىٰ عَبْدِهِ',
    ),
    QuranFontOption(
      id: 'tajawal',
      name: 'خط تجوال (Tajawal)',
      preview: 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ',
    ),
    QuranFontOption(
      id: 'almarai',
      name: 'خط المراعي (Almarai)',
      preview: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    ),
    QuranFontOption(
      id: 'el_messiri',
      name: 'خط المسيري (El Messiri)',
      preview: 'قُلْ هُوَ اللَّهُ أَحَدٌ',
    ),
    QuranFontOption(
      id: 'aref_ruqaa',
      name: 'خط رقعة (Aref Ruqaa)',
      preview: 'الرَّحْمَٰنُ عَلَّمَ الْقُرْآنَ',
    ),
    QuranFontOption(
      id: 'reem_kufi',
      name: 'خط ريم كوفي (Reem Kufi)',
      preview: 'اقْرَأْ بِاسْمِ رَبِّكَ الَّذِي خَلَقَ',
    ),
    QuranFontOption(
      id: 'cairo',
      name: 'خط كايرو (Cairo)',
      preview: 'شَهْرُ رَمَضَانَ الَّذِي أُنزِلَ فِيهِ الْقُرْآنُ',
    ),
  ];

  double _fontScale = 1.0;
  String _fontFamilyId = fontOptions.first.id;

  double get fontScale => _fontScale;
  String get fontFamilyId => _fontFamilyId;
  QuranFontOption get selectedFontOption => fontOptions.firstWhere(
        (option) => option.id == _fontFamilyId,
        orElse: () => fontOptions.first,
      );
  bool get scrollMode => _fontScale > maxFontScaleWithoutScroll;
  double get quranFontSize => 32 * _fontScale;
  double get ayahNumberFontSize => 28 * _fontScale;

  QuranDisplaySettings() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _fontScale = (prefs.getDouble(_fontScaleKey) ?? 1.0).clamp(
      minFontScale,
      maxFontScaleWithScroll,
    );
    final savedFontFamily = prefs.getString(_fontFamilyKey);
    if (fontOptions.any((option) => option.id == savedFontFamily)) {
      _fontFamilyId = savedFontFamily!;
    }
    notifyListeners();
  }

  Future<void> setFontScale(double value) async {
    _fontScale = value.clamp(minFontScale, maxFontScaleWithScroll);
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontScaleKey, _fontScale);
  }

  Future<void> setFontFamily(String value) async {
    if (!fontOptions.any((option) => option.id == value)) return;

    _fontFamilyId = value;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontFamilyKey, _fontFamilyId);
  }

  Future<void> setScrollMode(bool value) async {
    // Scroll mode is now automatically determined by fontScale.
    // Kept as a no-op for backward compatibility.
  }
}

class QuranFontOption {
  final String id;
  final String name;
  final String preview;

  const QuranFontOption({
    required this.id,
    required this.name,
    required this.preview,
  });
}
