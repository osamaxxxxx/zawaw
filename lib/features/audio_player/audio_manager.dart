import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioManager extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackSpeed = 1.0;

  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackSpeed => _playbackSpeed;
  AudioPlayer get player => _audioPlayer;

  AudioManager() {
    _initStreams();
  }

  void _initStreams() {
    _audioPlayer.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });

    _audioPlayer.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });

    _audioPlayer.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });
  }

  /// Load audio from an online URL and set background metadata
  Future<void> loadAudio(String url, {required String title, required String album}) async {
    try {
      final audioSource = AudioSource.uri(
        Uri.parse(url),
        tag: MediaItem(
          id: url, // Using URL as a unique ID for the item
          album: album,
          title: title,
          artUri: Uri.parse('https://example.com/default_art.png'), // Placeholder or load from Firebase
        ),
      );

      await _audioPlayer.setAudioSource(audioSource);
      _audioPlayer.play();
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  void play() => _audioPlayer.play();
  
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

  void setSpeed(double speed) {
    _playbackSpeed = speed;
    _audioPlayer.setSpeed(speed);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
