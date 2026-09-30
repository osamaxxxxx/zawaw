import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/surah.dart';
import '../models/ayah.dart';
import '../models/audio_timing.dart';

class ApiService {
  static const String remoteUrl = 'http://zawawyapi.runasp.net';

  // Use the deployed server URL
  static String get baseUrl {
    const url = '$remoteUrl/api';
    print('==================================================');
    print('🌐 API BASE URL IS SET TO: $url');
    print('==================================================');
    return url;
  }

  Future<List<Surah>> getSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check Cache First
    final cachedSurahs = prefs.getString('cached_surahs');
    if (cachedSurahs != null) {
      final List<dynamic> jsonList = jsonDecode(cachedSurahs);
      return jsonList.map((json) => Surah.fromJson(json)).toList();
    }

    // Fetch from API
    try {
      final response = await http.get(Uri.parse('$baseUrl/surahs')).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        // Cache the response
        await prefs.setString('cached_surahs', response.body);
        
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Surah.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load surahs: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching surahs: $e');
    }
  }

  Future<Surah> getSurahById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/surahs/$id'));
      
      if (response.statusCode == 200) {
        return Surah.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load surah $id: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching surah $id: $e');
    }
  }

  Future<List<Ayah>> getAyahsBySurah(int surahId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ayahs?surahId=$surahId'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Ayah.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load ayahs for surah $surahId: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching ayahs: $e');
    }
  }

  Future<Ayah> getSpecificAyah(int surahId, int ayahNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ayahs?surahId=$surahId&ayahNumber=$ayahNumber'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        if (jsonList.isNotEmpty) {
           return Ayah.fromJson(jsonList.first);
        }
        throw Exception('Ayah not found in response');
      } else {
        throw Exception('Failed to load specific ayah: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching specific ayah: $e');
    }
  }

  Future<List<Ayah>> getAyahsByPage(int pageNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/ayahs/page/$pageNumber')).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => Ayah.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load ayahs for page $pageNumber: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching page $pageNumber: $e');
    }
  }

  Future<List<AudioTiming>> getAudioForAyah(int surahId, int ayahNumber) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/audio/$surahId/$ayahNumber'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.map((json) => AudioTiming.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load audio timing: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error while fetching audio timing: $e');
    }
  }
}
