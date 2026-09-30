import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../models/short_category.dart';
import '../models/short_video.dart';

class ShortsDatabaseHelper {
  static final ShortsDatabaseHelper _instance = ShortsDatabaseHelper._internal();

  factory ShortsDatabaseHelper() {
    return _instance;
  }

  ShortsDatabaseHelper._internal();

  Map<String, dynamic>? _cache;

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'shorts_data.json');
    return File(path);
  }

  Future<Map<String, dynamic>> _readData() async {
    if (_cache != null) return _cache!;

    try {
      final file = await _file;
      if (await file.exists()) {
        final contents = await file.readAsString();
        _cache = jsonDecode(contents) as Map<String, dynamic>;
        return _cache!;
      }
    } catch (e) {
      print('Error reading local JSON data: $e');
    }
    
    // Load initial data from assets if local file doesn't exist or failed to load
    try {
      final assetContent = await rootBundle.loadString('assets/data/shorts.json');
      _cache = jsonDecode(assetContent) as Map<String, dynamic>;
      // Save it locally for future writes
      await _writeData(_cache!);
      return _cache!;
    } catch (e) {
      print('Error loading asset JSON data: $e');
    }

    // Fallback empty state
    _cache = {
      'categories': [],
      'shorts': []
    };
    return _cache!;
  }

  Future<void> _writeData(Map<String, dynamic> data) async {
    _cache = data;
    try {
      final file = await _file;
      // Write asynchronously but do not block the caller from using memory cache
      file.writeAsString(jsonEncode(data));
    } catch (e) {
      print('Error writing JSON data: $e');
    }
  }

  Future<List<ShortCategory>> getCategories() async {
    final data = await _readData();
    final categoriesList = data['categories'] as List<dynamic>? ?? [];
    
    final categories = categoriesList.map((c) => ShortCategory.fromJson(c as Map<String, dynamic>)).toList();
    
    // Return only active and sort by order
    final activeCategories = categories.where((c) => c.isActive).toList();
    activeCategories.sort((a, b) => a.order.compareTo(b.order));
    
    return activeCategories;
  }

  Future<List<ShortVideo>> getCategoryShorts({
    required int categoryId,
    int offset = 0,
    int limit = 10,
  }) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    
    var shorts = shortsList.map((s) => ShortVideo.fromJson(s as Map<String, dynamic>)).toList();
    
    shorts = shorts.where((s) => s.categoryId == categoryId && s.isActive).toList();
    shorts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    if (offset >= shorts.length) return [];
    
    final end = (offset + limit < shorts.length) ? offset + limit : shorts.length;
    return shorts.sublist(offset, end);
  }

  Future<int> getCategoryShortsCount(int categoryId) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    
    final shorts = shortsList.map((s) => ShortVideo.fromJson(s as Map<String, dynamic>)).toList();
    return shorts.where((s) => s.categoryId == categoryId && s.isActive).length;
  }

  Future<int> insertShort(ShortVideo video) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    
    int maxId = 0;
    for (var s in shortsList) {
      if ((s['id'] as int) > maxId) {
        maxId = s['id'] as int;
      }
    }
    
    final newId = maxId + 1;
    final videoJson = video.toJson();
    videoJson['id'] = newId;
    
    shortsList.add(videoJson);
    data['shorts'] = shortsList;
    
    await _writeData(data);
    await _updateCategoryShortsCount(video.categoryId);
    
    return newId;
  }

  Future<void> insertShorts(List<ShortVideo> videos) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    
    int maxId = 0;
    for (var s in shortsList) {
      if ((s['id'] as int) > maxId) {
        maxId = s['id'] as int;
      }
    }

    final categoryIds = <int>{};
    
    for (var video in videos) {
      maxId++;
      final videoJson = video.toJson();
      if (video.id == 0) { 
         videoJson['id'] = maxId;
      }
      shortsList.add(videoJson);
      categoryIds.add(video.categoryId);
    }
    
    data['shorts'] = shortsList;
    await _writeData(data);
    
    for (var categoryId in categoryIds) {
      await _updateCategoryShortsCount(categoryId);
    }
  }

  Future<void> incrementViews(int shortId) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    
    for (var i = 0; i < shortsList.length; i++) {
      if (shortsList[i]['id'] == shortId) {
        shortsList[i]['viewsCount'] = (shortsList[i]['viewsCount'] ?? 0) + 1;
        shortsList[i]['updatedAt'] = DateTime.now().toIso8601String();
        break;
      }
    }
    
    data['shorts'] = shortsList;
    await _writeData(data);
  }

  Future<void> _updateCategoryShortsCount(int categoryId) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    final count = shortsList.where((s) => s['categoryId'] == categoryId && (s['isActive'] == true || s['isActive'] == 1)).length;
    
    final categoriesList = data['categories'] as List<dynamic>? ?? [];
    for (var i = 0; i < categoriesList.length; i++) {
      if (categoriesList[i]['id'] == categoryId) {
        categoriesList[i]['shortsCount'] = count;
        categoriesList[i]['updatedAt'] = DateTime.now().toIso8601String();
        break;
      }
    }
    
    data['categories'] = categoriesList;
    await _writeData(data);
  }

  Future<void> deleteShort(int id) async {
    final data = await _readData();
    final shortsList = data['shorts'] as List<dynamic>? ?? [];
    
    int? categoryId;
    shortsList.removeWhere((s) {
      if (s['id'] == id) {
        categoryId = s['categoryId'];
        return true;
      }
      return false;
    });
    
    if (categoryId != null) {
      data['shorts'] = shortsList;
      await _writeData(data);
      await _updateCategoryShortsCount(categoryId!);
    }
  }

  Future<void> deleteDatabase() async {
    final file = await _file;
    if (await file.exists()) {
      await file.delete();
    }
    _cache = null;
  }
}
