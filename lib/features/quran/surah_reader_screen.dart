import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:provider/provider.dart';
import '../audio_player/audio_manager.dart';

class SurahReaderScreen extends StatefulWidget {
  final int surahNumber;
  const SurahReaderScreen({super.key, required this.surahNumber});

  @override
  State<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends State<SurahReaderScreen> {
  int? _currentPlayingAyah;

  @override
  void initState() {
    super.initState();
    // TODO: Connect Firebase Storage logic here to load the actual audio.
    // For now we setup a placeholder.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDummyAudioForSurah();
    });
  }

  void _loadDummyAudioForSurah() {
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    
    // Formatting Surah number to be 3 digits (e.g., 1 -> '001', 114 -> '114')
    String formattedSurah = widget.surahNumber.toString().padLeft(3, '0');
    
    // Placeholder audio file from mp3quran.net (e.g., Mishary Alafasy) 
    // until the user provides Sheikh Al-Zawawy's files.
    String audioUrl = 'https://server8.mp3quran.net/afs/$formattedSurah.mp3';

    audioManager.loadAudio(
      audioUrl, 
      title: 'سورة ${quran.getSurahNameArabic(widget.surahNumber)}',
      album: 'الشيخ عبد الرحمن الزواوي (مؤقت)',
    );
  }

  void _playFromAyah(int ayahNumber) {
    setState(() {
      _currentPlayingAyah = ayahNumber;
    });
    
    final audioManager = Provider.of<AudioManager>(context, listen: false);
    
    // TODO: Map ayah number to a time duration in the audio file.
    // Without exact timestamps for each verse, this is tricky. 
    // Usually, this is handled by a backend returning a duration for each ayah 
    // or using a specific API that provides verse-by-verse audio files.
    // Assuming we have timestamps, we would do:
    // audioManager.seek(Duration(seconds: ...));
    
    if (!audioManager.isPlaying) {
      audioManager.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final verseCount = quran.getVerseCount(widget.surahNumber);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('سورة ${quran.getSurahNameArabic(widget.surahNumber)}'),
      ),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: RichText(
            textAlign: TextAlign.justify,
            text: TextSpan(
              style: theme.textTheme.titleLarge?.copyWith(
                height: 2.0, 
                fontSize: 24, // Quranic text size
                fontFamily: 'Amiri', // Best for Quran text
              ),
              children: List.generate(verseCount, (index) {
                int ayahNumber = index + 1;
                bool isPlaying = _currentPlayingAyah == ayahNumber;

                return TextSpan(
                  children: [
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () => _playFromAyah(ayahNumber),
                        child: Container(
                          decoration: isPlaying 
                            ? BoxDecoration(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              )
                            : null,
                          child: Text(
                            '${quran.getVerse(widget.surahNumber, ayahNumber)} ',
                            style: theme.textTheme.titleLarge?.copyWith(
                              height: 2.0,
                              fontSize: 24,
                              fontFamily: 'Amiri',
                              color: isPlaying ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextSpan(
                      text: '${quran.getVerseEndSymbol(ayahNumber)} ',
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildAudioControl(theme),
    );
  }

  Widget _buildAudioControl(ThemeData theme) {
    return Consumer<AudioManager>(
      builder: (context, audioManager, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: theme.cardTheme.color,
          child: SafeArea(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous),
                  onPressed: () {
                    // Previous Surah or replay
                  },
                ),
                IconButton(
                  iconSize: 48,
                  color: theme.primaryColor,
                  icon: Icon(audioManager.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill),
                  onPressed: () {
                    audioManager.togglePlayPause();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next),
                  onPressed: () {
                    // Next Surah
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
