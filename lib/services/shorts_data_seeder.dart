import '../models/short_video.dart';
import 'shorts_database_helper.dart';

class ShortsDataSeeder {
  final ShortsDatabaseHelper _dbHelper = ShortsDatabaseHelper();

  // البيانات الافتراضية للفيديوهات
  Future<void> seedData() async {
    final now = DateTime.now();

    final videos = [
      // فئة: الداء والدواء (categoryId: 1)
      ShortVideo(
        id: 1,
        categoryId: 1,
        title: 'لماذا القسوة لا تُصلح الصغير - عبدالرحمن الزواوي',
        videoUrl: 'https://res.cloudinary.com/dmpxet5r6/video/upload/v1790503650/%D9%84%D9%85%D8%A7%D8%B0%D8%A7_%D8%A7%D9%84%D9%82%D8%B3%D9%88%D8%A9_%D9%84%D8%A7_%D8%AA%D9%8F%D8%B5%D9%84%D8%AD_%D8%A7%D9%84%D8%B5%D8%BA%D9%8A%D8%B1__%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86_%D8%A7%D9%84%D8%B2%D9%88%D8%A7%D9%88%D9%8A_360P_qo8phl.mp4',
        thumbnailUrl: null,
        viewsCount: 0,
        isActive: true,
        createdAt: now,
      ),

      // فئة: الداء والدواء (categoryId: 1)
      ShortVideo(
        id: 2,
        categoryId: 1,
        title: 'لماذا لا ينبغي للطالب أن يُنهي القراءة بنفسه - من آداب القرآن - عبدالرحمن الزواوي',
        videoUrl: 'https://res.cloudinary.com/dmpxet5r6/video/upload/v1790505371/%D9%84%D9%85%D8%A7%D8%B0%D8%A7_%D9%84%D8%A7_%D9%8A%D9%86%D8%A8%D8%BA%D9%8A%D9%84%D9%84%D8%B7%D8%A7%D9%84%D8%A8_%D8%A3%D9%86_%D9%8A%D9%8F%D9%86%D9%87%D9%8A_%D8%A7%D9%84%D9%82%D8%B1%D8%A7%D8%A1%D8%A9_%D8%A8%D9%86%D9%81%D8%B3%D9%87___%D9%85%D9%86_%D8%A2%D8%AF%D8%A7%D8%A8_%D8%A7%D9%84%D9%82%D8%B1%D8%A2%D9%86__%D8%B9%D8%A8%D8%AF%D8%A7%D9%84%D8%B1%D8%AD%D9%85%D9%86_%D8%A7%D9%84%D8%B2%D9%88%D8%A7%D9%88%D9%8A_360P_d47y4i.mp4',
        thumbnailUrl: null,
        viewsCount: 0,
        isActive: true,
        createdAt: now,
      ),
    ];

    try {
      await _dbHelper.insertShorts(videos);
      print('✅ تم إضافة ${videos.length} فيديو بنجاح');
    } catch (e) {
      print('❌ خطأ في إضافة الفيديوهات: $e');
    }
  }

  // للتحقق إذا كانت البيانات موجودة مسبقاً
  Future<bool> isDataSeeded() async {
    try {
      final result = await _dbHelper.getCategoryShorts(
        categoryId: 1,
        offset: 0,
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // تهيئة البيانات عند أول تشغيل
  Future<void> initializeIfNeeded() async {
    final isSeeded = await isDataSeeded();
    if (!isSeeded) {
      print('📦 تهيئة بيانات الفيديوهات...');
      await seedData();
    } else {
      print('✅ البيانات موجودة مسبقاً');
    }
  }
}
