class HashtagModel {
  final String hashtag;
  final int totalPosts;
  final int totalLikes;
  final int totalComments;

  HashtagModel({
    required this.hashtag,
    required this.totalPosts,
    required this.totalLikes,
    required this.totalComments,
  });

  factory HashtagModel.fromJson(Map<String, dynamic> json) {
    return HashtagModel(
      hashtag: json['hashtag']?.toString() ?? '',
      totalPosts: json['total_posts'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
    );
  }
}
