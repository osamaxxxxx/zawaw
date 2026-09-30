import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TafsirService {
  static const String _edition = 'ar.muyassar';
  static const String _baseUrl = 'https://api.alquran.cloud/v1';
  static const Duration _timeout = Duration(seconds: 12);

  Future<String> getTafsir({
    required int surahId,
    required int ayahNumber,
  }) async {
    final cacheKey = 'tafsir_${_edition}_${surahId}_$ayahNumber';
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.trim().isNotEmpty) {
      return cached;
    }

    final uri = Uri.parse('$_baseUrl/ayah/$surahId:$ayahNumber/$_edition');
    final response = await http.get(uri).timeout(_timeout);
    if (response.statusCode != 200) {
      throw Exception('تعذر تحميل التفسير الآن');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    if (payload['code'] != 200 || payload['data'] is! Map<String, dynamic>) {
      throw Exception('تعذر قراءة التفسير');
    }

    final tafsir = (payload['data']['text'] as String? ?? '').trim();
    if (tafsir.isEmpty) {
      throw Exception('لا يوجد تفسير متاح لهذه الآية');
    }

    await prefs.setString(cacheKey, tafsir);
    return tafsir;
  }
}
