import 'package:flutter/material.dart';
import '../models/shared_video.dart';
import 'video_detail_screen.dart';
import 'video_upload_screen.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({Key? key}) : super(key: key);

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  late final List<SharedVideo> _videos;

  @override
  void initState() {
    super.initState();
    _videos = _buildVideoFeed();
  }

  List<SharedVideo> _buildVideoFeed() {
    return [
      SharedVideo(
        id: 'v001',
        title: 'Drip Irrigation Setup for Small Farms',
        description:
            'Step-by-step irrigation planning for water-efficient vegetable plots.',
        category: 'Irrigation',
        uploader: 'Agri Pro Academy',
        uploadedAt: DateTime.now().subtract(const Duration(hours: 5)),
        thumbnailUrl: 'https://picsum.photos/seed/drip-irrigation/800/450',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
        duration: '12:34',
        views: 18230,
        likes: 420,
        shares: 38,
        isFeatured: true,
      ),
      SharedVideo(
        id: 'v002',
        title: 'Natural Pest Control Using Neem Spray',
        description:
            'Learn how to make an organic neem pest spray for safe crop protection.',
        category: 'Pest Control',
        uploader: 'Farmers Voice',
        uploadedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        thumbnailUrl: 'https://picsum.photos/seed/neem-pest/800/450',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4',
        duration: '09:20',
        views: 12340,
        likes: 285,
        shares: 24,
      ),
      SharedVideo(
        id: 'v003',
        title: 'High-Yield Wheat Planting Techniques',
        description:
            'Best practices for seedbed preparation and spacing to increase wheat yields.',
        category: 'Crop Management',
        uploader: 'Harvest Hub',
        uploadedAt: DateTime.now().subtract(const Duration(days: 2, hours: 4)),
        thumbnailUrl: 'https://picsum.photos/seed/wheat-planting/800/450',
        videoUrl:
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4',
        duration: '15:05',
        views: 21800,
        likes: 512,
        shares: 64,
      ),
    ];
  }

  Widget _buildHeroCard(SharedVideo video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoDetailScreen(video: video)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [Color(0xFF22C55E), Color(0xFF3B82F6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Image.network(
                video.thumbnailUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 220,
                    width: double.infinity,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.broken_image,
                      color: Color(0xFF9CA3AF),
                      size: 48,
                    ),
                  );
                },
              ),
              Container(
                height: 220,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.55),
                      Colors.transparent
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                bottom: 18,
                left: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        video.category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          video.duration,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.remove_red_eye,
                            color: Colors.white70, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${video.views} views',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVideoCard(SharedVideo video) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VideoDetailScreen(video: video)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(18)),
              child: Image.network(
                video.thumbnailUrl,
                height: 170,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 170,
                    width: double.infinity,
                    color: const Color(0xFFE5E7EB),
                    child: const Icon(
                      Icons.broken_image,
                      color: Color(0xFF9CA3AF),
                      size: 40,
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    video.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: Color(0xFF475569), fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.person_outline,
                          size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        video.uploader,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      const SizedBox(width: 18),
                      const Icon(Icons.access_time,
                          size: 16, color: Color(0xFF6B7280)),
                      const SizedBox(width: 6),
                      Text(
                        video.duration,
                        style: const TextStyle(
                            color: Color(0xFF6B7280), fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea Share'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Material(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              elevation: 2,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final result = await Navigator.push<SharedVideo?>(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VideoUploadScreen()),
                  );
                  if (result != null) {
                    setState(() {
                      _videos.insert(0, result);
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: const [
                      Icon(Icons.cloud_upload_outlined,
                          size: 28, color: Color(0xFF22C55E)),
                      SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload an idea video',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Share what you know with the agriculture community',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios,
                          size: 18, color: Color(0xFF6B7280)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _buildHeroCard(_videos.first),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'Recommended ideas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ..._videos.skip(1).map(_buildVideoCard),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
