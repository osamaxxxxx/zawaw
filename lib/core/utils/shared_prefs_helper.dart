import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsHelper {
  static const String _positionPrefix = 'last_position_surah_';
  static const String _lastPlayedKey = 'last_played_surah_id';

  /// Save playback position in seconds for a specific surah
  static Future<void> saveSurahPosition(int surahId, int positionInSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_positionPrefix$surahId', positionInSeconds);
    // Also save this surah as the last played one
    await saveLastPlayedSurahId(surahId);
  }

  /// Retrieve saved playback position in seconds for a specific surah
  static Future<int?> getSurahPosition(int surahId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_positionPrefix$surahId');
  }

  /// Clear saved playback position for a specific surah
  static Future<void> clearSurahPosition(int surahId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_positionPrefix$surahId');
  }

  /// Save the last played surah ID
  static Future<void> saveLastPlayedSurahId(int surahId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastPlayedKey, surahId);
  }

  /// Retrieve the last played surah ID
  static Future<int?> getLastPlayedSurahId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_lastPlayedKey);
  }
}

