import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/surah.dart';
import '../../services/local_quran_service.dart';
import '../../services/audio_service.dart';
import '../../services/surah_download_service.dart';
import '../../core/utils/shared_prefs_helper.dart';
import 'surah_reader_api_screen.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final LocalQuranService _quranService = LocalQuranService();
  late Future<List<Surah>> _surahsFuture;
  String _searchQuery = '';
  List<Surah> _allSurahs = [];

  @override
  void initState() {
    super.initState();
    _fetchSurahs();
  }

  void _fetchSurahs() {
    _surahsFuture = _quranService.getSurahs().then((surahs) {
      _allSurahs = surahs;
      return surahs;
    });
  }

  void _onSurahLongPress(BuildContext context, Surah surah) async {
    final audioService = Provider.of<AudioService>(context, listen: false);
    final downloads = Provider.of<SurahDownloadService>(context, listen: false);
    final savedPositionSec = await SharedPrefsHelper.getSurahPosition(surah.id);

    if (!context.mounted) return;

    if (savedPositionSec != null && savedPositionSec > 0) {
      final savedDuration = Duration(seconds: savedPositionSec);
      String twoDigits(int n) => n.toString().padLeft(2, '0');
      final hours = savedDuration.inHours;
      final minutes = savedDuration.inMinutes.remainder(60);
      final seconds = savedDuration.inSeconds.remainder(60);
      final timeStr = hours > 0
          ? '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}'
          : '${twoDigits(minutes)}:${twoDigits(seconds)}';

      showDialog(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'سورة ${surah.nameArabic}',
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: const Text(
                'لقد استمعت إلى هذه السورة سابقاً. كيف ترغب في الاستماع الآن؟',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    try {
                      if (downloads.isDownloaded(surah.id)) {
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('هذه السورة مُنزّلة بالفعل'),
                            ),
                          );
                        }
                      } else {
                        await downloads.download(surah.id);
                      }
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (_) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تعذر تنزيل التلاوة')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('تنزيل السورة'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    audioService.playSurah(
                      surah.id,
                      startPosition: Duration.zero,
                    );
                  },
                  child: const Text(
                    'التشغيل من البداية',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    audioService.playSurah(
                      surah.id,
                      startPosition: savedDuration,
                    );
                  },
                  child: Text(
                    'استئناف الاستماع ($timeStr)',
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'بدء الاستماع',
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'هل تريد الاستماع إلى سورة ${surah.nameArabic}؟',
                style: const TextStyle(fontFamily: 'Cairo'),
              ),
              actions: [
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await downloads.download(surah.id);
                      if (dialogContext.mounted) {
                        Navigator.of(dialogContext).pop();
                      }
                    } catch (_) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('تعذر تنزيل التلاوة')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.download_for_offline_outlined),
                  label: const Text('تنزيل السورة'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text(
                    'لا',
                    style: TextStyle(fontFamily: 'Cairo', color: Colors.grey),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    audioService.playSurah(surah.id);
                  },
                  child: const Text(
                    'نعم',
                    style: TextStyle(
                      fontFamily: 'Cairo',
                      color: Color(0xFFD4AF37),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121212)
          : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark
            ? const Color(0xFF121212)
            : theme.appBarTheme.backgroundColor,
        elevation: 0,
        title: Text(
          'فهرس السور',
          style: TextStyle(
            color: isDark
                ? theme.primaryColor
                : theme.textTheme.titleLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Surah>>(
        future: _surahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _allSurahs.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError && _allSurahs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'فشل تحميل السور: ${snapshot.error}',
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _fetchSurahs();
                    }),
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              ),
            );
          }

          // Use the fetched surahs for filtering
          var filteredSurahs = _allSurahs
              .where((s) => s.nameArabic.contains(_searchQuery))
              .toList();

          return Column(
            children: [
              _buildSearchBar(theme, isDark),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredSurahs.length,
                  itemBuilder: (context, index) {
                    final surah = filteredSurahs[index];
                    return _buildListItemCard(
                      theme: theme,
                      isDark: isDark,
                      number: surah.id,
                      title: surah.nameArabic,
                      subtitle: surah.nameEnglish.isNotEmpty
                          ? surah.nameEnglish
                          : 'سورة ${surah.id}',
                      surahId: surah.id,
                      onTap: () => _onSurahLongPress(context, surah),
                      onLongPress: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SurahReaderApiScreen(surah: surah),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'بحث في أسماء السور',
          hintStyle: TextStyle(color: isDark ? Colors.grey : Colors.black54),
          prefixIcon: Icon(
            Icons.search,
            color: isDark ? Colors.white : Colors.black54,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF222222) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildListItemCard({
    required ThemeData theme,
    required bool isDark,
    required int number,
    required String title,
    required String subtitle,
    required int surahId,
    required VoidCallback onTap,
    required VoidCallback onLongPress,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Consumer<SurahDownloadService>(
        builder: (context, downloads, _) => ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          onTap: onTap,
          onLongPress: onLongPress,
          title: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF121212)
                  : theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _toArabicNumbers(number),
              style: TextStyle(
                color: isDark ? Colors.white : theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          trailing: IconButton(
            tooltip: downloads.isDownloading(surahId)
                ? 'جاري التنزيل... (${(downloads.getSurahProgress(surahId) * 100).toInt()}%)'
                : downloads.isDownloaded(surahId)
                ? 'مُنزّلة بالفعل'
                : 'تنزيل التلاوة',
            icon: downloads.isDownloading(surahId)
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      value: downloads.getSurahProgress(surahId) > 0 ? downloads.getSurahProgress(surahId) : null,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    downloads.isDownloaded(surahId)
                        ? Icons.download_done_rounded
                        : Icons.download_for_offline_outlined,
                    color: downloads.isDownloaded(surahId)
                        ? const Color(0xFF2D6A4F)
                        : theme.primaryColor,
                  ),
            onPressed: downloads.isDownloading(surahId)
                ? null
                : () async {
                    try {
                      if (downloads.isDownloaded(surahId)) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('هذه التلاوة مُنزّلة بالفعل'),
                            ),
                          );
                        }
                      } else {
                        await downloads.download(surahId);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'تم تنزيل التلاوة للاستماع دون إنترنت',
                              ),
                            ),
                          );
                        }
                      }
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تعذر استكمال تنزيل التلاوة. يمكنك المحاولة مرة أخرى للاستئناف من حيث توقف.',
                            ),
                          ),
                        );
                      }
                    }
                  },
          ),
        ),
      ),
    );
  }

  String _toArabicNumbers(int number) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const arabic = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    String result = number.toString();
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], arabic[i]);
    }
    return result;
  }
}
