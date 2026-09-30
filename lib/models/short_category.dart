class ShortCategory {
  final int id;
  final String name;
  final String? iconUrl;
  final int order;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int shortsCount;

  ShortCategory({
    required this.id,
    required this.name,
    this.iconUrl,
    this.order = 0,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
    this.shortsCount = 0,
  });

  factory ShortCategory.fromJson(Map<String, dynamic> json) {
    return ShortCategory(
      id: json['id'] as int,
      name: json['name'] as String,
      iconUrl: json['iconUrl'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      shortsCount: json['shortsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'iconUrl': iconUrl,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'shortsCount': shortsCount,
    };
  }
}
