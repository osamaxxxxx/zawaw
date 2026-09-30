import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/ayah.dart';
import '../models/surah.dart';

_QuranCache _parseQuranData(String rawJson) {
  final data = jsonDecode(rawJson) as Map<String, dynamic>;

  final surahs = (data['surahs'] as List<dynamic>? ?? [])
      .map((json) => Surah.fromJson(Map<String, dynamic>.from(json as Map)))
      .toList();

  final ayahs = (data['ayahs'] as List<dynamic>? ?? [])
      .map((json) => Ayah.fromJson(Map<String, dynamic>.from(json as Map)))
      .toList();

  final ayahsByPage = <int, List<Ayah>>{};
  final ayahsBySurah = <int, List<Ayah>>{};

  for (final ayah in ayahs) {
    (ayahsByPage[ayah.pageNumber] ??= []).add(ayah);
    (ayahsBySurah[ayah.surahId] ??= []).add(ayah);
  }

  return _QuranCache(
    data: data,
    surahs: surahs,
    ayahs: ayahs,
    ayahsByPage: ayahsByPage,
    ayahsBySurah: ayahsBySurah,
  );
}

class LocalQuranService {
  static const String _assetPath = 'assets/data/quran_data.json';

  static Future<void>? _loadFuture;
  static Map<String, dynamic>? _data;
  static List<Surah>? _surahs;
  static List<Ayah>? _ayahs;
  static Map<int, List<Ayah>>? _ayahsByPage;
  static Map<int, List<Ayah>>? _ayahsBySurah;

  bool get isLoaded => _data != null;

  Future<void> preload() => _ensureLoaded();

  List<Surah>? getCachedSurahs() {
    final surahs = _surahs;
    if (surahs == null) return null;
    return List<Surah>.unmodifiable(surahs);
  }

  List<Ayah>? getCachedAyahsByPage(int pageNumber) {
    final ayahsByPage = _ayahsByPage;
    if (ayahsByPage == null) return null;
    return List<Ayah>.unmodifiable(ayahsByPage[pageNumber] ?? const []);
  }

  List<Ayah>? getCachedAyahsBySurah(int surahId) {
    final ayahsBySurah = _ayahsBySurah;
    if (ayahsBySurah == null) return null;
    return List<Ayah>.unmodifiable(ayahsBySurah[surahId] ?? const []);
  }

  Future<void> _ensureLoaded() {
    if (_data != null) return Future<void>.value();
    return _loadFuture ??= _load().catchError((Object error) {
      _loadFuture = null;
      throw error;
    });
  }

  Future<void> _load() async {
    final rawJson = await rootBundle.loadString(_assetPath);
    final cache = await compute(_parseQuranData, rawJson);

    _data = cache.data;
    _surahs = cache.surahs;
    _ayahs = cache.ayahs;
    _ayahsByPage = cache.ayahsByPage;
    _ayahsBySurah = cache.ayahsBySurah;
  }

  Future<List<Surah>> getSurahs() async {
    await _ensureLoaded();
    return List<Surah>.unmodifiable(_surahs!);
  }

  Future<List<Ayah>> getAyahsByPage(int pageNumber) async {
    await _ensureLoaded();
    return List<Ayah>.unmodifiable(_ayahsByPage![pageNumber] ?? const []);
  }

  Future<List<Ayah>> getAyahsBySurah(int surahId) async {
    await _ensureLoaded();
    return List<Ayah>.unmodifiable(_ayahsBySurah![surahId] ?? const []);
  }

  Future<List<QuranSearchResult>> searchAyahs(
    String query, {
    int limit = 30,
  }) async {
    await _ensureLoaded();

    final normalizedQuery = _normalizeArabic(query);
    if (normalizedQuery.length < 2) return const [];

    final results = <QuranSearchResult>[];
    for (final ayah in _ayahs!) {
      final normalizedText = _normalizeArabic(ayah.textUthmani);
      if (!normalizedText.contains(normalizedQuery)) continue;

      final surah = _surahs!.firstWhere((surah) => surah.id == ayah.surahId);
      results.add(QuranSearchResult(ayah: ayah, surah: surah));

      if (results.length >= limit) break;
    }

    return List<QuranSearchResult>.unmodifiable(results);
  }

  Future<Ayah> getSpecificAyah(int surahId, int ayahNumber) async {
    final ayahs = await getAyahsBySurah(surahId);
    return ayahs.firstWhere((ayah) => ayah.ayahNumber == ayahNumber);
  }

  static String _normalizeArabic(String value) {
    return value
        .trim()
        .replaceAll(
          RegExp(r'[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED]'),
          '',
        )
        .replaceAll('\u0640', '')
        .replaceAll(RegExp('[\u0625\u0623\u0622\u0671]'), '\u0627')
        .replaceAll('\u0649', '\u064A')
        .replaceAll('\u0629', '\u0647')
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}

class _QuranCache {
  final Map<String, dynamic> data;
  final List<Surah> surahs;
  final List<Ayah> ayahs;
  final Map<int, List<Ayah>> ayahsByPage;
  final Map<int, List<Ayah>> ayahsBySurah;

  const _QuranCache({
    required this.data,
    required this.surahs,
    required this.ayahs,
    required this.ayahsByPage,
    required this.ayahsBySurah,
  });
}

class QuranSearchResult {
  final Ayah ayah;
  final Surah surah;

  const QuranSearchResult({
    required this.ayah,
    required this.surah,
  });
}
