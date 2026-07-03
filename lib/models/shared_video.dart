class SharedVideo {
  final String id;
  final String title;
  final String description;
  final String category;
  final String uploader;
  final DateTime uploadedAt;
  final String thumbnailUrl;
  final String videoUrl;
  final String duration;
  final int views;
  int likes;
  int shares;
  bool isFeatured;

  SharedVideo({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.uploader,
    required this.uploadedAt,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.duration,
    required this.views,
    this.likes = 0,
    this.shares = 0,
    this.isFeatured = false,
  });
}
