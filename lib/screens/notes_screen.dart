import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';

class Note {
  final String id;
  String content;
  String? imagePath;
  final DateTime createdAt;

  Note({
    required this.id,
    required this.content,
    this.imagePath,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'imagePath': imagePath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        id: json['id'],
        content: json['content'],
        imagePath: json['imagePath'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}

class NotesScreen extends StatefulWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final TextEditingController _noteController = TextEditingController();
  List<Note> _notes = [];
  String? _selectedImagePath;
  String? _editingNoteId;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AppState().currentUserId ?? '';
      final notesString = prefs.getString('notes_key_$userId');
      if (notesString != null) {
        final List<dynamic> decoded = jsonDecode(notesString);
        setState(() {
          _notes = decoded.map((item) => Note.fromJson(item)).toList();
        });
      } else {
        setState(() {
          _notes = [];
        });
      }
    } catch (e) {
      debugPrint("Error loading notes: $e");
    }
  }

  Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = AppState().currentUserId ?? '';
      final notesString = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await prefs.setString('notes_key_$userId', notesString);
    } catch (e) {
      debugPrint("Error saving notes: $e");
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _selectedImagePath = image.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  void _showImageSourceOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _saveOrUpdateNote() {
    final content = _noteController.text.trim();
    if (content.isEmpty && _selectedImagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write a note or attach an image.")),
      );
      return;
    }

    if (_editingNoteId != null) {
      // Update existing note
      final noteIndex = _notes.indexWhere((n) => n.id == _editingNoteId);
      if (noteIndex != -1) {
        setState(() {
          _notes[noteIndex].content = content;
          _notes[noteIndex].imagePath = _selectedImagePath;
          _editingNoteId = null;
        });
      }
    } else {
      // Add new note
      final newNote = Note(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: content,
        imagePath: _selectedImagePath,
        createdAt: DateTime.now(),
      );
      setState(() {
        _notes.insert(0, newNote);
      });
    }

    _noteController.clear();
    setState(() {
      _selectedImagePath = null;
    });

    _saveNotes();
  }

  void _startEditNote(Note note) {
    setState(() {
      _editingNoteId = note.id;
      _noteController.text = note.content;
      _selectedImagePath = note.imagePath;
    });
  }

  void _deleteNote(String id) {
    setState(() {
      _notes.removeWhere((n) => n.id == id);
      if (_editingNoteId == id) {
        _editingNoteId = null;
        _noteController.clear();
        _selectedImagePath = null;
      }
    });
    _saveNotes();
  }

  @override
  Widget build(BuildContext context) {
    final headerColor = const Color(0xFF2E7D32); // Bold green matching screenshot
    final screenBgColor = const Color(0xFFFCFBF4); // Light yellow/cream page background

    return Scaffold(
      backgroundColor: screenBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: headerColor,
                ),
              ),
              const SizedBox(height: 20),
              
              // Custom dashed note editor card
              CustomPaint(
                painter: DashedRectanglePainter(
                  color: const Color(0xFFE6D695),
                  borderRadius: 16,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEEB), // Editor card pastel background
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _noteController,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          hintText: "Write your note...",
                          hintStyle: TextStyle(
                            color: Colors.black38,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      
                      // Attached image preview if selected
                      if (_selectedImagePath != null) ...[
                        const SizedBox(height: 12),
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedImagePath!),
                                height: 120,
                                width: 120,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImagePath = null;
                                  });
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      
                      const SizedBox(height: 16),
                      
                      // Bottom Row: Camera button on left, Add button on right
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.camera_alt, color: Colors.black54),
                            onPressed: _showImageSourceOptions,
                          ),
                          ElevatedButton(
                            onPressed: _saveOrUpdateNote,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4CAF50), // Green Add button
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            ),
                            child: Text(
                              _editingNoteId == null ? "Add" : "Update",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Notes List
              _notes.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 80.0),
                      child: Center(
                        child: Text(
                          'No notes yet.',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        final hasValidImage = note.imagePath != null && File(note.imagePath!).existsSync();
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5D5FF), // Lavender note card background
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFF6E8A9), // Gold card border
                              width: 1.5,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (hasValidImage) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(note.imagePath!),
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Text(
                                  note.content,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.4,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Operations: Edit pencil on left, Delete trash on right
                                Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => _startEditNote(note),
                                      child: const Icon(
                                        Icons.edit,
                                        color: Colors.orangeAccent,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 24),
                                    GestureDetector(
                                      onTap: () => _deleteNote(note.id),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.grey,
                                        size: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              
              // Native Ad below the notes list
              const SizedBox(height: 24),
              AdService.getNativeAdWidget(height: 90),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class DashedRectanglePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double dashLength;
  final double borderRadius;

  DashedRectanglePainter({
    required this.color,
    this.strokeWidth = 1.5,
    this.gap = 4.0,
    this.dashLength = 6.0,
    this.borderRadius = 16.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.addRRect(RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    ));

    final dashPath = Path();
    for (final pathMetric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < pathMetric.length) {
        final length = dashLength;
        dashPath.addPath(
          pathMetric.extractPath(distance, distance + length),
          Offset.zero,
        );
        distance += length + gap;
      }
    }
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant DashedRectanglePainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth ||
      oldDelegate.gap != gap ||
      oldDelegate.dashLength != dashLength ||
      oldDelegate.borderRadius != borderRadius;
}
