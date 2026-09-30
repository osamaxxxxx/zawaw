class ShortVideo {
  final int id;
  final int categoryId;
  final String? categoryName;
  final String title;
  final String videoUrl;
  final String? thumbnailUrl;
  final int viewsCount;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ShortVideo({
    required this.id,
    required this.categoryId,
    this.categoryName,
    required this.title,
    required this.videoUrl,
    this.thumbnailUrl,
    this.viewsCount = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ShortVideo.fromJson(Map<String, dynamic> json) {
    return ShortVideo(
      id: json['id'] as int,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String?,
      title: json['title'] as String,
      videoUrl: json['videoUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      viewsCount: json['viewsCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'title': title,
      'videoUrl': videoUrl,
      'thumbnailUrl': thumbnailUrl,
      'viewsCount': viewsCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
