import '../models/short_video.dart';
import '../models/short_category.dart';
import 'shorts_database_helper.dart';

class PagedShortsResult {
  final List<ShortVideo> items;
  final int page;
  final int limit;
  final int totalCount;
  final int totalPages;
  final bool hasMore;

  PagedShortsResult({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalCount,
    required this.totalPages,
    required this.hasMore,
  });
}

class ShortsService {
  final ShortsDatabaseHelper _dbHelper = ShortsDatabaseHelper();

  // جلب جميع الفئات
  Future<List<ShortCategory>> getCategories() async {
    try {
      return await _dbHelper.getCategories();
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  // جلب شورتس حسب الفئة مع pagination
  Future<PagedShortsResult> getCategoryShorts({
    required int categoryId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final offset = (page - 1) * limit;

      // جلب الفيديوهات
      final videos = await _dbHelper.getCategoryShorts(
        categoryId: categoryId,
        offset: offset,
        limit: limit,
      );

      // حساب العدد الكلي
      final totalCount = await _dbHelper.getCategoryShortsCount(categoryId);
      final totalPages = (totalCount / limit).ceil();
      final hasMore = page < totalPages;

      return PagedShortsResult(
        items: videos,
        page: page,
        limit: limit,
        totalCount: totalCount,
        totalPages: totalPages,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Error fetching shorts: $e');
    }
  }

  // زيادة عدد المشاهدات
  Future<void> incrementViews(int shortId) async {
    try {
      await _dbHelper.incrementViews(shortId);
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  // إضافة فيديو جديد
  Future<int> addShort(ShortVideo video) async {
    try {
      return await _dbHelper.insertShort(video);
    } catch (e) {
      throw Exception('Error adding short: $e');
    }
  }

  // إضافة عدة فيديوهات دفعة واحدة
  Future<void> addShorts(List<ShortVideo> videos) async {
    try {
      await _dbHelper.insertShorts(videos);
    } catch (e) {
      throw Exception('Error adding shorts: $e');
    }
  }

  // حذف فيديو
  Future<void> deleteShort(int shortId) async {
    try {
      await _dbHelper.deleteShort(shortId);
    } catch (e) {
      throw Exception('Error deleting short: $e');
    }
  }
}
