import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/surah_audio_mapping.dart';

/// Keeps recitations in the app's private storage for offline listening.
class SurahDownloadService extends ChangeNotifier {
  final Set<int> _downloading = <int>{};
  final Set<int> _downloaded = <int>{};
  final Map<int, double> _surahProgress = <int, double>{};
  final Map<String, double> _trackProgress = <String, double>{};
  bool _isReady = false;
  final Map<String, DownloadedTrack> _tracks = <String, DownloadedTrack>{};

  bool isDownloading(int surahId) => _downloading.contains(surahId);
  bool isDownloaded(int surahId) => _downloaded.contains(surahId);
  double getSurahProgress(int surahId) => _surahProgress[surahId] ?? 0.0;

  bool isTrackDownloaded(String id) => _tracks.containsKey(id);
  bool isTrackDownloading(String id) => _downloading.contains(id.hashCode);
  double getTrackProgress(String id) => _trackProgress[id] ?? 0.0;
  List<DownloadedTrack> get downloadedTracks => _tracks.values.toList();

  Future<void> initialize() async {
    if (_isReady) return;
    final directory = await _downloadsDirectory();
    if (await directory.exists()) {
      await for (final entity in directory.list()) {
        final name = entity.path.split(Platform.pathSeparator).last;
        final match = RegExp(r'^surah_(\d+)\.mp3$').firstMatch(name);
        if (match != null) _downloaded.add(int.parse(match.group(1)!));
      }
    }
    _isReady = true;
    final rawTracks = (await SharedPreferences.getInstance()).getStringList('downloaded_ramadan_tracks') ?? const [];
    for (final raw in rawTracks) {
      final parts = raw.split('|');
      if (parts.length == 3) _tracks[parts[0]] = DownloadedTrack(id: parts[0], title: parts[1], url: parts[2]);
    }
    notifyListeners();
  }

