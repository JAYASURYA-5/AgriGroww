import 'package:flutter/material.dart';
import '../models/shared_video.dart';
import 'video_playback_screen.dart';

class VideoDetailScreen extends StatefulWidget {
  final SharedVideo video;
  const VideoDetailScreen({Key? key, required this.video}) : super(key: key);

  @override
  State<VideoDetailScreen> createState() => _VideoDetailScreenState();
}

class _VideoDetailScreenState extends State<VideoDetailScreen> {
  late SharedVideo _video;

  @override
  void initState() {
    super.initState();
    _video = widget.video;
  }

  void _toggleLike() {
    setState(() {
      _video.likes += 1;
    });
  }

  void _shareVideo() {
    setState(() {
      _video.shares += 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video share link copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Watch Idea'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => VideoPlaybackScreen(video: _video),
                  ),
                );
              },
              child: Stack(
                children: [
                  Image.network(
                    _video.thumbnailUrl,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 240,
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
                    height: 240,
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
                    child: Row(
                      children: const [
                        Icon(Icons.play_circle_fill,
                            color: Colors.white, size: 40),
                        SizedBox(width: 10),
                        Text(
                          'Watch now',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _video.title,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _video.description,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Chip(label: Text(_video.category)),
                      const SizedBox(width: 10),
                      Chip(label: Text(_video.uploader)),
                      const SizedBox(width: 10),
                      Chip(label: Text(_video.duration)),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleLike,
                        icon: const Icon(Icons.thumb_up_alt_outlined),
                        label: Text('Like ${_video.likes}'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF22C55E),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: _shareVideo,
                        icon: const Icon(Icons.share_outlined),
                        label: Text('Share ${_video.shares}'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF1F2937),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Idea details',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDetailRow('Views', '${_video.views}'),
                  _buildDetailRow('Published',
                      '${_video.uploadedAt.toLocal().toString().split('.').first}'),
                  _buildDetailRow('Category', _video.category),
                  const SizedBox(height: 20),
                  const Text(
                    'About this idea',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Share practical farming tips, demonstration videos, and tutorial content with the community. This feed is designed for idea exchange, peer learning, and professional agriculture knowledge sharing.',
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 14, height: 1.6),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
