import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants/surah_audio_mapping.dart';
import '../core/utils/shared_prefs_helper.dart';

class AudioService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _quranPlaybackSpeed = 1.0;
  double _ramadanPlaybackSpeed = 1.0;

  int? _currentSurahId;
  String? _currentSurahName;
  String? _currentTrackId;
  String? _currentTrackTitle;
  String? _currentTrackAlbum;
  bool _shouldPersistSurahPosition = true;
  bool _isLoading = false;
  String? _errorMessage;
  static const Duration _audioLoadTimeout = Duration(seconds: 15);

  // Getters
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed {
    if (_currentSurahId != null) {
      return _quranPlaybackSpeed;
    }
    return _ramadanPlaybackSpeed;
  }

  double get quranPlaybackSpeed => _quranPlaybackSpeed;
  double get ramadanPlaybackSpeed => _ramadanPlaybackSpeed;
  int? get currentSurahId => _currentSurahId;
  String? get currentSurahName => _currentSurahName;
  String? get currentTrackId => _currentTrackId;
  String? get currentTrackTitle => _currentTrackTitle;
  String? get currentTrackAlbum => _currentTrackAlbum;
  bool get shouldPersistSurahPosition => _shouldPersistSurahPosition;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AudioPlayer get player => _audioPlayer;

  AudioService() {
    _initStreams();
  }

  void _initStreams() {
    _audioPlayer.playerStateStream.listen(
      (state) {
        final oldPlaying = _isPlaying;
        _isPlaying = state.playing;

        // If we transitioned from playing to paused, save current position
        if (oldPlaying &&
            !_isPlaying &&
            state.processingState != ProcessingState.completed) {
          if (_shouldPersistSurahPosition &&
              _currentSurahId != null &&
              _currentPosition.inSeconds > 0) {
            SharedPrefsHelper.saveSurahPosition(
              _currentSurahId!,
              _currentPosition.inSeconds,
            );
          }
        }

        // If playback completed naturally, clear any saved position for this surah
        if (state.processingState == ProcessingState.completed) {
          if (_shouldPersistSurahPosition && _currentSurahId != null) {
            SharedPrefsHelper.clearSurahPosition(_currentSurahId!);
          }
          _currentSurahId = null;
          _currentSurahName = null;
          _currentTrackId = null;
          _currentTrackTitle = null;
          _currentTrackAlbum = null;
        }
        notifyListeners();
      },
      onError: (e) {
        _errorMessage = _friendlyAudioErrorMessage(e);
        notifyListeners();
      },
    );

    _audioPlayer.positionStream.listen((position) {
      // Listeners only display whole seconds, so skip sub-second rebuilds.
      final secondChanged = position.inSeconds != _currentPosition.inSeconds;
      _currentPosition = position;
      if (secondChanged) notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });

    // Listen to buffering/loading states
    _audioPlayer.processingStateStream.listen((state) {
      _isLoading =
          state == ProcessingState.loading ||
          state == ProcessingState.buffering;
      notifyListeners();
    });

    _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object e, StackTrace stackTrace) {
        _isLoading = false;
        _errorMessage = _friendlyAudioErrorMessage(e);
        notifyListeners();
      },
    );
  }

  AudioSource _audioSource({required String url, required MediaItem tag}) {
    return AudioSource.uri(Uri.parse(url), tag: tag);
  }

  Future<void> _setAudioSourceWithTimeout(
    AudioSource audioSource, {
    required Duration initialPosition,
  }) {
    return _audioPlayer
        .setAudioSource(audioSource, initialPosition: initialPosition)
        .timeout(_audioLoadTimeout);
  }

  String _friendlyAudioErrorMessage(Object error) {
    if (error is TimeoutException) {
      return 'تعذر تحميل الصوت. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
    }

    final message = error.toString().toLowerCase();
    if (message.contains('network') ||
        message.contains('internet') ||
        message.contains('connection') ||
        message.contains('connection refused') ||
        message.contains('connection reset') ||
        message.contains('failed host lookup') ||
        message.contains('host lookup') ||
        message.contains('socket') ||
        message.contains('timed out') ||
        message.contains('timeout') ||
        message.contains('source error') ||
        message.contains('404') ||
        message.contains('403')) {
      return 'تعذر تحميل الصوت. يرجى التحقق من اتصالك بالإنترنت والمحاولة مرة أخرى.';
    }

    return 'حدث خطأ أثناء تشغيل الصوت. حاول مرة أخرى بعد قليل.';
  }

  /// Start playing a Surah by its ID, with an optional starting position (for resuming)
  Future<void> playSurah(
    int surahId, {
    Duration startPosition = Duration.zero,
  }) async {
    // Save progress of the previous Surah before loading the new one
    if (_shouldPersistSurahPosition &&
        _currentSurahId != null &&
        _currentSurahId != surahId &&
        _currentPosition.inSeconds > 0) {
      await SharedPrefsHelper.saveSurahPosition(
        _currentSurahId!,
        _currentPosition.inSeconds,
      );
    }

    final remoteAudioUrl = SurahAudioMapping.surahAudioUrls[surahId];
    final surahName = SurahAudioMapping.surahNames[surahId] ?? 'سورة $surahId';

    if (remoteAudioUrl == null || remoteAudioUrl.isEmpty) {
      _errorMessage = 'عذراً، تلاوة هذه السورة غير متوفرة حالياً';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _currentSurahId = surahId;
    _currentSurahName = surahName;
    _currentTrackId = null;
    _currentTrackTitle = null;
    _currentTrackAlbum = null;
    _shouldPersistSurahPosition = true;
    notifyListeners();

    try {
      final audioSource = _audioSource(
        url: await _bestAudioUrl(surahId, remoteAudioUrl),
        tag: MediaItem(
          id: 'surah_$surahId',
          album: 'تلاوات الشيخ عبدالرحمن الزواوي',
          title: 'سورة $surahName',
          artUri: Uri.parse(
            'https://res.cloudinary.com/dmjtwwiue/image/upload/v1/default_art.png',
          ),
        ),
      );

      // Set the audio source with initial position if needed
      await _setAudioSourceWithTimeout(
        audioSource,
        initialPosition: startPosition,
      );
      await _audioPlayer.setSpeed(_quranPlaybackSpeed);
      await _audioPlayer.play();

      // Save last played surah ID in SharedPreferences
      await SharedPrefsHelper.saveLastPlayedSurahId(surahId);
    } catch (e) {
      _errorMessage = _friendlyAudioErrorMessage(e);
      debugPrint("Error loading Surah audio: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _bestAudioUrl(int surahId, String remoteUrl) async {
    final documents = await getApplicationDocumentsDirectory();
    final downloaded = File(
      '${documents.path}${Platform.pathSeparator}recitations${Platform.pathSeparator}surah_$surahId.mp3',
    );
    return await downloaded.exists() ? downloaded.uri.toString() : remoteUrl;
  }

  /// Load audio from an online URL (e.g., Ramadan track or individual Ayah playback)
  Future<void> loadAudio(
    String url, {
    required String id,
    required String title,
    required String album,
    Duration startPosition = Duration.zero,
  }) async {
    // Save progress of the previous Surah before loading individual Ayah audio
    if (_shouldPersistSurahPosition &&
        _currentSurahId != null &&
        _currentPosition.inSeconds > 0) {
      await SharedPrefsHelper.saveSurahPosition(
        _currentSurahId!,
        _currentPosition.inSeconds,
      );
    }

    _isLoading = true;
    _errorMessage = null;
    // We clear Surah level metadata as this is an individual track playback
    _currentSurahId = null;
    _currentSurahName = null;
    _currentTrackId = id;
    _currentTrackTitle = title;
    _currentTrackAlbum = album;
    _shouldPersistSurahPosition = false;
    notifyListeners();

    try {
      final audioSource = _audioSource(
        url: await _bestTrackUrl(id, url),
        tag: MediaItem(
          id: id,
          album: album,
          title: title,
          artUri: Uri.parse(
            'https://res.cloudinary.com/dmjtwwiue/image/upload/v1/default_art.png',
          ),
        ),
      );

      await _setAudioSourceWithTimeout(
        audioSource,
        initialPosition: startPosition,
      );
      await _audioPlayer.setSpeed(_ramadanPlaybackSpeed);
      await _audioPlayer.play();
    } catch (e) {
      _errorMessage = _friendlyAudioErrorMessage(e);
      debugPrint("Error loading audio: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> _bestTrackUrl(String id, String remoteUrl) async {
    final documents = await getApplicationDocumentsDirectory();
    final downloaded = File(
      '${documents.path}${Platform.pathSeparator}recitations${Platform.pathSeparator}track_$id.mp3',
    );
    return await downloaded.exists() ? downloaded.uri.toString() : remoteUrl;
  }

  Future<void> play() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _audioPlayer.play().timeout(_audioLoadTimeout);
    } catch (e) {
      _errorMessage = _friendlyAudioErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void pause() => _audioPlayer.pause();

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  void stop() {
    _audioPlayer.stop();
    _currentSurahId = null;
    _currentSurahName = null;
    _currentTrackId = null;
    _currentTrackTitle = null;
    _currentTrackAlbum = null;
    _shouldPersistSurahPosition = true;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    notifyListeners();
  }

  void setSpeed(double speed) {
    if (_currentSurahId != null) {
      _quranPlaybackSpeed = speed;
    } else {
      _ramadanPlaybackSpeed = speed;
    }
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