  Future<void> _resilientDownload({
    required String url,
    required File targetFile,
    required void Function(double progress) onProgress,
  }) async {
    final temporary = File('${targetFile.path}.part');
    await targetFile.parent.create(recursive: true);

    const int maxRetries = 8;
    int retryCount = 0;
    int totalBytes = -1;

    while (true) {
      HttpClient? client;
      IOSink? sink;
      try {
        final existingBytes = temporary.existsSync() ? temporary.lengthSync() : 0;
        if (totalBytes > 0 && existingBytes >= totalBytes) {
          break;
        }

        client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 25);
        client.idleTimeout = const Duration(seconds: 35);

        final request = await client.getUrl(Uri.parse(url));
        request.headers.add(HttpHeaders.acceptEncodingHeader, 'identity');

        if (existingBytes > 0) {
          request.headers.add(HttpHeaders.rangeHeader, 'bytes=$existingBytes-');
        }

        final response = await request.close();

        if (response.statusCode == HttpStatus.partialContent) {
          final contentRange = response.headers.value(HttpHeaders.contentRangeHeader);
          if (contentRange != null) {
            final match = RegExp(r'/(\d+)$').firstMatch(contentRange);
            if (match != null) {
              totalBytes = int.parse(match.group(1)!);
            }
          }
          if (totalBytes <= 0 && response.contentLength > 0) {
            totalBytes = existingBytes + response.contentLength;
          }
          sink = temporary.openWrite(mode: FileMode.append);
        } else if (response.statusCode == HttpStatus.ok) {
          totalBytes = response.contentLength;
          sink = temporary.openWrite(mode: FileMode.write);
        } else if (response.statusCode == HttpStatus.requestedRangeNotSatisfiable) {
          if (totalBytes > 0 && existingBytes >= totalBytes) {
            break;
          }
          if (temporary.existsSync()) await temporary.delete();
          retryCount++;
          continue;
        } else {
          throw HttpException('HTTP error ${response.statusCode}');
        }

        int receivedSoFar = temporary.existsSync() ? temporary.lengthSync() : 0;
        if (totalBytes > 0) {
          onProgress((receivedSoFar / totalBytes).clamp(0.0, 1.0));
        }

        DateTime lastUpdate = DateTime.now();
        await for (final chunk in response) {
          sink.add(chunk);
          receivedSoFar += chunk.length;
          final now = DateTime.now();
          if (totalBytes > 0 && now.difference(lastUpdate).inMilliseconds >= 250) {
            lastUpdate = now;
            onProgress((receivedSoFar / totalBytes).clamp(0.0, 1.0));
          }
        }

        await sink.flush();
        await sink.close();
        sink = null;

        final finalSize = temporary.existsSync() ? temporary.lengthSync() : 0;
        if (totalBytes > 0 && finalSize < totalBytes) {
          throw HttpException('Connection closed prematurely ($finalSize of $totalBytes bytes)');
        }

        break;
      } catch (e) {
        retryCount++;
        debugPrint('Download error ($e). Attempt $retryCount/$maxRetries');
        try {
          await sink?.flush();
          await sink?.close();
        } catch (_) {}
        sink = null;

        if (retryCount > maxRetries) {
          throw const HttpException(
            'تعذر استكمال التحميل بعد عدة محاولات بسبب ضعف اتصال الإنترنت. يرجى المحاولة مرة أخرى وسيتم استكمال التحميل من حيث توقف.',
          );
        }

        final delay = Duration(milliseconds: (600 * retryCount).clamp(600, 4000));
        await Future.delayed(delay);
      } finally {
        client?.close(force: true);
      }
    }

    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    await temporary.rename(targetFile.path);
    onProgress(1.0);
  }

  Future<void> download(int surahId) async {
    if (_downloading.contains(surahId) || _downloaded.contains(surahId)) return;
    final url = SurahAudioMapping.surahAudioUrls[surahId];
    if (url == null || url.isEmpty) throw StateError('التلاوة غير متوفرة حالياً');

    _downloading.add(surahId);
    _surahProgress[surahId] = 0.0;
    notifyListeners();

    final target = File('${(await _downloadsDirectory()).path}${Platform.pathSeparator}surah_$surahId.mp3');
    try {
      await _resilientDownload(
        url: url,
        targetFile: target,
        onProgress: (p) {
          _surahProgress[surahId] = p;
          notifyListeners();
        },
      );
      _downloaded.add(surahId);
    } finally {
      _downloading.remove(surahId);
      _surahProgress.remove(surahId);
      notifyListeners();
    }
  }

  Future<void> remove(int surahId) async {
    final dir = await _downloadsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}surah_$surahId.mp3');
    final part = File('${file.path}.part');
    if (await file.exists()) await file.delete();
    if (await part.exists()) await part.delete();
    _downloaded.remove(surahId);
    _surahProgress.remove(surahId);
    notifyListeners();
  }

  Future<void> downloadTrack({required String id, required String title, required String url}) async {
    final trackHash = id.hashCode;
    if (isTrackDownloaded(id) || _downloading.contains(trackHash)) return;

    _downloading.add(trackHash);
    _trackProgress[id] = 0.0;
    notifyListeners();

    final target = File('${(await _downloadsDirectory()).path}${Platform.pathSeparator}track_$id.mp3');
    try {
      await _resilientDownload(
        url: url,
        targetFile: target,
        onProgress: (p) {
          _trackProgress[id] = p;
          notifyListeners();
        },
      );
      _tracks[id] = DownloadedTrack(id: id, title: title, url: url);
      await _saveTracks();
    } finally {
      _downloading.remove(trackHash);
      _trackProgress.remove(id);
      notifyListeners();
    }
  }

  Future<void> removeTrack(String id) async {
    final dir = await _downloadsDirectory();
    final file = File('${dir.path}${Platform.pathSeparator}track_$id.mp3');
    final part = File('${file.path}.part');
    if (await file.exists()) await file.delete();
    if (await part.exists()) await part.delete();
    _tracks.remove(id);
    _trackProgress.remove(id);
    await _saveTracks();
    notifyListeners();
  }

  Future<void> _saveTracks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('downloaded_ramadan_tracks', _tracks.values.map((track) => '${track.id}|${track.title}|${track.url}').toList());
  }

  Future<Directory> _downloadsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory('${root.path}${Platform.pathSeparator}recitations');
  }
}

class DownloadedTrack {
  final String id;
  final String title;
  final String url;
  const DownloadedTrack({required this.id, required this.title, required this.url});
}
