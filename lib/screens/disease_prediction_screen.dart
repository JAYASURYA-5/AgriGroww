import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_drop/desktop_drop.dart';
import '../services/app_state.dart';
import '../services/ad_service.dart';

class DiseasePredictionScreen extends StatefulWidget {
  const DiseasePredictionScreen({Key? key}) : super(key: key);

  @override
  State<DiseasePredictionScreen> createState() => _DiseasePredictionScreenState();
}

class _DiseasePredictionScreenState extends State<DiseasePredictionScreen> {
  // Navigation & State Toggle
  bool _isDiseaseCheck = true; // true = Disease Check, false = Soil Analysis

  // Image Selection State
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  // Analysis State
  bool _isAnalyzing = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  // Clear selected image
  void _clearImage() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _errorMessage = null;
    });
  }

  // Pick Image from Gallery or Camera
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _analysisResult = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error picking image: $e';
      });
    }
  }

  // Show image source picker bottom sheet
  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Color(0xFF22C55E)),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera, color: Color(0xFF22C55E)),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _promptAndStartAnalysis() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Unlock AI Analysis"),
        content: const Text("Watch a quick sponsored video ad to generate advanced AI crop/soil insights & recommendations."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AdService.showRewardedAd(context, () {
                _startAnalysis();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
            ),
            child: const Text("Watch Ad", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Call Gemini API or fallback to Offline Demo Result
  Future<void> _startAnalysis() async {
    if (_selectedImage == null) return;

    final apiKey = AppState().geminiApiKeyNotifier.value.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = 'Gemini API Key is not configured. Go to settings to set your key. Using offline demo fallback...';
        _analysisResult = null;
      });
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          _loadDemoResult();
        }
      });
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _errorMessage = null;
      _analysisResult = null;
    });

    try {
      final imageBytes = await _selectedImage!.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = _isDiseaseCheck
          ? "You are an expert plant pathologist/botanist. "
              "Analyze this crop leaf image and diagnose any crop disease present. "
              "Provide your response as a strict JSON object with the following keys. Do not include markdown code block formatting (like ```json) in your raw response: "
              "{"
              "  \"diseaseName\": \"Name of the disease (e.g., Powdery Mildew, Black Spot, Rust) or 'Healthy' or 'Unknown'\","
              "  \"confidence\": \"percentage confidence as an integer (e.g., 92)\","
              "  \"symptoms\": [\"symptom 1\", \"symptom 2\", \"symptom 3\"],"
              "  \"severity\": \"LOW, MEDIUM, or HIGH\","
              "  \"causes\": [\"cause 1\", \"cause 2\", \"cause 3\"],"
              "  \"treatments\": [\"treatment step 1\", \"treatment step 2\"],"
              "  \"preventions\": [\"prevention step 1\", \"prevention step 2\"]"
              "}"
          : "You are an expert soil scientist/agronomist. "
              "Analyze this soil image or document and provide analysis. "
              "Provide your response as a strict JSON object with the following keys. Do not include markdown code block formatting (like ```json) in your raw response: "
              "{"
              "  \"soilType\": \"Name of the soil type (e.g., Clay, Loam, Sandy, Alluvial)\","
              "  \"confidence\": \"percentage confidence as an integer (e.g., 88)\","
              "  \"properties\": [\"property 1\", \"property 2\", \"property 3\"],"
              "  \"nutrientStatus\": \"OPTIMAL, DEFICIENT, or SURPLUS\","
              "  \"recommendedCrops\": [\"crop 1\", \"crop 2\", \"crop 3\"],"
              "  \"improvementSteps\": [\"improvement step 1\", \"improvement step 2\"],"
              "  \"maintenance\": [\"maintenance tip 1\", \"maintenance tip 2\"]"
              "}";

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
                {
                  'inlineData': {
                    'mimeType': 'image/jpeg',
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates'][0]['content']['parts'][0]['text'] as String;

        // Clean up markdown block formatting if present
        String cleanedJson = rawText.trim();
        if (cleanedJson.startsWith('```')) {
          final lines = cleanedJson.split('\n');
          if (lines.first.startsWith('```json')) {
            lines.removeAt(0);
          } else if (lines.first.startsWith('```')) {
            lines.removeAt(0);
          }
          if (lines.isNotEmpty && lines.last.startsWith('```')) {
            lines.removeLast();
          }
          cleanedJson = lines.join('\n').trim();
        }

        final parsedResult = jsonDecode(cleanedJson);
        setState(() {
          _analysisResult = parsedResult;
          _isAnalyzing = false;
        });
      } else {
        setState(() {
          _errorMessage = 'API Error (Status ${response.statusCode}): ${response.body}';
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to analyze image: $e. Using offline demo fallback instead.';
        _isAnalyzing = false;
      });
      // Fallback to offline demo if call fails
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _loadDemoResult();
        }
      });
    }
  }

  // Load Mock Demo Data matching the user's screenshots exactly
  void _loadDemoResult() {
    setState(() {
      _errorMessage = null;
      if (_isDiseaseCheck) {
        _analysisResult = {
          'diseaseName': 'Powdery Mildew',
          'confidence': 92,
          'symptoms': [
            'White powdery spots on leaves and stems',
            'Leaves may curl or become distorted',
            'Premature leaf drop'
          ],
          'severity': 'LOW',
          'causes': [
            'Fungal spores spread by wind',
            'High humidity with moderate temperatures',
            'Poor air circulation'
          ],
          'treatments': [
            'Prune affected leaves and stems to improve air flow',
            'Apply organic neem oil or sulfur-based fungicides',
            'Avoid watering leaves directly; irrigate at root level'
          ],
          'preventions': [
            'Plant in areas with good air circulation',
            'Water at the base of plants, not on leaves',
            'Space plants adequately',
            'Choose resistant varieties when available',
            'Avoid overhead irrigation',
            'Remove and destroy infected plant material'
          ]
        };
      } else {
        _analysisResult = {
          'soilType': 'Clay Loam',
          'confidence': 88,
          'properties': [
            'Fine texture with high water retention capability',
            'Rich in plant nutrients, particularly potassium and calcium',
            'Slow drainage characteristics, prone to compaction'
          ],
          'nutrientStatus': 'OPTIMAL',
          'recommendedCrops': [
            'Rice/Paddy (demands standing water)',
            'Sugarcane (requires moisture retention)',
            'Wheat & Cabbage (thrive in fertile clay loams)'
          ],
          'improvementSteps': [
            'Incorporate compost or manure to improve aeration',
            'Apply gypsum to loosen clay particles and structure',
            'Construct raised beds to encourage lateral drainage'
          ],
          'maintenance': [
            'Avoid tilling when soil is excessively wet',
            'Apply a thick layer of mulch to prevent surface crusting',
            'Grow deep-rooted cover crops like radishes to break soil compaction'
          ]
        };
      }
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate background
      body: Stack(
        children: [
          // 1. DYNAMIC LIVE BACKGROUND (Pulsing Gradient & Animating Leaves)
          const Positioned.fill(
            child: LiveLeafBackground(),
          ),

          // 2. SCROLLABLE CONTENT AREA
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 12),

                  // Header Bar with Back button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back to Home Button
                      OutlinedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white, size: 16),
                        label: const Text(
                          'Back to Home',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.25),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                      // Indication of live API status
                      ValueListenableBuilder<String>(
                        valueListenable: AppState().geminiApiKeyNotifier,
                        builder: (context, apiKey, child) {
                          final isConfigured = apiKey.trim().isNotEmpty;
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isConfigured
                                  ? const Color(0xFF22C55E).withOpacity(0.25)
                                  : const Color(0xFFFF9800).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: isConfigured ? const Color(0xFF00FF66) : const Color(0xFFFF9800),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isConfigured ? 'Gemini API Connected' : 'Offline Demo Mode',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Screen Title
                  Center(
                    child: Text(
                      _isDiseaseCheck ? 'Crop Disease\nPredictor' : 'Soil Disease &\nAnalyzer',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            blurRadius: 4,
                            color: Colors.black38,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        _isDiseaseCheck
                            ? 'Upload a crop image to detect diseases and get treatment recommendations'
                            : 'Upload a soil image to identify characteristics, nutrients, and crop recommendations',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black26,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. SLICK CUSTOM TAB TOGGLE BUTTONS (Disease Check / Soil Analysis)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Disease Check Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (!_isDiseaseCheck) {
                                setState(() {
                                  _isDiseaseCheck = true;
                                  _selectedImage = null;
                                  _analysisResult = null;
                                  _errorMessage = null;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _isDiseaseCheck ? primaryGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.spa_outlined,
                                    color: _isDiseaseCheck ? Colors.white : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Disease Check',
                                    style: TextStyle(
                                      color: _isDiseaseCheck ? Colors.white : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Soil Analysis Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (_isDiseaseCheck) {
                                setState(() {
                                  _isDiseaseCheck = false;
                                  _selectedImage = null;
                                  _analysisResult = null;
                                  _errorMessage = null;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: !_isDiseaseCheck ? primaryGreen : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dark_mode_outlined,
                                    color: !_isDiseaseCheck ? Colors.white : Colors.white70,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Soil Analysis',
                                    style: TextStyle(
                                      color: !_isDiseaseCheck ? Colors.white : Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. MAIN UPLOAD CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              color: primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Upload Image',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Gradient Line
                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF22C55E),
                                      Color(0xFFE2E8F0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Dashed Selection Area (Supports drag-and-drop files as well as tap-to-pick)
                        DropTarget(
                          onDragDone: (detail) {
                            if (detail.files.isNotEmpty) {
                              final file = detail.files.first;
                              setState(() {
                                _selectedImage = File(file.path);
                                _analysisResult = null;
                                _errorMessage = null;
                              });
                            }
                          },
                          child: GestureDetector(
                            onTap: _showImageSourceSelector,
                            child: CustomPaint(
                              painter: DashedBorderPainter(
                                color: const Color(0xFFCBD5E1),
                                strokeWidth: 1.5,
                                borderRadius: 16,
                              ),
                              child: Container(
                                height: 220,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: const Color(0xFFF8FAFC),
                                ),
                                child: _selectedImage != null
                                    ? Stack(
                                        children: [
                                          // Selected Image Preview
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(16),
                                            child: Image.file(
                                              _selectedImage!,
                                              width: double.infinity,
                                              height: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          // Delete Floating Button
                                          Positioned(
                                            top: 10,
                                            right: 10,
                                            child: GestureDetector(
                                              onTap: () {
                                                // Prevent triggering outer container tap
                                                _clearImage();
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: const BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black26,
                                                      blurRadius: 4,
                                                      offset: Offset(0, 2),
                                                    )
                                                  ],
                                                ),
                                                child: const Icon(
                                                  Icons.delete,
                                                  color: Colors.red,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.add_photo_alternate_outlined,
                                            color: Color(0xFF64748B),
                                            size: 44,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _isDiseaseCheck
                                                ? 'Drag & drop or Tap to select Leaf Image'
                                                : 'Drag & drop or Tap to select Soil Image',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF475569),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          const Text(
                                            'Drop files here or tap to select image',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _showImageSourceSelector,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: const Color(0xFF3B82F6),
                                              foregroundColor: Colors.white,
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 20,
                                                vertical: 12,
                                              ),
                                            ),
                                            child: const Text(
                                              'Select Image',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        if (_selectedImage != null && !_isAnalyzing && _analysisResult == null) ...[
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _promptAndStartAnalysis,
                              icon: const Icon(Icons.rocket_launch, size: 16),
                              label: Text(
                                _isDiseaseCheck ? 'Analyze Crop Leaf' : 'Analyze Soil Sample',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. ANALYSIS RESULTS CARD
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card Header
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryGreen,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Analysis Results',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Gradient Line
                            Expanded(
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF22C55E),
                                      Color(0xFFE2E8F0),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Error message indicator if any
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFFCA5A5)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Colors.red),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Render States: Empty, Loading, or Analysis Results
                        if (_isAnalyzing) ...[
                          _buildLoadingState()
                        ] else if (_analysisResult != null) ...[
                          _buildResultsState()
                        ] else ...[
                          _buildEmptyState()
                        ]
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Visual widget for the Empty Initial State
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1FDF5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.spa_outlined, // Leaf outline
                color: Color(0xFF86EFAC),
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Upload and analyze an image to see results',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Visual widget for the Loading State
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF22C55E),
            ),
            const SizedBox(height: 20),
            const Text(
              'Analyzing image with Gemini API...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'This should only take a couple of seconds.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Visual widget for formatting and listing the full Analysis Results
  Widget _buildResultsState() {
    final primaryGreen = const Color(0xFF22C55E);

    if (_isDiseaseCheck) {
      // DISEASE CHECK RESULT LAYOUT
      final disease = _analysisResult!['diseaseName'] ?? 'Unknown';
      final confidence = _analysisResult!['confidence'] ?? 0;
      final symptoms = List<String>.from(_analysisResult!['symptoms'] ?? []);
      final severity = (_analysisResult!['severity'] ?? 'LOW').toString().toUpperCase();
      final causes = List<String>.from(_analysisResult!['causes'] ?? []);
      final treatments = List<String>.from(_analysisResult!['treatments'] ?? []);
      final preventions = List<String>.from(_analysisResult!['preventions'] ?? []);

      Color severityColor = const Color(0xFFFCD34D); // Yellow
      if (severity == 'MEDIUM') {
        severityColor = Colors.orange;
      } else if (severity == 'HIGH') {
        severityColor = Colors.red;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ALERT BANNER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.bug_report, color: Color(0xFF10B981)),
                const SizedBox(width: 8),
                Text(
                  'Disease Detected: $disease',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF065F46),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. CONFIDENCE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2), // soft pink/red background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFEE2E2)),
            ),
            child: Row(
              children: [
                // Red Exclamation Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.priority_high, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        disease,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7F1D1D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Detected Plant Pathology',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$confidence%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7F1D1D),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Confidence',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. SYMPTOMS OBSERVED CARD
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
                  children: const [
                    Icon(Icons.list_alt, color: Color(0xFF3B82F6), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Symptoms Observed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...symptoms.map((symptom) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 8),
                            child: CircleAvatar(radius: 3.5, backgroundColor: Colors.red),
                          ),
                          Expanded(
                            child: Text(
                              symptom,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. SEVERITY LEVEL CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Severity Level',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: severityColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: severityColor),
                  ),
                  child: Text(
                    severity,
                    style: TextStyle(
                      color: severityColor == const Color(0xFFFCD34D)
                          ? const Color(0xFFD97706)
                          : severityColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. ROOT CAUSES CARD
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
                  children: const [
                    Icon(Icons.psychology, color: Color(0xFFFF6B35), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Root Causes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...causes.map((cause) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '→ ',
                            style: TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              cause,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 6. STEP-BY-STEP TREATMENT GUIDE CARD
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
                  children: const [
                    Icon(Icons.healing_outlined, color: Color(0xFF8B5CF6), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Step-by-Step Treatment Guide',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < treatments.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Blue Circle Number
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            treatments[i],
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 7. PREVENTION & PRECAUTIONS CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4), // green background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Prevention & Precautions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...preventions.map((prev) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, color: primaryGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prev,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      );
    } else {
      // SOIL ANALYSIS RESULT LAYOUT
      final soil = _analysisResult!['soilType'] ?? 'Unknown';
      final confidence = _analysisResult!['confidence'] ?? 0;
      final properties = List<String>.from(_analysisResult!['properties'] ?? []);
      final nutrientStatus = (_analysisResult!['nutrientStatus'] ?? 'OPTIMAL').toString().toUpperCase();
      final recommendedCrops = List<String>.from(_analysisResult!['recommendedCrops'] ?? []);
      final improvementSteps = List<String>.from(_analysisResult!['improvementSteps'] ?? []);
      final maintenance = List<String>.from(_analysisResult!['maintenance'] ?? []);

      Color statusColor = const Color(0xFF22C55E); // Green for OPTIMAL
      if (nutrientStatus == 'DEFICIENT') {
        statusColor = Colors.red;
      } else if (nutrientStatus == 'SURPLUS') {
        statusColor = Colors.orange;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. ALERT BANNER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.terrain, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Text(
                  'Soil Classification: $soil',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 2. SOIL TYPE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // soft blue background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDBEAFE)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.grass_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        soil,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E3A5F),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Detected Soil Composition',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$confidence%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A5F),
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Confidence',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3. SOIL PROPERTIES CARD
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
                  children: const [
                    Icon(Icons.analytics_outlined, color: Color(0xFF3B82F6), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Soil Characteristics',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...properties.map((prop) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6, right: 8),
                            child: CircleAvatar(radius: 3.5, backgroundColor: Colors.blue),
                          ),
                          Expanded(
                            child: Text(
                              prop,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 4. NUTRIENT STATUS CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Nutrient Status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    nutrientStatus,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 5. RECOMMENDED CROPS CARD
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
                  children: const [
                    Icon(Icons.agriculture, color: Color(0xFF10B981), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Recommended Crops',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    List<Widget> listItems = [];
                    for (int i = 0; i < recommendedCrops.length; i++) {
                      listItems.add(Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              '→ ',
                              style: TextStyle(
                                color: Color(0xFF22C55E),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                recommendedCrops[i],
                                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ));
                      if ((i + 1) % 4 == 0) {
                        listItems.add(Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: AdService.getNativeAdWidget(height: 70),
                        ));
                      }
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: listItems,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 6. SOIL IMPROVEMENT STEPS CARD
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
                  children: const [
                    Icon(Icons.upgrade_outlined, color: Color(0xFF8B5CF6), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Soil Improvement Steps',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (int i = 0; i < improvementSteps.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFF3B82F6),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            improvementSteps[i],
                            style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 7. FERTILITY MAINTENANCE CARD
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      'Fertility Maintenance',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF14532D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...maintenance.map((prev) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check, color: primaryGreen, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              prev,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF166534)),
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      );
    }
  }
}

// ----------------------------------------------------------------------
// DYNAMIC LIVE BACKGROUND COMPONENTS
// ----------------------------------------------------------------------

class LiveLeafBackground extends StatefulWidget {
  const LiveLeafBackground({Key? key}) : super(key: key);

  @override
  State<LiveLeafBackground> createState() => _LiveLeafBackgroundState();
}

class _LiveLeafBackgroundState extends State<LiveLeafBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<LeafParticle> _particles = [];
  final random = math.Random();

  @override
  void initState() {
    super.initState();
    // Initialize random leaf particles
    for (int i = 0; i < 12; i++) {
      _particles.add(LeafParticle.random(random));
    }

    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..addListener(() {
        setState(() {
          for (final particle in _particles) {
            particle.update();
          }
        });
      })..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF0F2D18), // Deep forest green
            Color(0xFF1F4D2B), // Dark organic green
            Color(0xFF111827), // Near black/slate background
          ],
        ),
      ),
      child: CustomPaint(
        painter: LeafBackgroundPainter(particles: _particles),
      ),
    );
  }
}

class LeafParticle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double rotation;
  double swaySpeed;
  double swayRange;
  double baseAngle;
  final math.Random random;

  LeafParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.rotation,
    required this.swaySpeed,
    required this.swayRange,
    required this.baseAngle,
    required this.random,
  });

  factory LeafParticle.random(math.Random rand) {
    return LeafParticle(
      x: rand.nextDouble(),
      y: rand.nextDouble() * 1.2,
      size: rand.nextDouble() * 24 + 16,
      speed: rand.nextDouble() * 0.0015 + 0.0006,
      opacity: rand.nextDouble() * 0.15 + 0.05,
      rotation: rand.nextDouble() * math.pi * 2,
      swaySpeed: rand.nextDouble() * 2 + 1.0,
      swayRange: rand.nextDouble() * 0.08 + 0.04,
      baseAngle: rand.nextDouble() * math.pi,
      random: rand,
    );
  }

  void update() {
    // Drifts upwards
    y -= speed;
    
    // Horizontal sway
    x += math.sin(y * swaySpeed + baseAngle) * 0.0012;
    
    // Sway rotation
    rotation += 0.005;

    // Reset if it goes off screen (top)
    if (y < -0.1) {
      y = 1.1;
      x = random.nextDouble();
      size = random.nextDouble() * 24 + 16;
      speed = random.nextDouble() * 0.0015 + 0.0006;
      opacity = random.nextDouble() * 0.15 + 0.05;
    }
  }
}

class LeafBackgroundPainter extends CustomPainter {
  final List<LeafParticle> particles;

  LeafBackgroundPainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = const Color(0xFF22C55E).withOpacity(particle.opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      canvas.save();
      
      // Move to particle coordinate
      canvas.translate(particle.x * size.width, particle.y * size.height);
      canvas.rotate(particle.rotation);

      // Draw minimal organic leaf outline
      final leafSize = particle.size;
      final path = Path();
      
      path.moveTo(0, -leafSize / 2);
      // Left side curve
      path.quadraticBezierTo(leafSize / 3, -leafSize / 4, leafSize / 4, 0);
      path.quadraticBezierTo(leafSize / 3, leafSize / 4, 0, leafSize / 2);
      // Right side curve
      path.quadraticBezierTo(-leafSize / 3, leafSize / 4, -leafSize / 4, 0);
      path.quadraticBezierTo(-leafSize / 3, -leafSize / 4, 0, -leafSize / 2);
      
      // Leaf central vein
      path.moveTo(0, -leafSize / 2);
      path.lineTo(0, leafSize / 2);

      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom Painter for drawing a dashed rounded border around upload card
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
