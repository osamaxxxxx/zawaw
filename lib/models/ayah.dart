class Ayah {
  final int id;
  final int surahId;
  final int ayahNumber;
  final String textUthmani;
  final int pageNumber;

  Ayah({
    required this.id,
    required this.surahId,
    required this.ayahNumber,
    required this.textUthmani,
    required this.pageNumber,
  });

  factory Ayah.fromJson(Map<String, dynamic> json) {
    return Ayah(
      id: json['id'],
      surahId: json['surahId'],
      ayahNumber: json['ayahNumber'],
      textUthmani: json['textUthmani'],
      pageNumber: json['pageNumber'] ?? 0,
    );
  }
}
