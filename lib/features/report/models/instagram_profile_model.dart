class InstagramProfileModel {
  final String id;
  final String username;
  final String name;
  final String biography;
  final int followersCount;
  final int followsCount;
  final int mediaCount;
  final String profilePictureUrl;

  InstagramProfileModel({
    required this.id,
    required this.username,
    required this.name,
    required this.biography,
    required this.followersCount,
    required this.followsCount,
    required this.mediaCount,
    required this.profilePictureUrl,
  });

  factory InstagramProfileModel.fromJson(Map<String, dynamic> json) {
    return InstagramProfileModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      biography: json['biography'] ?? '',
      followersCount: json['followers_count'] ?? 0,
      followsCount: json['follows_count'] ?? 0,
      mediaCount: json['media_count'] ?? 0,
      profilePictureUrl: json['profile_picture_url'] ?? '',
    );
  }
}
