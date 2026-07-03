import 'dart:async';
import 'package:flutter/material.dart';

class Module {
  final String title;
  final String duration;
  final String description;
  final List<String> objectives;

  Module({
    required this.title,
    required this.duration,
    required this.description,
    required this.objectives,
  });
}

class Course {
  final String title;
  final String instructor;
  final String description;
  final double rating;
  final String students;
  final int modules;
  final String duration;
  final String level;
  final String category;
  final String imageUrl;
  final List<Module> modulesList;

  Course({
    required this.title,
    required this.instructor,
    required this.description,
    required this.rating,
    required this.students,
    required this.modules,
    required this.duration,
    required this.level,
    required this.category,
    required this.imageUrl,
    required this.modulesList,
  });
}

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final String? profileName;

  const CourseDetailScreen({
    Key? key,
    required this.course,
    this.profileName,
  }) : super(key: key);

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  int _activeModuleIndex = 0;
  final List<int> _completedModulesIndices = [];
  bool _isPlaying = false;
  Timer? _timer;

  // Video stats state
  int _currentSeconds = 0;
  int _totalSeconds = 40; // Default total seconds for active video simulation
  String _selectedQuality = '720p (Default)';
  bool _autoplayNext = true;
  int _likesCount = 0;
  int _dislikesCount = 0;
  bool _isLiked = false;
  bool _isDisliked = false;

  // Download simulation state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  Timer? _downloadTimer;

  @override
  void initState() {
    super.initState();
    if (widget.course.modulesList.isNotEmpty) {
      _totalSeconds = _parseDurationToSeconds(widget.course.modulesList[0].duration);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _downloadTimer?.cancel();
    super.dispose();
  }

  int _parseDurationToSeconds(String durationStr) {
    final cleaned = durationStr.replaceAll(RegExp(r'[^0-9]'), '');
    final val = int.tryParse(cleaned) ?? 20;
    return val * 2; // e.g. 20 min -> 40 seconds simulated
  }

  String _formatTime(int totalSecs) {
    final mins = totalSecs ~/ 60;
    final secs = totalSecs % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isPlaying) {
          timer.cancel();
          return;
        }

        setState(() {
          if (_currentSeconds < _totalSeconds) {
            _currentSeconds++;
          } else {
            // Finished playing video
            _isPlaying = false;
            _timer?.cancel();

            // Mark module as completed
            if (!_completedModulesIndices.contains(_activeModuleIndex)) {
              _completedModulesIndices.add(_activeModuleIndex);
            }

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Completed module: ${widget.course.modulesList[_activeModuleIndex].title}!'),
                backgroundColor: const Color(0xFF22C55E),
              ),
            );

            // Handle Autoplay next
            if (_autoplayNext && _activeModuleIndex + 1 < widget.course.modulesList.length) {
              _activeModuleIndex++;
              _currentSeconds = 0;
              _totalSeconds = _parseDurationToSeconds(widget.course.modulesList[_activeModuleIndex].duration);
              _togglePlayPause(); // Auto start next
            }
          }
        });
      });
    } else {
      _timer?.cancel();
    }
  }

  void _simulateDownload() {
    if (_isDownloading) return;
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    _downloadTimer = Timer.periodic(const Duration(milliseconds: 200), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_downloadProgress < 1.0) {
          _downloadProgress += 0.05;
        } else {
          _isDownloading = false;
          timer.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Course downloaded successfully for offline viewing!'),
              backgroundColor: Color(0xFF1E3A5F),
            ),
          );
        }
      });
    });
  }

  void _getCertificate() {
    final completedCount = _completedModulesIndices.length;
    final totalModules = widget.course.modulesList.length;

    if (completedCount < totalModules) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Certificate Locked 🔒'),
          content: Text(
            'You must complete all $totalModules modules to unlock your certificate. Currently, you have completed $completedCount modules.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final name = widget.profileName ?? "Farmer Partner";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD97706), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🎓 CERTIFICATE OF COMPLETION 🎓',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'This is proudly presented to',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                  color: Color(0xFF1E3A5F),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'for successfully completing the course\n"${widget.course.title}"',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 24),
              const Divider(color: Colors.grey),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'AgriGrow Academy',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  Text(
                    'Certified Partner',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706)),
                child: const Text('Download PDF'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = const Color(0xFF1E3A5F);
    final primaryGreen = const Color(0xFF22C55E);

    final totalModules = widget.course.modulesList.length;
    final completedCount = _completedModulesIndices.length;
    final progressPercent = totalModules > 0 ? (completedCount / totalModules) * 100 : 0.0;

    final activeModule = widget.course.modulesList.isNotEmpty
        ? widget.course.modulesList[_activeModuleIndex]
        : Module(title: "Empty Module", duration: "0 min", description: "", objectives: []);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. COURSE DETAIL HEADER
            Container(
              color: headerBg,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button
                  OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                    label: const Text(
                      'Back to Courses',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white38),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    widget.course.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'By ${widget.course.instructor}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text(
                        'Progress ${progressPercent.toInt()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          const Text(
                            'Rating ',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            widget.course.rating.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 2. PROGRESS BAR SECTION
            Container(
              padding: const EdgeInsets.all(20),
              color: const Color(0xFFEFF6FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progressPercent / 100,
                      color: primaryGreen,
                      backgroundColor: Colors.grey[200],
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$completedCount of $totalModules modules completed',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.video_library_outlined, color: Color(0xFF1E3A5F), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Videos watched: $completedCount of $totalModules (${progressPercent.toInt()}%)',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1E3A5F),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. COURSE MODULES LIST CARD
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📚', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          'Course Modules',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: headerBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // List of modules cards
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: widget.course.modulesList.length,
                      itemBuilder: (context, index) {
                        final mod = widget.course.modulesList[index];
                        final isActive = _activeModuleIndex == index;
                        final isCompleted = _completedModulesIndices.contains(index);

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _activeModuleIndex = index;
                              _isPlaying = false;
                              _timer?.cancel();
                              _currentSeconds = 0;
                              _totalSeconds = _parseDurationToSeconds(mod.duration);
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isActive ? headerBg : const Color(0xFFE2E8F0),
                                width: isActive ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: headerBg,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        mod.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.timer_outlined, color: Colors.purple, size: 14),
                                          const SizedBox(width: 4),
                                          Text(
                                            mod.duration,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          if (isCompleted) ...[
                                            const SizedBox(width: 12),
                                            const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 14),
                                            const SizedBox(width: 4),
                                            const Text(
                                              'Completed',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Color(0xFF22C55E),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Download Course Button
                    if (_isDownloading) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress,
                            color: headerBg,
                            backgroundColor: Colors.grey[200],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Downloading course... ${(_downloadProgress * 100).toInt()}%',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _simulateDownload,
                          icon: const Icon(Icons.download, color: Colors.black87),
                          label: const Text(
                            'Download Course',
                            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Get Certificate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _getCertificate,
                        icon: const Icon(Icons.card_membership, color: Colors.black87),
                        label: const Text(
                          'Get Certificate',
                          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFC59E), // Peach/orange
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. ACTIVE VIDEO PLAYER / DETAIL BLOCK
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mocked Video Frame / Thumbnail
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.course.imageUrl,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 200,
                                width: double.infinity,
                                color: headerBg,
                                child: const Icon(
                                  Icons.video_library,
                                  color: Colors.white,
                                  size: 48,
                                ),
                              );
                            },
                          ),
                        ),
                        // Dark overlay
                        Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        // Play/Pause circular button overlay
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isPlaying ? Icons.pause : Icons.play_arrow,
                              color: headerBg,
                              size: 36,
                            ),
                          ),
                        ),
                        // Video Duration Indicator
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${_formatTime(_currentSeconds)} / ${_formatTime(_totalSeconds)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Active Module Meta
                    Text(
                      activeModule.title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: headerBg,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(Icons.person, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          widget.course.instructor,
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.timer_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Duration: ${activeModule.duration}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.book_outlined, color: Colors.grey, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Module ${_activeModuleIndex + 1}',
                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // About This Module
                    const Text(
                      'About This Module',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activeModule.description.isNotEmpty
                          ? activeModule.description
                          : "This module covers important aspects of ${activeModule.title.toLowerCase()}. You'll learn practical techniques and best practices that you can apply directly to your farm.",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF475569),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // What You'll Learn
                    if (activeModule.objectives.isNotEmpty) ...[
                      const Text(
                        "What You'll Learn:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...activeModule.objectives.map((obj) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('• ', style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                            Expanded(
                              child: Text(
                                obj,
                                style: const TextStyle(fontSize: 14, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      )).toList(),
                      const SizedBox(height: 16),
                    ],

                    // Simulated Video Controls (Screenshot 4 format)
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Video Content:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Inner Player Video Controls Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  // Paused/Playing state badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          _isPlaying ? Icons.play_arrow : Icons.pause,
                                          size: 14,
                                          color: const Color(0xFFD97706),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _isPlaying ? 'Playing' : 'Paused',
                                          style: const TextStyle(
                                            color: Color(0xFFD97706),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                'Current: ${_formatTime(_currentSeconds)} / Total: ${_formatTime(_totalSeconds)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Seek slider
                          Slider(
                            value: _currentSeconds.toDouble(),
                            min: 0.0,
                            max: _totalSeconds.toDouble(),
                            activeColor: primaryGreen,
                            inactiveColor: Colors.grey[200],
                            onChanged: (val) {
                              setState(() {
                                _currentSeconds = val.toInt();
                              });
                            },
                          ),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${((_currentSeconds / _totalSeconds) * 100).toInt()}% watched',
                                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                              GestureDetector(
                                onTap: _togglePlayPause,
                                child: Text(
                                  _isPlaying ? 'Pause Simulation' : 'Start Simulation',
                                  style: TextStyle(fontSize: 12, color: headerBg, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Dropdown Quality & Autoplay check
                          Row(
                            children: [
                              const Text('Quality: ', style: TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(width: 4),
                              DropdownButton<String>(
                                value: _selectedQuality,
                                style: TextStyle(color: headerBg, fontSize: 13, fontWeight: FontWeight.bold),
                                items: ['1080p', '720p (Default)', '480p', '360p'].map((q) {
                                  return DropdownMenuItem(value: q, child: Text(q));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedQuality = val;
                                    });
                                  }
                                },
                              ),
                              const Spacer(),
                              Checkbox(
                                value: _autoplayNext,
                                activeColor: primaryGreen,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _autoplayNext = val;
                                    });
                                  }
                                },
                              ),
                              const Text(
                                'Autoplay next',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),

                          // Like Dislike buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Like
                              IconButton(
                                icon: Icon(
                                  _isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
                                  color: _isLiked ? primaryGreen : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_isLiked) {
                                      _isLiked = false;
                                      _likesCount--;
                                    } else {
                                      _isLiked = true;
                                      _likesCount++;
                                      if (_isDisliked) {
                                        _isDisliked = false;
                                        _dislikesCount--;
                                      }
                                    }
                                  });
                                },
                              ),
                              Text('$_likesCount', style: const TextStyle(fontWeight: FontWeight.bold)),

                              // Dislike
                              IconButton(
                                icon: Icon(
                                  _isDisliked ? Icons.thumb_down : Icons.thumb_down_outlined,
                                  color: _isDisliked ? Colors.red : Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    if (_isDisliked) {
                                      _isDisliked = false;
                                      _dislikesCount--;
                                    } else {
                                      _isDisliked = true;
                                      _dislikesCount++;
                                      if (_isLiked) {
                                        _isLiked = false;
                                        _likesCount--;
                                      }
                                    }
                                  });
                                },
                              ),
                              Text('$_dislikesCount', style: const TextStyle(fontWeight: FontWeight.bold)),

                              // Share
                              TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Course link copied to clipboard!')),
                                  );
                                },
                                icon: const Icon(Icons.share, size: 18, color: Colors.grey),
                                label: const Text('Share', style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ),

                              // Save
                              TextButton.icon(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Course saved to bookmarks!')),
                                  );
                                },
                                icon: const Icon(Icons.bookmark_border, size: 18, color: Colors.grey),
                                label: const Text('Save', style: TextStyle(color: Colors.grey, fontSize: 13)),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
