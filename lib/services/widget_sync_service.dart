import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tafsir_service.dart';

/// Notifies the native home-screen widgets after their shared data changes.
class WidgetSyncService {
  static const _androidChannel = MethodChannel(
    'zawawy_app/prayer_notifications',
  );
  static const _iosChannel = MethodChannel('zawawy_app/widgets');

  static Future<void> refresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedAyahs = prefs.getStringList('saved_ayahs') ?? const [];
      // A bad legacy value must never prevent the application from starting.
      // Parse each bookmark independently and leave unreadable entries out of
      // the widget data; the original stored list remains untouched.
      final savedAyahs = <Map<String, dynamic>>[];
      for (final rawAyah in storedAyahs) {
        try {
          final decoded = jsonDecode(rawAyah);
          if (decoded is Map) {
            savedAyahs.add(Map<String, dynamic>.from(decoded));
          }
        } on FormatException {
          // Ignore malformed legacy data for the optional home-screen widget.
        } on TypeError {
          // Ignore values that decode to a type other than a JSON object.
        }
      }

      // Older bookmarks did not include tafsir. Complete them during widget
      // synchronization so the saved-ayah widget can show an explanation too.
      var changed = false;
      final tafsirService = TafsirService();
      for (var index = 0; index < savedAyahs.length; index++) {
        final ayah = savedAyahs[index];
        if ((ayah['tafsir'] as String? ?? '').trim().isNotEmpty) continue;
        final surah = ayah['surah'];
        final ayahNumber = ayah['ayah'];
        if (surah is! num || ayahNumber is! num) continue;
        try {
          final tafsir = await tafsirService.getTafsir(
            surahId: surah.toInt(),
            ayahNumber: ayahNumber.toInt(),
          );
          savedAyahs[index] = {...ayah, 'tafsir': tafsir};
          changed = true;
        } catch (_) {
          // The bookmark remains available; a later sync can retry.
        }
      }

      if (changed) {
        await prefs.setStringList(
          'saved_ayahs',
          savedAyahs.map(jsonEncode).toList(),
        );
      }
      final arguments = {'ayahs': savedAyahs};
      try {
        await _androidChannel.invokeMethod<void>('updateSavedAyahs', arguments);
      } on PlatformException {
        // This bridge is Android-only.
      } on MissingPluginException {
        // This bridge is Android-only.
      }
      try {
        await _iosChannel.invokeMethod<void>('updateSavedAyahs', arguments);
      } on PlatformException {
        // This bridge is iOS-only.
      } on MissingPluginException {
        // This bridge is iOS-only.
      }
    } on FormatException {
      // Ignore legacy malformed bookmark data without blocking the user.
    } on TypeError {
      // Shared preferences can contain legacy values with unexpected types.
    }
  }
}
