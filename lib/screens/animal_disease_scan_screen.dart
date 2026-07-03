import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:desktop_drop/desktop_drop.dart';
import '../services/app_state.dart';

class AnimalDiseaseScanScreen extends StatefulWidget {
  final bool hideBackButton;
  const AnimalDiseaseScanScreen({
    Key? key,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<AnimalDiseaseScanScreen> createState() => _AnimalDiseaseScanScreenState();
}

class _AnimalDiseaseScanScreenState extends State<AnimalDiseaseScanScreen> {
  // Selection State
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String _selectedAnimalType = "Cattle";
  final TextEditingController _notesController = TextEditingController();

  // Analysis State
  bool _isAnalyzing = false;
  String? _errorMessage;
  Map<String, dynamic>? _analysisResult;

  // Selected Symptoms Checkboxes Map
  final Map<String, bool> _selectedSymptoms = {
    "Fever / High Temperature": false,
    "Loss of Appetite": false,
    "Coughing": false,
    "Difficulty Breathing": false,
    "Bloating": false,
    "Skin Lesions / Rashes": false,
    "Limping / Lameness": false,
    "Eye Discharge": false,
    "Lethargy / Weakness": false,
    "Weight Loss": false,
    "Nasal Discharge": false,
    "Diarrhea": false,
    "Vomiting": false,
    "Hair / Feather Loss": false,
    "Swelling in Body Parts": false,
    "Excessive Drooling": false,
  };

  final List<String> _animalTypes = ["Cattle", "Sheep", "Goats", "Pigs", "Chickens", "Horses"];

  void _clearSelection() {
    setState(() {
      _selectedImage = null;
      _analysisResult = null;
      _errorMessage = null;
      _notesController.clear();
      _selectedSymptoms.updateAll((key, value) => false);
    });
  }

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

  Future<void> _startAnalysis() async {
    final List<String> activeSymptoms = [];
    _selectedSymptoms.forEach((key, val) {
      if (val) activeSymptoms.add(key);
    });

    if (activeSymptoms.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one symptom or upload an image!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final apiKey = AppState().geminiApiKeyNotifier.value.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _isAnalyzing = true;
        _errorMessage = 'Gemini API Key is not configured. Go to settings to set your key. Using offline fallback...';
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
      String base64Image = "";
      if (_selectedImage != null) {
        final imageBytes = await _selectedImage!.readAsBytes();
        base64Image = base64Encode(imageBytes);
      }

      final prompt = 
          "You are an expert veterinary doctor and animal pathologist. "
          "Analyze these symptoms and details for a ${_selectedAnimalType.toLowerCase()}. "
          "Selected symptoms: ${activeSymptoms.join(', ')}. "
          "Additional observations/notes: ${_notesController.text.trim()}. "
          "${_selectedImage != null ? 'I have also uploaded a disease symptom image.' : ''} "
          "Diagnose the animal disease. Provide your response as a strict JSON object with the following keys. "
          "Do not include markdown code block formatting (like ```json) in your raw response: "
          "{"
          "  \"diseaseName\": \"Name of the disease (e.g., Foot and Mouth Disease, Newcastle, Ruminal Bloat) or 'Healthy' or 'Unknown'\","
          "  \"confidence\": \"percentage confidence as an integer (e.g., 92)\","
          "  \"severity\": \"LOW, MEDIUM, or HIGH\","
          "  \"symptoms\": [\"symptom 1\", \"symptom 2\"],"
          "  \"causes\": [\"cause 1\", \"cause 2\"],"
          "  \"treatmentSteps\": [\"step 1\", \"step 2\"],"
          "  \"medicines\": [{\"name\": \"Medicine Name\", \"dosage\": \"e.g., 10ml daily\", \"purpose\": \"e.g., antibiotic\", \"instructions\": \"e.g., intramuscular injection\"}],"
          "  \"preventions\": [\"prevention 1\", \"prevention 2\"]"
          "}";

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
              if (base64Image.isNotEmpty)
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
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
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
          _errorMessage = 'API Error (Status ${response.statusCode}). Using offline demo fallback.';
        });
        _loadDemoResult();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to call API: $e. Using offline demo fallback instead.';
      });
      _loadDemoResult();
    }
  }

  void _loadDemoResult() {
    setState(() {
      final hasFever = _selectedSymptoms["Fever / High Temperature"] ?? false;
      final hasDrooling = _selectedSymptoms["Excessive Drooling"] ?? false;
      final hasLimping = _selectedSymptoms["Limping / Lameness"] ?? false;
      final hasBreathing = _selectedSymptoms["Difficulty Breathing"] ?? false;
      final hasCoughing = _selectedSymptoms["Coughing"] ?? false;
      final hasDiarrhea = _selectedSymptoms["Diarrhea"] ?? false;
      final hasBloating = _selectedSymptoms["Bloating"] ?? false;
      
      String disease = "Gastrointestinal Parasites / Worms";
      int confidence = 82;
      String severity = "MEDIUM";
      List<String> symptoms = [];
      List<String> causes = [];
      List<String> treatments = [];
      List<dynamic> medicines = [];
      List<String> preventions = [];

      _selectedSymptoms.forEach((key, val) {
        if (val) symptoms.add(key);
      });

      if (symptoms.isEmpty) symptoms.add("General lethargy");

      if (_selectedAnimalType == "Cattle" && hasDrooling && hasLimping && hasFever) {
        disease = "Foot and Mouth Disease (FMD)";
        confidence = 94;
        severity = "HIGH";
        causes = ["Foot-and-mouth disease virus (FMDV)", "Contact with infected herds", "Contaminated pastures"];
        treatments = [
          "Quarantine infected animal immediately to prevent spread to the herd",
          "Apply mild antiseptic solution to foot lesions and mouth sores",
          "Feed soft, easily digestible wet feeds",
          "Provide clean, dry bedding and well-ventilated enclosure"
        ];
        medicines = [
          {"name": "Potassium Permanganate (0.1% wash)", "dosage": "Apply twice daily", "purpose": "Antiseptic wash", "instructions": "For cleaning feet and mouth lesions"},
          {"name": "Meloxicam Injection", "dosage": "0.5 mg/kg body weight", "purpose": "Anti-inflammatory & pain relief", "instructions": "Subcutaneous injection once daily"},
          {"name": "Oxytetracycline Wound Spray", "dosage": "Apply to foot lesions daily", "purpose": "Prevent secondary bacterial infection", "instructions": "Topical spray after washing"}
        ];
        preventions = ["Regular vaccination schedules (every 6 months)", "Strict farm biosecurity protocols", "Isolate new animals for 21 days"];
      } else if (_selectedAnimalType == "Cattle" && (hasBreathing || hasCoughing) && hasFever) {
        disease = "Bovine Respiratory Disease (BRD)";
        confidence = 90;
        severity = "HIGH";
        causes = ["Viral pathogen stressors (BRSV, IBR)", "Secondary bacterial agents (Pasteurella)", "Poor air quality and high dust/ammonia levels in barn"];
        treatments = [
          "Isolate the calf immediately",
          "House in dry, draft-free, well-ventilated quarantine stall",
          "Ensure access to fresh, clean drinking water",
          "Feed highly palatable diet to stimulate appetite"
        ];
        medicines = [
          {"name": "Draxxin (Tulathromycin)", "dosage": "2.5 mg/kg body weight", "purpose": "Antibiotic", "instructions": "Single subcutaneous injection in the neck"},
          {"name": "Flunixin Meglumine", "dosage": "2.2 mg/kg body weight", "purpose": "Anti-inflammatory & fever reducer", "instructions": "Intravenous injection once daily for 3 days"},
          {"name": "Oral Electrolytes", "dosage": "Ad libitum", "purpose": "Hydration support", "instructions": "Mix in clean water"}
        ];
        preventions = ["Vaccinate calves against respiratory viruses", "Ensure clean air flow in barns", "Minimize shipping stress"];
      } else if (hasBloating) {
        disease = "Ruminal Bloat (Tympany)";
        confidence = 88;
        severity = "HIGH";
        causes = ["Excessive consumption of young, wet clover/pasture legumes", "Blockage in esophagus preventing burping", "Sudden switch to high-concentrate feeds"];
        treatments = [
          "Walk the animal to stimulate digestive movement",
          "Pass a stomach tube to vent free gas",
          "Elevate the front legs to relieve pressure on lungs",
          "Drench anti-foaming agent to disperse stable foam"
        ];
        medicines = [
          {"name": "Tympanol / Bloat Guard", "dosage": "100 ml orally", "purpose": "Rumen antifoaming agent", "instructions": "Slow oral drench. Do not let animal choke"},
          {"name": "Mineral or Vegetable Oil", "dosage": "500 ml to 1 Liter", "purpose": "Disperse foam bubbles", "instructions": "Administer orally via drench bottle or stomach tube"},
          {"name": "Rumen-active stimulants", "dosage": "50g package", "purpose": "Restore digestive flora", "instructions": "Mix with warm water and drench twice daily"}
        ];
        preventions = ["Feed dry forage prior to morning pasture release", "Limit initial legume grazing duration", "Avoid abrupt feed transitions"];
      } else if (_selectedAnimalType == "Chickens" && (hasDiarrhea || hasFever)) {
        disease = "Coccidiosis / Newcastle Disease";
        confidence = 85;
        severity = "HIGH";
        causes = ["Eimeria protozoal parasites", "Ingestion of sporulated oocysts in wet litter", "Overcrowded and damp coop floors"];
        treatments = [
          "Isolate droopy, listless birds",
          "Empty, disinfect, and re-litter the coop with dry shavings",
          "Treat entire flock via water supply",
          "Supplement daily with Vitamin A and K"
        ];
        medicines = [
          {"name": "Amprolium (Corid 9.6% solution)", "dosage": "9.5 ml per gallon of water", "purpose": "Coccidiostat", "instructions": "Provide as sole drinking source for 5-7 days"},
          {"name": "Sulfaquinoxaline", "dosage": "0.04% in drinking water", "purpose": "Antibacterial & Coccidiostat", "instructions": "Use for 3 days under direction of vet"},
          {"name": "Vitamin K & A Supplements", "dosage": "5 ml per 100 birds", "purpose": "Reduce intestinal bleeding & boost immunity", "instructions": "Add to fresh drinking water daily for 7 days"}
        ];
        preventions = ["Keep coop bedding dry and change frequently", "Provide sufficient coop space", "Use coccidiostat-formulated chick feeds"];
      } else {
        disease = "Internal Parasitic Infection (Haemonchosis)";
        confidence = 80;
        severity = "MEDIUM";
        causes = ["Stomach worm eggs picked up from grass", "Continuous grazing on same pasture plots", "Damp grass during morning hours"];
        treatments = [
          "Administer systemic anthelmintic (dewormer)",
          "Transfer the flock/herd to clean, ungrazed pastures",
          "Administer supplementary iron to combat worm-induced anemia",
          "Evaluate FAMACHA scores for anemia check"
        ];
        medicines = [
          {"name": "Albendazole (Valbazen)", "dosage": "7.5 mg/kg body weight", "purpose": "Broad-spectrum dewormer", "instructions": "Administer orally. Warning: Do not use in pregnant ewes/cows in early gestation"},
          {"name": "Ivermectin 1% injection", "dosage": "1 ml per 50 kg body weight", "purpose": "Dewormer", "instructions": "Subcutaneous injection in the neck"},
          {"name": "Iron Dextran", "dosage": "5 ml", "purpose": "Anti-anemia support", "instructions": "Deep intramuscular injection once"}
        ];
        preventions = ["Rotate pastures every 2-3 weeks", "Deworm dynamically based on worm count tests", "Maintain elevated feed bunks"];
      }

      _analysisResult = {
        "diseaseName": disease,
        "confidence": confidence,
        "severity": severity,
        "symptoms": symptoms,
        "causes": causes,
        "treatmentSteps": treatments,
        "medicines": medicines,
        "preventions": preventions
      };
      _isAnalyzing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF22C55E);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Disease Detection', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: widget.hideBackButton
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFF22C55E)),
                onPressed: () => Navigator.pop(context),
              ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Screen Header (matching image 1)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF8F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.healing,
                      color: Color(0xFF22C55E),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Disease Detection',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'AI-powered symptom analysis and diagnosis',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 1. UPLOAD ANIMAL IMAGE CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.camera_alt_outlined, color: Colors.grey, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Upload Animal Image',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropTarget(
                      onDragDone: (detail) {
                        if (detail.files.isNotEmpty) {
                          setState(() {
                            _selectedImage = File(detail.files.first.path);
                          });
                        }
                      },
                      child: GestureDetector(
                        onTap: _showImageSourceSelector,
                        child: CustomPaint(
                          painter: DashedBorderPainter(
                            color: const Color(0xFFD1D5DB),
                            strokeWidth: 1.2,
                            borderRadius: 16,
                          ),
                          child: Container(
                            height: 170,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFFAFAFA),
                            ),
                            child: _selectedImage != null
                                ? Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.file(
                                          _selectedImage!,
                                          width: double.infinity,
                                          height: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: GestureDetector(
                                          onTap: _clearSelection,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.close, color: Colors.red, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(Icons.upload_file_outlined, size: 38, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        'Click to upload or drag and drop',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF4B5563)),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'PNG, JPG up to 10MB',
                                        style: TextStyle(fontSize: 10.5, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. ANIMAL INFORMATION CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Animal Information',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Animal Type',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(10),
                        color: const Color(0xFFFAFAFA),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAnimalType,
                          isExpanded: true,
                          items: _animalTypes
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedAnimalType = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Additional Notes',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Describe any other observations...",
                        hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: const Color(0xFFFAFAFA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. OBSERVED SYMPTOMS CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Observed Symptoms',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 14),

                    // 2-column checklist
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 6,
                        childAspectRatio: 3.8,
                      ),
                      itemCount: _selectedSymptoms.keys.length,
                      itemBuilder: (context, index) {
                        final key = _selectedSymptoms.keys.elementAt(index);
                        final val = _selectedSymptoms[key]!;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedSymptoms[key] = !val;
                            });
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: val ? primaryGreen : Colors.grey, width: 1.5),
                                  color: val ? primaryGreen : Colors.transparent,
                                ),
                                child: val ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  key,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startAnalysis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Analyze Symptoms',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. ANALYSIS RESULTS CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'Analysis Results',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _isAnalyzing
                        ? _buildLoadingState()
                        : _analysisResult != null
                            ? _buildResultState()
                            : _buildEmptyState(),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 5. IMPORTANT DISCLAIMER CARD
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFEF3C7)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFD97706), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Important Disclaimer',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'This tool provides preliminary analysis only. Always consult a qualified veterinarian for accurate diagnosis and treatment. Early detection can save animal lives.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: const [
            Icon(Icons.healing_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Select symptoms and click "Analyze" to get disease predictions',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: const [
            CircularProgressIndicator(color: Color(0xFF22C55E)),
            SizedBox(height: 16),
            Text(
              'Analyzing symptoms with Gemini AI...',
              style: TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState() {
    final result = _analysisResult!;
    final disease = result['diseaseName'] ?? 'Unknown disease';
    final confidence = result['confidence'] ?? 80;
    final severity = (result['severity'] ?? 'MEDIUM').toString().toUpperCase();
    final treatmentSteps = List<String>.from(result['treatmentSteps'] ?? []);
    final medicines = List<dynamic>.from(result['medicines'] ?? []);
    final causes = List<String>.from(result['causes'] ?? []);
    final preventions = List<String>.from(result['preventions'] ?? []);

    Color severityColor = Colors.orange;
    Color severityBg = const Color(0xFFFFF7E6);
    if (severity == "LOW") {
      severityColor = const Color(0xFF22C55E);
      severityBg = const Color(0xFFEAF8F2);
    } else if (severity == "HIGH") {
      severityColor = Colors.redAccent;
      severityBg = const Color(0xFFFFF0F0);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Disease title + Confidence
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                disease,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "$confidence% match",
                style: const TextStyle(fontSize: 11, color: Color(0xFF0F5A3E), fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Severity level
        Row(
          children: [
            const Text(
              "Severity: ",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: severityBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                severity,
                style: TextStyle(fontSize: 11, color: severityColor, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Color(0xFFF3F4F6)),

        // Causes
        if (causes.isNotEmpty) ...[
          const Text(
            "Common Causes",
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          ...causes.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 6),
                      child: Icon(Icons.fiber_manual_record, size: 5, color: Colors.grey),
                    ),
                    Expanded(
                      child: Text(c, style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563))),
                    ),
                  ],
                ),
              )),
          const Divider(height: 24, color: Color(0xFFF3F4F6)),
        ],

        // Treatment steps
        const Text(
          "Step-by-Step Treatment Plan",
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 6),
        if (treatmentSteps.isEmpty)
          const Text("No steps provided.", style: TextStyle(fontSize: 12.5, color: Colors.grey))
        else
          ...treatmentSteps.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final val = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$idx. ",
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                  ),
                  Expanded(
                    child: Text(
                      val,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF374151), height: 1.35),
                    ),
                  ),
                ],
              ),
            );
          }),
        const Divider(height: 24, color: Color(0xFFF3F4F6)),

        // Medicines details (highly specific list)
        const Text(
          "Medicine Details & Prescription",
          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 8),
        if (medicines.isEmpty)
          const Text("No specific medicines recommended.", style: TextStyle(fontSize: 12.5, color: Colors.grey))
        else
          ...medicines.map((med) {
            final name = med['name'] ?? 'Unknown Medicine';
            final dosage = med['dosage'] ?? 'Refer to package dosage';
            final instructions = med['instructions'] ?? '';
            final purpose = med['purpose'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vaccines_outlined, color: Color(0xFF22C55E), size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (purpose.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        "Purpose: $purpose",
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563)),
                      ),
                    ),
                  Text(
                    "Dosage: $dosage",
                    style: const TextStyle(fontSize: 11.5, color: Color(0xFF4B5563), fontWeight: FontWeight.w500),
                  ),
                  if (instructions.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        "Instructions: $instructions",
                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B7280), fontStyle: FontStyle.italic),
                      ),
                    ),
                ],
              ),
            );
          }),
        const Divider(height: 24, color: Color(0xFFF3F4F6)),

        // Preventions
        if (preventions.isNotEmpty) ...[
          const Text(
            "Preventions & Management",
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          ...preventions.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 6),
                      child: Icon(Icons.check_circle_outline, size: 12, color: Color(0xFF22C55E)),
                    ),
                    Expanded(
                      child: Text(p, style: const TextStyle(fontSize: 12.5, color: Color(0xFF4B5563))),
                    ),
                  ],
                ),
              )),
        ],
      ],
    );
  }
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
