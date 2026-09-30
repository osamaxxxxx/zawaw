class Surah {
  final int id;
  final String nameArabic;
  final String nameEnglish;

  Surah({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
  });

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(
      id: json['id'],
      nameArabic: json['nameArabic'],
      nameEnglish: json['nameEnglish'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nameArabic': nameArabic,
      'nameEnglish': nameEnglish,
    };
  }
}
