import 'dart:async';
import 'package:flutter/material.dart';
import 'course_detail_screen.dart';

class UploadedVideo {
  final String title;
  final String description;
  final String category;
  final String keywords;
  final String fileName;
  final String fileSize;
  final DateTime uploadTime;
  String status; // 'Processing' or 'Published'

  UploadedVideo({
    required this.title,
    required this.description,
    required this.category,
    required this.keywords,
    required this.fileName,
    required this.fileSize,
    required this.uploadTime,
    this.status = 'Processing',
  });
}

class UploadVideoScreen extends StatefulWidget {
  final Function(Course) onCourseUploaded;

  const UploadVideoScreen({
    Key? key,
    required this.onCourseUploaded,
  }) : super(key: key);

  @override
  State<UploadVideoScreen> createState() => _UploadVideoScreenState();
}

class _UploadVideoScreenState extends State<UploadVideoScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _keywordsController = TextEditingController();
  String _selectedCategory = 'Soil Health';

  // Selected file simulation state
  String? _selectedFileName;
  String? _selectedFileSize;

  // Upload history list (static to persist across navigation in the same session)
  static final List<UploadedVideo> _myUploadHistory = [];

  final List<String> _categories = [
    'Soil Health',
    'Irrigation',
    'Organic Farming',
    'Pest Control',
    'Crop Management',
    'Schemes'
  ];

  // Dummy mock video files user can "pick"
  final List<Map<String, String>> _mockVideos = [
    {'name': 'drip_irrigation_setup_final.mp4', 'size': '245 MB'},
    {'name': 'soil_testing_guide_2026.mp4', 'size': '128 MB'},
    {'name': 'organic_vermicompost_method.mov', 'size': '312 MB'},
    {'name': 'pest_control_neem_spray.mp4', 'size': '94 MB'},
    {'name': 'government_subsidies_tutorial.mp4', 'size': '156 MB'},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _showMockFilePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Video File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A5F),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Text(
                'Choose an agricultural video from your local device to upload:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _mockVideos.length,
                  itemBuilder: (context, index) {
                    final item = _mockVideos[index];
                    return Card(
                      elevation: 0,
                      color: const Color(0xFFF1F5F9),
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: ListTile(
                        leading: const Icon(Icons.video_file, color: Color(0xFF1E3A5F)),
                        title: Text(
                          item['name']!,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(item['size']!, style: const TextStyle(fontSize: 12)),
                        onTap: () {
                          setState(() {
                            _selectedFileName = item['name'];
                            _selectedFileSize = item['size'];
                          });
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _clearSelectedFile() {
    setState(() {
      _selectedFileName = null;
      _selectedFileSize = null;
    });
  }

  void _simulateUpload() {
    if (_selectedFileName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file to upload'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a video title'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a video description'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show upload progress indicator dialog
    double progress = 0.0;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Start a timer to increment progress
            Timer? timer;
            if (progress == 0.0) {
              timer = Timer.periodic(const Duration(milliseconds: 200), (t) {
                if (progress >= 1.0) {
                  t.cancel();
                  Navigator.pop(context); // Close dialog
                  _onUploadComplete();
                } else {
                  setDialogState(() {
                    progress += 0.1;
                    if (progress > 1.0) progress = 1.0;
                  });
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload, color: Color(0xFF22C55E), size: 48),
                    const SizedBox(height: 16),
                    Text(
                      progress < 1.0 ? 'Uploading Video...' : 'Publishing Course...',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      color: const Color(0xFF22C55E),
                      backgroundColor: Colors.grey[200],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toInt()}% completed',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _onUploadComplete() {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final category = _selectedCategory;
    final keywords = _keywordsController.text.trim();
    final fileName = _selectedFileName!;
    final fileSize = _selectedFileSize!;

    // Create uploaded video object
    final newVideo = UploadedVideo(
      title: title,
      description: description,
      category: category,
      keywords: keywords,
      fileName: fileName,
      fileSize: fileSize,
      uploadTime: DateTime.now(),
    );

    setState(() {
      _myUploadHistory.insert(0, newVideo);
    });

    // Start a processing timer: after 8 seconds, transition status to Published
    Timer(const Duration(seconds: 8), () {
      if (mounted) {
        setState(() {
          final index = _myUploadHistory.indexOf(newVideo);
          if (index != -1) {
            _myUploadHistory[index].status = 'Published';
          }
        });
      }
    });

    // Determine fallback image for new courses added to main LMS screen
    String imgUrl = "https://images.unsplash.com/photo-1592417817098-8f3d6eb19675?w=500&q=80";
    if (category == 'Irrigation') {
      imgUrl = "https://images.unsplash.com/photo-1563514223300-b3b3a3a854a2?w=500&q=80";
    } else if (category == 'Schemes') {
      imgUrl = "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=500&q=80";
    } else if (category == 'Organic Farming') {
      imgUrl = "https://images.unsplash.com/photo-1589923188900-85dae44094ad?w=500&q=80";
    } else if (category == 'Pest Control') {
      imgUrl = "https://images.unsplash.com/photo-1463123081488-729f555ee3f2?w=500&q=80";
    }

    // Trigger LMS callback to register course
    final newCourse = Course(
      title: title,
      instructor: "Educator Partner",
      description: description,
      rating: 5.0,
      students: "1",
      modules: 4,
      duration: "40 min",
      level: "Beginner",
      category: category,
      imageUrl: imgUrl,
      modulesList: [
        Module(
          title: "1. Overview of $title",
          duration: "10 min",
          description: description,
          objectives: [
            "Introduction to the core principles of $title",
            "General practices and recommended tools"
          ],
        ),
        Module(
          title: "2. Setting up & Setup Guides",
          duration: "12 min",
          description: "Step-by-step procedures to layout and setup.",
          objectives: ["Proper tool placement", "Configuration guides"],
        ),
        Module(
          title: "3. Maintenance & Common Problems",
          duration: "8 min",
          description: "Learn troubleshooting techniques for common failure modes.",
          objectives: ["Diagnosing pressure losses", "Cleaning and filters"],
        ),
        Module(
          title: "4. Summary & Quiz",
          duration: "10 min",
          description: "Summary assessment.",
          objectives: ["Knowledge check questions"],
        ),
      ],
    );

    widget.onCourseUploaded(newCourse);

    // Clear inputs
    _titleController.clear();
    _descriptionController.clear();
    _keywordsController.clear();
    _clearSelectedFile();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Video Uploaded & Published Successfully!'),
          ],
        ),
        backgroundColor: const Color(0xFF22C55E),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final headerBg = const Color(0xFF1E3A5F);
    final primaryGreen = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF), // Soft light blue layout
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. FULL HEADER (styled like screenshot 1)
            Container(
              color: headerBg,
              padding: const EdgeInsets.fromLTRB(16, 48, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Align(
                    alignment: Alignment.topLeft,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                      label: const Text(
                        'Back',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF385A82),
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('📹', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        'Upload Video File',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Share your agriculture videos instantly with farmers\n(no approval needed)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // 2. MAIN CARD LAYOUT
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video File Section
                      Row(
                        children: const [
                          Text('🎬', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Video File',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select Video File',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Dashed upload box or Selected File Indicator
                      GestureDetector(
                        onTap: _selectedFileName == null ? _showMockFilePicker : null,
                        child: _selectedFileName != null
                            ? Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.video_file, color: Color(0xFF22C55E), size: 36),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _selectedFileName!,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Color(0xFF0F172A),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _selectedFileSize!,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: _clearSelectedFile,
                                    ),
                                  ],
                                ),
                              )
                            : CustomPaint(
                                painter: DashedBorderPainter(
                                  color: const Color(0xFFCBD5E1),
                                  strokeWidth: 1.5,
                                  borderRadius: 16,
                                ),
                                child: Container(
                                  height: 140,
                                  width: double.infinity,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFEFF6FF),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(
                                          Icons.file_upload,
                                          color: Color(0xFF1E3A5F),
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Click to upload or drag and drop',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1E3A5F),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'MP4, MOV, AVI, WebM, OGG (Max 1GB)',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 12),

                      // Video Details Section
                      Row(
                        children: const [
                          Text('📝', style: TextStyle(fontSize: 16)),
                          SizedBox(width: 8),
                          Text(
                            'Video Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Title field
                      Row(
                        children: const [
                          Text(
                            'Title',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Drip Irrigation for Small Farms',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Description field
                      Row(
                        children: const [
                          Text(
                            'Description',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Explain what farmers will learn...',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          contentPadding: const EdgeInsets.all(16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Category Dropdown
                      const Text(
                        'Category',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 14)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCategory = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Keywords field
                      const Text(
                        'Keywords (comma separated)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _keywordsController,
                        decoration: InputDecoration(
                          hintText: 'irrigation, drip, water saving',
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),

                      // Buttons Row
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                foregroundColor: const Color(0xFF0F172A),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _simulateUpload,
                              icon: const Icon(Icons.cloud_upload, size: 18),
                              label: const Text(
                                'Upload & Publish Video',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. UPLOAD HISTORY SECTION (styled like screenshot 3)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Text('📥', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 8),
                      Text(
                        'My Upload History',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  _myUploadHistory.isEmpty
                      ? Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: const [
                              Text('📪', style: TextStyle(fontSize: 24)),
                              SizedBox(height: 8),
                              Text(
                                'No videos uploaded yet',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Upload your first video above to get started!',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _myUploadHistory.length,
                          itemBuilder: (context, index) {
                            final video = _myUploadHistory[index];
                            final isProcessing = video.status == 'Processing';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.play_circle_outline,
                                      color: isProcessing ? Colors.orange : const Color(0xFF22C55E),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          video.title,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: Color(0xFF0F172A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                video.category,
                                                style: const TextStyle(
                                                  color: Color(0xFF1E3A5F),
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              video.fileSize,
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          video.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isProcessing
                                          ? const Color(0xFFFEF3C7) // soft yellow
                                          : const Color(0xFFDCFCE7), // soft green
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isProcessing) ...[
                                          const SizedBox(
                                            width: 8,
                                            height: 8,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 1.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                        ],
                                        Text(
                                          isProcessing ? 'Processing' : 'Published 🟢',
                                          style: TextStyle(
                                            color: isProcessing ? const Color(0xFFD97706) : const Color(0xFF16A34A),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for dashed rounded borders
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedBorderPainter({
    this.color = Colors.grey,
    this.strokeWidth = 1,
    this.gap = 4,
    this.dashLength = 6,
    this.borderRadius = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(borderRadius),
      ));

    final dashedPath = Path();
    double distance = 0.0;
    for (final pathMetric in path.computeMetrics()) {
      while (distance < pathMetric.length) {
        dashedPath.addPath(
          pathMetric.extractPath(distance, distance + dashLength),
          Offset.zero,
        );
        distance += dashLength + gap;
      }
    }
    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
