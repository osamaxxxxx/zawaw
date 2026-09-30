import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Stores recently watched short videos for faster repeat playback.
class ShortsVideoCacheService {
  ShortsVideoCacheService._();

  static final ShortsVideoCacheService _instance = ShortsVideoCacheService._();

  factory ShortsVideoCacheService() => _instance;

  static const int _maxCacheBytes = 250 * 1024 * 1024;
  final Map<String, Future<void>> _pendingDownloads = <String, Future<void>>{};

  Future<File?> getCachedFile(String videoUrl) async {
    final file = await _fileForUrl(videoUrl);
    if (!await file.exists() || await file.length() == 0) return null;

    await file.setLastModified(DateTime.now());
    return file;
  }

  Future<void> cacheVideo(String videoUrl) async {
    if (await getCachedFile(videoUrl) != null) return;

    final pending = _pendingDownloads[videoUrl];
    if (pending != null) return pending;

    final download = _download(videoUrl);
    _pendingDownloads[videoUrl] = download;
    try {
      await download;
    } finally {
      _pendingDownloads.remove(videoUrl);
    }
  }

  Future<void> clearCache() async {
    final directory = await _cacheDirectory();
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  Future<void> _download(String videoUrl) async {
    final target = await _fileForUrl(videoUrl);
    final temporary = File('${target.path}.part');
    HttpClient? client;
    IOSink? sink;

    try {
      await target.parent.create(recursive: true);
      client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
      final request = await client.getUrl(Uri.parse(videoUrl));
      final response = await request.close();

      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Unexpected status code: ${response.statusCode}');
      }

      sink = temporary.openWrite();
      await response.pipe(sink);
      sink = null;

      if (await target.exists()) await target.delete();
      await temporary.rename(target.path);
      await _enforceCacheLimit(excluding: target.path);
    } catch (error) {
      debugPrint('Unable to cache short video: $error');
      if (await temporary.exists()) await temporary.delete();
    } finally {
      await sink?.close();
      client?.close(force: true);
    }
  }

  Future<File> _fileForUrl(String videoUrl) async {
    final directory = await _cacheDirectory();
    return File('${directory.path}${Platform.pathSeparator}${_urlHash(videoUrl)}.mp4');
  }

  Future<Directory> _cacheDirectory() async {
    final root = await getApplicationSupportDirectory();
    return Directory('${root.path}${Platform.pathSeparator}shorts_video_cache');
  }

  Future<void> _enforceCacheLimit({required String excluding}) async {
    final directory = await _cacheDirectory();
    if (!await directory.exists()) return;

    final files = <File>[];
    await for (final entity in directory.list()) {
      if (entity is File && entity.path.endsWith('.mp4')) files.add(entity);
    }

    var totalBytes = 0;
    final metadata = <FileSystemEntity, FileStat>{};
    for (final file in files) {
      final stat = await file.stat();
      metadata[file] = stat;
      totalBytes += stat.size;
    }

    files.sort((a, b) => metadata[a]!.modified.compareTo(metadata[b]!.modified));
    for (final file in files) {
      if (totalBytes <= _maxCacheBytes) break;
      if (file.path == excluding) continue;
      totalBytes -= metadata[file]!.size;
      await file.delete();
    }
  }

  String _urlHash(String value) {
    var hash = 0xcbf29ce484222325;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x100000001b3) & 0xffffffffffffffff;
    }
    return hash.toRadixString(16).padLeft(16, '0');
  }
}
