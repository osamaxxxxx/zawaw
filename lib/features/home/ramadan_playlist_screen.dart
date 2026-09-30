import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/audio_service.dart';
import '../../services/surah_download_service.dart';

class RamadanPlaylistScreen extends StatefulWidget {
  const RamadanPlaylistScreen({super.key});

  @override
  State<RamadanPlaylistScreen> createState() => _RamadanPlaylistScreenState();
}

class _RamadanPlaylistScreenState extends State<RamadanPlaylistScreen> {
  late final Future<List<RamadanNight>> _nightsFuture = _loadNights();
  int _selectedDay = 1;
  RamadanTrack? _selectedTrack;
  AudioService? _audioService;
  int _lastSavedSecond = -1;

  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color darkGreen = Color(0xFF1B4332);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final audioService = context.read<AudioService>();
    if (_audioService == audioService) return;

    _audioService?.removeListener(_saveCurrentTrackPosition);
    _audioService?.removeListener(_onAudioServiceChanged);

    _audioService = audioService;

    _audioService?.addListener(_saveCurrentTrackPosition);
    _audioService?.addListener(_onAudioServiceChanged);

    // Initial sync of active track
    _onAudioServiceChanged();
  }

  @override
  void dispose() {
    _saveCurrentTrackPosition();
    _audioService?.removeListener(_saveCurrentTrackPosition);
    _audioService?.removeListener(_onAudioServiceChanged);
    super.dispose();
  }

  void _onAudioServiceChanged() {
    if (!mounted) return;
    final trackId = _audioService?.currentTrackId;
    if (trackId != null) {
      if (_selectedTrack == null || _selectedTrack!.id != trackId) {
        _syncActiveTrack(trackId);
      }
    } else {
      if (_selectedTrack != null && _audioService?.currentSurahId == null) {
        setState(() {
          _selectedTrack = null;
        });
      }
    }
  }

  void _syncActiveTrack(String trackId) async {
    final nights = await _nightsFuture;
    for (var night in nights) {
      for (var track in night.items) {
        if (track.id == trackId) {
          if (mounted) {
            setState(() {
              _selectedTrack = track;
            });
          }
          return;
        }
      }
    }
  }

  Future<List<RamadanNight>> _loadNights() async {
    final jsonText = await rootBundle.loadString(
      'assets/data/ramadan_playlist.json',
    );
    final data = jsonDecode(jsonText) as Map<String, dynamic>;
    final days = data['days'] as List<dynamic>;
    return days
        .map((day) => RamadanNight.fromJson(day as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFFBF8F1),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'رمضان 1447هـ - 2026م',
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: isDark ? primaryGold : darkGreen,
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<List<RamadanNight>>(
          future: _nightsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator(color: primaryGold));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return Center(
                child: Text(
                  'تعذر تحميل محتوى رمضان المبارك',
                  style: GoogleFonts.cairo(fontSize: 16),
                ),
              );
            }

            final nights = snapshot.data!;
            final selectedNight = nights.firstWhere(
              (night) => night.day == _selectedDay,
              orElse: () => nights.first,
            );

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                _buildHeader(context, isDark),
                const SizedBox(height: 16),
                _buildNightGrid(nights, isDark),
                const SizedBox(height: 18),
                _buildNightTracks(context, selectedNight, isDark),
                const SizedBox(height: 18),
                _buildPlayer(context, isDark),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1E1E), const Color(0xFF141414)]
              : [Colors.white, const Color(0xFFFAF7EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: primaryGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.nightlight_round, color: primaryGold, size: 32),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ليالي شهر رمضان المبارك',
                  style: GoogleFonts.cairo(
                    fontSize: 16.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : darkGreen,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'تلاوات القيام، أدعية التراويح، وصلوات التهجد بصوت الشيخ عبدالرحمن الزواوي',
                  style: GoogleFonts.cairo(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNightGrid(List<RamadanNight> nights, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'اختر الليلة المباركة:',
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isDark ? primaryGold : darkGreen,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: primaryGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'الليلة $_selectedDay من رمضان',
                style: GoogleFonts.cairo(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? primaryGold : darkGreen,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: nights.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            final night = nights[index];
            final isSelected = night.day == _selectedDay;
            final hasItems = night.items.isNotEmpty;
            final isLastTen = night.day >= 21;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedDay = night.day;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryGold
                      : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? primaryGold
                        : isLastTen
                            ? primaryGold.withValues(alpha: 0.5)
                            : (isDark ? Colors.white12 : Colors.black12),
                    width: isSelected || isLastTen ? 1.4 : 1.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryGold.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${night.day}',
                      style: GoogleFonts.cairo(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.black87
                            : (isDark ? Colors.white : darkGreen),
                      ),
                    ),
                    Icon(
                      hasItems ? Icons.nightlight_round : Icons.circle_outlined,
                      size: 11,
                      color: isSelected
                          ? Colors.black87
                          : (hasItems ? primaryGold : Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNightTracks(BuildContext context, RamadanNight night, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Icon(Icons.queue_music_rounded, color: primaryGold, size: 20),
            const SizedBox(width: 8),
            Text(
              night.label,
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                fontSize: 15.5,
                color: isDark ? Colors.white : darkGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (night.items.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
            ),
            child: Center(
              child: Text(
                'لا توجد تسجيلات مضافة لهذه الليلة حاليًا.',
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          )
        else
          ...night.items.map((track) => _buildTrackTile(context, track, isDark)),
      ],
    );
  }

  Widget _buildTrackTile(BuildContext context, RamadanTrack track, bool isDark) {
    final isSelected = _selectedTrack?.id == track.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? primaryGold.withValues(alpha: isDark ? 0.15 : 0.1)
            : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? primaryGold
              : (isDark ? Colors.white10 : primaryGold.withValues(alpha: 0.2)),
          width: isSelected ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Consumer<SurahDownloadService>(
        builder: (context, downloads, _) => ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _typeColor(track.type).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_typeIcon(track.type), color: _typeColor(track.type), size: 22),
          ),
          title: Text(
            track.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.cairo(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isSelected ? primaryGold : (isDark ? Colors.white : darkGreen),
            ),
          ),
          subtitle: Text(
            track.typeLabel,
            style: GoogleFonts.cairo(
              fontSize: 11.5,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: downloads.isTrackDownloading(track.id)
                    ? 'جاري تنزيل التسجيل... (${(downloads.getTrackProgress(track.id) * 100).toInt()}%)'
                    : downloads.isTrackDownloaded(track.id)
                    ? 'التسجيل مُنزّل بجهازك'
                    : 'تنزيل التسجيل',
                icon: downloads.isTrackDownloading(track.id)
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          value: downloads.getTrackProgress(track.id) > 0 ? downloads.getTrackProgress(track.id) : null,
                          strokeWidth: 2,
                          color: primaryGold,
                        ),
                      )
                    : Icon(
                        downloads.isTrackDownloaded(track.id)
                            ? Icons.download_done_rounded
                            : Icons.download_for_offline_outlined,
                        color: downloads.isTrackDownloaded(track.id) ? Colors.green : primaryGold,
                        size: 22,
                      ),
                onPressed: downloads.isTrackDownloading(track.id)
                    ? null
                    : () async {
                        try {
                          if (downloads.isTrackDownloaded(track.id)) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('هذا التسجيل مُنزّل بالفعل على جهازك', style: GoogleFonts.cairo()),
                                  backgroundColor: darkGreen,
                                ),
                              );
                            }
                          } else {
                            await downloads.downloadTrack(
                              id: track.id,
                              title: track.title,
                              url: track.url,
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('تعذر استكمال تنزيل التسجيل. يمكنك المحاولة مرة أخرى للاستئناف من حيث توقف.', style: GoogleFonts.cairo()),
                                backgroundColor: Colors.redAccent,
                              ),
                            );
                          }
                        }
                      },
              ),
              const SizedBox(width: 4),
              Icon(
                isSelected ? Icons.graphic_eq_rounded : Icons.play_circle_fill_rounded,
                color: primaryGold,
                size: 28,
              ),
            ],
          ),
          onTap: () => _playTrack(track),
        ),
      ),
    );
  }

  Widget _buildPlayer(BuildContext context, bool isDark) {
    final track = _selectedTrack;
    if (track == null) return const SizedBox.shrink();

    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final totalSeconds = audioService.totalDuration.inSeconds <= 0
            ? 1.0
            : audioService.totalDuration.inSeconds.toDouble();
        final currentSeconds = audioService.currentPosition.inSeconds
            .clamp(0, totalSeconds.toInt())
            .toDouble();
        final statusMessage =
            audioService.errorMessage ??
            (audioService.isLoading ? 'جارٍ تحميل وتشغيل التلاوة...' : null);

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: primaryGold.withValues(alpha: 0.4), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: primaryGold.withValues(alpha: isDark ? 0.08 : 0.15),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _typeColor(track.type).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_typeIcon(track.type), color: _typeColor(track.type), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      track.title,
                      style: GoogleFonts.cairo(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : darkGreen,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 5.0,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7.0),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14.0),
                  activeTrackColor: primaryGold,
                  inactiveTrackColor: isDark ? Colors.grey[800] : Colors.grey[300],
                  thumbColor: primaryGold,
                  overlayColor: primaryGold.withValues(alpha: 0.2),
                ),
                child: Slider(
                  min: 0,
                  max: totalSeconds,
                  value: currentSeconds,
                  onChanged: (value) {
                    audioService.seek(Duration(seconds: value.round()));
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(audioService.currentPosition),
                      style: GoogleFonts.cairo(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    Text(
                      _formatDuration(audioService.totalDuration),
                      style: GoogleFonts.cairo(fontSize: 11.5, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              if (statusMessage != null) ...[
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    statusMessage,
                    style: GoogleFonts.cairo(
                      fontSize: 12,
                      color: audioService.errorMessage != null ? Colors.redAccent : primaryGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    tooltip: 'تقديم 10 ثوانٍ',
                    onPressed: () => _seekBy(audioService, 10),
                    icon: const Icon(Icons.replay_10_rounded),
                  ),
                  const SizedBox(width: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryGold,
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: audioService.isLoading ? null : audioService.togglePlayPause,
                    icon: audioService.isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87),
                          )
                        : Icon(audioService.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 24),
                    label: Text(
                      audioService.isPlaying ? 'إيقاف مؤقت' : 'استماع',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 14),
                  IconButton.filledTonal(
                    tooltip: 'تأخير 10 ثوانٍ',
                    onPressed: () => _seekBy(audioService, -10),
                    icon: const Icon(Icons.forward_10_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Playback Speed
              SegmentedButton<double>(
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                segments: const [
                  ButtonSegment(value: 0.75, label: Text('0.75x')),
                  ButtonSegment(value: 1.0, label: Text('1x')),
                  ButtonSegment(value: 1.25, label: Text('1.25x')),
                  ButtonSegment(value: 1.5, label: Text('1.5x')),
                ],
                selected: {audioService.playbackSpeed},
                onSelectionChanged: (selection) {
                  audioService.setSpeed(selection.first);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _playTrack(RamadanTrack track) async {
    await _saveCurrentTrackPosition();
    final startPosition = await _pickStartPosition(track);
    if (startPosition == null) return;
    if (!mounted) return;

    setState(() {
      _selectedTrack = track;
    });
    _lastSavedSecond = startPosition.inSeconds;

    final audioService = context.read<AudioService>();
    await audioService.loadAudio(
      track.url,
      id: track.id,
      title: track.title,
      album: 'رمضان 2026 - الشيخ عبد الرحمن الزواوي',
      startPosition: startPosition,
    );
  }

  Future<Duration?> _pickStartPosition(RamadanTrack track) async {
    final prefs = await SharedPreferences.getInstance();
    final savedSeconds = prefs.getInt(_positionKey(track.id)) ?? 0;
    if (savedSeconds < 5 || !mounted) return Duration.zero;

    final resume = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('تشغيل التسجيل', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
          content: Text(
            'هل تريد البدء من البداية أم الاستئناف من ${_formatDuration(Duration(seconds: savedSeconds))}؟',
            style: GoogleFonts.cairo(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text('من البداية', style: GoogleFonts.cairo(color: Colors.grey)),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: primaryGold, foregroundColor: Colors.black87),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text('استئناف', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (resume == null) return null;
    if (!resume) {
      await prefs.remove(_positionKey(track.id));
      return Duration.zero;
    }
    return Duration(seconds: savedSeconds);
  }

  Future<void> _saveCurrentTrackPosition() async {
    final track = _selectedTrack;
    final audioService = _audioService;
    if (track == null || audioService == null) return;

    final position = audioService.currentPosition;
    final duration = audioService.totalDuration;
    final currentSecond = position.inSeconds;
    if (currentSecond == _lastSavedSecond) return;
    if (currentSecond < 3) return;

    _lastSavedSecond = currentSecond;
    final prefs = await SharedPreferences.getInstance();
    final key = _positionKey(track.id);
    if (duration.inSeconds > 0 && currentSecond >= duration.inSeconds - 3) {
      await prefs.remove(key);
    } else {
      await prefs.setInt(key, currentSecond);
    }
  }

  String _positionKey(String trackId) => 'ramadan_track_position_$trackId';

  void _seekBy(AudioService audioService, int seconds) {
    final next = audioService.currentPosition + Duration(seconds: seconds);
    final clamped = next < Duration.zero
        ? Duration.zero
        : audioService.totalDuration > Duration.zero &&
              next > audioService.totalDuration
        ? audioService.totalDuration
        : next;
    audioService.seek(clamped);
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'dua':
        return Colors.teal;
      case 'tahajjud':
        return Colors.deepPurpleAccent;
      default:
        return primaryGold;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'dua':
        return Icons.volunteer_activism_rounded;
      case 'tahajjud':
        return Icons.nightlight_round;
      default:
        return Icons.mosque_rounded;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

class RamadanNight {
  final int day;
  final String label;
  final List<RamadanTrack> items;

  const RamadanNight({
    required this.day,
    required this.label,
    required this.items,
  });

  factory RamadanNight.fromJson(Map<String, dynamic> json) {
    final items = json['items'] as List<dynamic>? ?? const [];
    return RamadanNight(
      day: json['day'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      items: items
          .map((item) => RamadanTrack.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class RamadanTrack {
  final String id;
  final String type;
  final String typeLabel;
  final String title;
  final String url;
  final String transcript;

  const RamadanTrack({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.url,
    required this.transcript,
  });

  factory RamadanTrack.fromJson(Map<String, dynamic> json) {
    return RamadanTrack(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      typeLabel: json['typeLabel'] as String? ?? '',
      title: json['title'] as String? ?? '',
      url: json['url'] as String? ?? '',
      transcript: json['transcript'] as String? ?? '',
    );
  }
}
