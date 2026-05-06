class DashboardModel {
  final int totalNewUsers;
  final int totalKawanssPosts;
  final int totalInfossPosts;
  final int totalInstagramPosts;
  final int totalInstagramUsers;
  final int totalComments;
  final int totalLikes;

  DashboardModel({
    required this.totalNewUsers,
    required this.totalKawanssPosts,
    required this.totalInfossPosts,
    required this.totalInstagramPosts,
    required this.totalInstagramUsers,
    required this.totalComments,
    required this.totalLikes,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      totalNewUsers: json['total_new_users'] ?? 0,
      totalKawanssPosts: json['total_kawanss_posts'] ?? 0,
      totalInfossPosts: json['total_infoss_posts'] ?? 0,
      totalInstagramPosts: json['total_instagram_posts'] ?? 0,
      totalInstagramUsers: json['total_instagram_users'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      totalLikes: json['total_likes'] ?? 0,
    );
  }
}
