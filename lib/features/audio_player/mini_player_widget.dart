import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/audio_service.dart';
import '../../core/utils/shared_prefs_helper.dart';

class MiniPlayerWidget extends StatelessWidget {
  const MiniPlayerWidget({super.key});

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final surahId = audioService.currentSurahId;
        final surahName = audioService.currentSurahName;
        final trackTitle = audioService.currentTrackTitle;
        final trackAlbum = audioService.currentTrackAlbum;
        final statusMessage =
            audioService.errorMessage ??
            (audioService.isLoading ? 'جار تحميل الصوت...' : null);

        // Display mini player if EITHER a Surah is active OR a Ramadan track is active!
        if ((surahId == null || surahName == null) && trackTitle == null) {
          return const SizedBox.shrink();
        }

        final isSurah = surahId != null;
        final title = isSurah ? 'سورة $surahName' : trackTitle;
        final subtitle = isSurah
            ? 'الشيخ عبدالرحمن الزواوي'
            : (trackAlbum ?? 'رمضان 2026');

        const primaryGold = Color(0xFFD4AF37);
        const darkGreen = Color(0xFF1B4332);
        final playerBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;

        // Calculate slider values
        double currentVal = audioService.currentPosition.inSeconds.toDouble();
        double totalVal = audioService.totalDuration.inSeconds.toDouble();

        // Safety checks for slider
        if (currentVal < 0) currentVal = 0;
        if (totalVal <= 0) totalVal = 1;
        if (currentVal > totalVal) currentVal = totalVal;

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            decoration: BoxDecoration(
              color: playerBg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
              border: Border(
                top: BorderSide(
                  color: primaryGold.withValues(alpha: 0.5),
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Thin but visible Slider at the top of mini player
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5.0, // Thicker and more visible progress bar!
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 7.0,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14.0,
                    ),
                    activeTrackColor: primaryGold,
                    inactiveTrackColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[300],
                    thumbColor: primaryGold,
                    overlayColor: primaryGold.withValues(alpha: 0.2),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: totalVal,
                    value: currentVal,
                    onChanged: (val) {
                      audioService.seek(Duration(seconds: val.toInt()));
                    },
                  ),
                ),

                // Controls Row
                Padding(
                  padding: const EdgeInsets.only(
                    left: 12.0,
                    right: 12.0,
                    bottom: 8.0,
                    top: 4.0,
                  ),
                  child: Row(
                    children: [
                      // Right Side: Icon & Title/Subtitle details
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryGold.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isSurah ? Icons.menu_book : Icons.music_note,
                          color: primaryGold,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title ?? '',
                              style: GoogleFonts.cairo(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : darkGreen,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              subtitle,
                              style: GoogleFonts.cairo(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (statusMessage != null)
                              Text(
                                statusMessage,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: audioService.errorMessage != null
                                      ? Colors.redAccent
                                      : primaryGold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),

                      // Center: Playback controls (Speed, Seek -10s, Play/Pause, Seek +10s)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Playback Speed Toggle
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              final currentSpeed = audioService.playbackSpeed;
                              final nextSpeed = currentSpeed == 1.0
                                  ? 1.25
                                  : currentSpeed == 1.25
                                  ? 1.5
                                  : currentSpeed == 1.5
                                  ? 0.75
                                  : 1.0;
                              audioService.setSpeed(nextSpeed);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: primaryGold.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${audioService.playbackSpeed}x',
                                style: GoogleFonts.cairo(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: primaryGold,
                                ),
                              ),
                            ),
                          ),

                          // Skip forward 10s
                          IconButton(
                            icon: const Icon(
                              Icons.replay_10,
                              color: primaryGold,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              final nextPos =
                                  audioService.currentPosition +
                                  const Duration(seconds: 10);
                              audioService.seek(
                                audioService.totalDuration > Duration.zero &&
                                        nextPos > audioService.totalDuration
                                    ? audioService.totalDuration
                                    : nextPos,
                              );
                            },
                            tooltip: 'تقديم 10 ثوانٍ',
                          ),

                          // Play / Pause Button with Buffering State
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6.0),
                            child: audioService.isLoading
                                ? const SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: Padding(
                                      padding: EdgeInsets.all(6.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              primaryGold,
                                            ),
                                      ),
                                    ),
                                  )
                                : IconButton(
                                    icon: Icon(
                                      audioService.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_filled,
                                      color: primaryGold,
                                      size: 32,
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () {
                                      audioService.togglePlayPause();
                                    },
                                  ),
                          ),

                          // Skip backward 10s
                          IconButton(
                            icon: const Icon(
                              Icons.forward_10,
                              color: primaryGold,
                              size: 20,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              final nextPos =
                                  audioService.currentPosition -
                                  const Duration(seconds: 10);
                              audioService.seek(
                                nextPos < Duration.zero
                                    ? Duration.zero
                                    : nextPos,
                              );
                            },
                            tooltip: 'تأخير 10 ثوانٍ',
                          ),
                        ],
                      ),
                      const SizedBox(width: 6),

                      // Left Side: Duration Text & Close Button
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_formatDuration(audioService.currentPosition)} / ${_formatDuration(audioService.totalDuration)}',
                            style: GoogleFonts.cairo(
                              fontSize: 9,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                              size: 18,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final isSurahActive =
                                  audioService.currentSurahId != null;
                              final activeId = audioService.currentSurahId;
                              final activeTrackId = audioService.currentTrackId;
                              final positionSec =
                                  audioService.currentPosition.inSeconds;
                              final shouldPersist =
                                  audioService.shouldPersistSurahPosition;

                              if (isSurahActive &&
                                  activeId != null &&
                                  shouldPersist) {
                                await SharedPrefsHelper.saveSurahPosition(
                                  activeId,
                                  positionSec,
                                );
                              } else if (activeTrackId != null) {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                await prefs.setInt(
                                  'ramadan_track_position_$activeTrackId',
                                  positionSec,
                                );
                              }

                              audioService.stop();

                              if (context.mounted &&
                                  isSurahActive &&
                                  shouldPersist) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'تم حفظ موضع التوقف تلقائياً',
                                      style: GoogleFonts.cairo(),
                                    ),
                                    backgroundColor: primaryGold,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
