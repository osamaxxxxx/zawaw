import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../models/surah.dart';
import '../../models/ayah.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';
import '../../services/local_quran_service.dart';

class SurahReaderApiScreen extends StatefulWidget {
  final Surah surah;
  
  const SurahReaderApiScreen({super.key, required this.surah});

  @override
  State<SurahReaderApiScreen> createState() => _SurahReaderApiScreenState();
}

class _SurahReaderApiScreenState extends State<SurahReaderApiScreen> {
  final ApiService _apiService = ApiService();
  final LocalQuranService _quranService = LocalQuranService();
  late Future<List<Ayah>> _ayahsFuture;
  int? _playingAyahNumber;

  @override
  void initState() {
    super.initState();
    _ayahsFuture = _quranService.getAyahsBySurah(widget.surah.id);
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

  void _playAyahAudio(BuildContext context, Ayah ayah) async {
    final audioService = Provider.of<AudioService>(context, listen: false);
    
    setState(() {
      _playingAyahNumber = ayah.ayahNumber;
    });

    try {
      final audioTimings = await _apiService.getAudioForAyah(widget.surah.id, ayah.ayahNumber);
      if (audioTimings.isEmpty || audioTimings.first.audioUrl.isEmpty) {
        throw Exception('تلاوة الزواوي غير متوفرة لهذه الآية حالياً');
      }

      await audioService.loadAudio(
        audioTimings.first.audioUrl,
        id: 'ayah_${widget.surah.id}_${ayah.ayahNumber}',
        title: 'سورة ${widget.surah.nameArabic} - آية ${ayah.ayahNumber}',
        album: 'تلاوات الشيخ الزواوي',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('جاري تشغيل آية ${ayah.ayahNumber}', style: const TextStyle(fontFamily: 'Amiri')),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تشغيل التلاوة: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _playingAyahNumber = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final pageColor = isDark ? Colors.black : const Color(0xFFFDF6E3);
    final textColor = isDark ? Colors.white : Colors.black87;
    final frameColor = isDark ? theme.primaryColor : const Color(0xFF8B0000);

    return Scaffold(
      backgroundColor: pageColor,
      appBar: AppBar(
        title: Text('سورة ${widget.surah.nameArabic}', style: const TextStyle(fontFamily: 'Amiri', fontWeight: FontWeight.bold)),
        backgroundColor: isDark ? const Color(0xFF121212) : theme.appBarTheme.backgroundColor,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Ayah>>(
        future: _ayahsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: frameColor),
                  const SizedBox(height: 16),
                  Text('جاري تحميل الآيات...', style: TextStyle(color: textColor, fontFamily: 'Amiri', fontSize: 18)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 60),
                    const SizedBox(height: 16),
                    Text(
                      'حدث خطأ أثناء تحميل السورة',
                      style: TextStyle(color: textColor, fontFamily: 'Amiri', fontSize: 20),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: isDark ? Colors.grey : Colors.black54),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: frameColor, foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          _ayahsFuture = _quranService.getAyahsBySurah(widget.surah.id);
                        });
                      },
                      child: const Text('إعادة المحاولة', style: TextStyle(fontFamily: 'Amiri')),
                    ),
                  ],
                ),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد آيات لهذه السورة'));
          }

          final ayahs = snapshot.data!;
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ayahs.length,
            itemBuilder: (context, index) {
              final ayah = ayahs[index];
              final isPlaying = _playingAyahNumber == ayah.ayahNumber;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: InkWell(
                  onTap: () => _playAyahAudio(context, ayah),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: isPlaying ? theme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Stack(
                      children: [
                        RichText(
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          text: TextSpan(
                            style: theme.textTheme.titleLarge?.copyWith(
                              height: 1.9,
                              fontFamily: GoogleFonts.scheherazadeNew().fontFamily,
                              fontSize: 28,
                              color: textColor,
                            ),
                            children: [
                              TextSpan(text: '${ayah.textUthmani} '),
                              TextSpan(
                                text: '(${_toArabicNumbers(ayah.ayahNumber)})',
                                style: TextStyle(
                                  color: frameColor,
                                  fontSize: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isPlaying)
                          Positioned(
                            left: 0,
                            top: 0,
                            child: Icon(Icons.volume_up, color: frameColor),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
