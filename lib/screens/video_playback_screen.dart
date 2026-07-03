import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/shared_video.dart';

class VideoPlaybackScreen extends StatefulWidget {
  final SharedVideo video;
  const VideoPlaybackScreen({required this.video, Key? key}) : super(key: key);

  @override
  State<VideoPlaybackScreen> createState() => _VideoPlaybackScreenState();
}

class _VideoPlaybackScreenState extends State<VideoPlaybackScreen> {
  late final VideoPlayerController _controller;
  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
          ..initialize().then((_) {
            setState(() {
              _isReady = true;
            });
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Player'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isReady)
            AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            )
          else
            const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.video.title,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(widget.video.description),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Chip(label: Text(widget.video.category)),
                    const SizedBox(width: 10),
                    Chip(label: Text(widget.video.uploader)),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: Icon(_controller.value.isPlaying
                      ? Icons.pause
                      : Icons.play_arrow),
                  label: Text(_controller.value.isPlaying ? 'Pause' : 'Play'),
                  onPressed: _isReady
                      ? () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
