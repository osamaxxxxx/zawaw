import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/surah_audio_mapping.dart';
import '../../services/audio_service.dart';
import '../../services/surah_download_service.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('التنزيلات')),
      body: Consumer<SurahDownloadService>(
        builder: (context, downloads, _) {
          final surahs = List.generate(
            114,
            (index) => index + 1,
          ).where(downloads.isDownloaded).toList();
          final tracks = downloads.downloadedTracks;
          if (surahs.isEmpty && tracks.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد تلاوات محمّلة بعد.\nاستخدم زر التنزيل بجانب أي سورة أو تسجيل.',
                textAlign: TextAlign.center,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (surahs.isNotEmpty) ...[
                const Text(
                  'السور المحمّلة',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...surahs.map(
                  (id) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.menu_book_rounded),
                      title: Text(
                        'سورة ${SurahAudioMapping.surahNames[id] ?? id}',
                      ),
                      subtitle: const Text('متاحة للاستماع دون إنترنت'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'حذف التنزيل',
                        onPressed: () => downloads.remove(id),
                      ),
                      onTap: () => context.read<AudioService>().playSurah(id),
                    ),
                  ),
                ),
              ],
              if (tracks.isNotEmpty) ...[
                const SizedBox(height: 18),
                const Text(
                  'تسجيلات رمضان والتراويح',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...tracks.map(
                  (track) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.nightlight_round),
                      title: Text(
                        track.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: const Text('متاح للاستماع دون إنترنت'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'حذف التنزيل',
                        onPressed: () => downloads.removeTrack(track.id),
                      ),
                      onTap: () => context.read<AudioService>().loadAudio(
                        track.url,
                        id: track.id,
                        title: track.title,
                        album: 'التنزيلات',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
