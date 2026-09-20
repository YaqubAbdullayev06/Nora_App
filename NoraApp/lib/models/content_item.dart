/// Content item model for feed and content management.
class ContentItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String contentType;
  final int durationMinutes;
  final int points;
  final List<String> tags;
  final String? imageUrl;
  final String? author;
  final String? takeaway;
  final List<String> keyPoints;

  const ContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.contentType,
    required this.durationMinutes,
    required this.points,
    this.tags = const [],
    this.imageUrl,
    this.author,
    this.takeaway,
    this.keyPoints = const [],
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) {
    return ContentItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      contentType: json['content_type'] ?? json['contentType'] ?? 'article',
      durationMinutes: json['duration_minutes'] ?? json['durationMinutes'] ?? 0,
      points: json['points'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      author: json['author'],
      takeaway: json['takeaway'],
      keyPoints: List<String>.from(json['keyPoints'] ?? json['key_points'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'contentType': contentType,
      'durationMinutes': durationMinutes,
      'points': points,
      'tags': tags,
      'imageUrl': imageUrl,
      'author': author,
      'takeaway': takeaway,
      'keyPoints': keyPoints,
    };
  }
}
