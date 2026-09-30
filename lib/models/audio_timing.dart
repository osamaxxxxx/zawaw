class AudioTiming {
  final int id;
  final int ayahId;
  final int reciterId;
  final String audioUrl;

  AudioTiming({
    required this.id,
    required this.ayahId,
    required this.reciterId,
    required this.audioUrl,
  });

  factory AudioTiming.fromJson(Map<String, dynamic> json) {
    return AudioTiming(
      id: json['id'],
      ayahId: json['ayahId'],
      reciterId: json['reciterId'],
      audioUrl: json['audioUrl'] ?? '',
    );
  }
}
