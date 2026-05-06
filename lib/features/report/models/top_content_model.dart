class TopContentModel {
  final String id;
  final String title;
  final String description;
  final String type;
  final String uploadDate;
  final String permalink;
  final int views;
  final int likes;
  final int comments;
  final int shares;
  final int score;

  TopContentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.uploadDate,
    required this.permalink,
    required this.views,
    required this.likes,
    required this.comments,
    required this.shares,
    required this.score,
  });

  factory TopContentModel.fromJson(Map<String, dynamic> json) {
    return TopContentModel(
      id: json['id']?.toString() ?? '',
      title:
          json['title']?.toString() ??
          json['caption']?.toString() ??
          'Untitled',
      description:
          json['description']?.toString() ?? json['caption']?.toString() ?? '',
      type: json['type']?.toString() ?? json['media_type']?.toString() ?? '',
      uploadDate:
          json['uploadDate']?.toString() ?? json['timestamp']?.toString() ?? '',
      permalink: json['permalink']?.toString() ?? '',
      views: json['views'] ?? 0,
      likes: json['likes'] ?? 0,
      comments: json['comments'] ?? 0,
      shares: json['shares'] ?? 0,
      score: json['score'] ?? 0,
    );
  }
}
