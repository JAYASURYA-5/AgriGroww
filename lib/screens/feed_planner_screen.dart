import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/app_state.dart';

class FeedPlannerScreen extends StatefulWidget {
  final bool hideBackButton;
  const FeedPlannerScreen({
    Key? key,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<FeedPlannerScreen> createState() => _FeedPlannerScreenState();
}

class _FeedPlannerScreenState extends State<FeedPlannerScreen> {
  String? _selectedAnimalType;
  String? _selectedAgeGroup;
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _countController = TextEditingController(text: "1");

  bool _isLoading = false;
  Map<String, dynamic>? _recommendationResult;
  String? _errorMessage;

  final List<String> _animalTypes = ["Cattle", "Buffalo", "Goats", "Sheep", "Chickens", "Pigs", "Horses"];
  final List<String> _ageGroups = ["Young", "Adult", "Lactating/Pregnant", "Senior"];

  Future<void> _calculateRecommendation() async {
    if (_selectedAnimalType == null || _selectedAgeGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select both Animal Type and Age Group!"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final apiKey = AppState().geminiApiKeyNotifier.value.trim();
    if (apiKey.isEmpty) {
      setState(() {
        _errorMessage = 'Gemini API Key is not configured. Go to settings to set your key. Using offline fallback...';
      });
      _loadOfflineRecommendation();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _recommendationResult = null;
    });

    try {
      final weightText = _weightController.text.trim();
      final weightPrompt = weightText.isNotEmpty ? "The average weight of the animal is $weightText kg." : "";

      final prompt = 
          "You are an expert veterinary nutritionist and livestock feed manager. "
          "Provide feed recommendations for a $_selectedAnimalType in the $_selectedAgeGroup age group. "
          "$weightPrompt "
          "Provide the feed plan recommendation details. You MUST respond with a strict JSON object containing the following keys. "
          "Do not include markdown code block formatting (like ```json) in your raw response: "
          "{"
          "  \"recommendedFeed\": \"Name of recommended feed mix (e.g., Concentrate Mix + Dry/Green Fodder, Layer Mash, Legume Hay)\","
          "  \"dailyQuantity\": \"Recommended feed weight range daily per animal (e.g., 8-12 kg/day, 120g/day)\","
          "  \"feedingFrequency\": \"Recommended frequency (e.g., 2-3 times daily, Ad-libitum)\","
          "  \"dailyCostPerAnimal\": \"An integer value representing the estimated feed cost per animal per day in Indian Rupees (INR) e.g., 350\","
          "  \"feedingTips\": [\"tip 1\", \"tip 2\", \"tip 3\"]"
          "}";

      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey');

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
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
      ).timeout(const Duration(seconds: 8));

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
          _recommendationResult = parsedResult;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'API Error (${response.statusCode}). Using local fallback.';
        });
        _loadOfflineRecommendation();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection timeout/error: $e. Using local fallback.';
      });
      _loadOfflineRecommendation();
    }
  }

  void _loadOfflineRecommendation() {
    setState(() {
      String recommendedFeed = "Concentrate Mix + Dry/Green Fodder";
      String dailyQuantity = "8-12 kg/day";
      String feedingFrequency = "2-3 times daily";
      int dailyCost = 350;
      List<String> tips = [
        "Balance roughage and concentrate ratio",
        "Add mineral mixture 50g/day",
        "Adjust feed based on individual milk production yield"
      ];

      final isYoung = _selectedAgeGroup == "Young";

      if (_selectedAnimalType == "Cattle" || _selectedAnimalType == "Buffalo") {
        recommendedFeed = "Concentrate Mix + Dry/Green Fodder";
        dailyQuantity = isYoung ? "3-5 kg/day" : "8-12 kg/day";
        feedingFrequency = "2-3 times daily";
        dailyCost = isYoung ? 150 : 350;
        tips = [
          "Balance roughage and concentrate ratio",
          "Add mineral mixture 50g/day",
          "Adjust feed based on individual milk production yield"
        ];
      } else if (_selectedAnimalType == "Goats" || _selectedAnimalType == "Sheep") {
        recommendedFeed = "Legume Hay + Energy Concentrates";
        dailyQuantity = isYoung ? "0.8-1.2 kg/day" : "2-3 kg/day";
        feedingFrequency = "2 times daily";
        dailyCost = isYoung ? 40 : 100;
        tips = [
          "Provide high-quality browse or pasture whenever possible",
          "Ensure fresh water is available constantly",
          "Monitor mineral levels (avoid high copper for sheep)"
        ];
      } else if (_selectedAnimalType == "Chickens") {
        recommendedFeed = isYoung ? "Chick Starter Crumble" : "Layer Mash / Feed";
        dailyQuantity = isYoung ? "50-70 g/day" : "110-120 g/day";
        feedingFrequency = "Ad-libitum (Continuous)";
        dailyCost = 7;
        tips = [
          "Provide insoluble grit to help with food grinding/digestion",
          "Keep feeders clean and dry to prevent mold growth",
          "Supplement with calcium/oyster shells for layer hens"
        ];
      } else {
        recommendedFeed = "Standard Balanced Ration + Greens";
        dailyQuantity = isYoung ? "2-4 kg/day" : "6-10 kg/day";
        feedingFrequency = "2 times daily";
        dailyCost = isYoung ? 100 : 220;
        tips = [
          "Maintain consistent feeding schedule to prevent digestive stress",
          "Introduce new feed batches slowly over 7-10 days",
          "Provide salt blocks / mineral licks in pastures"
        ];
      }

      _recommendationResult = {
        "recommendedFeed": recommendedFeed,
        "dailyQuantity": dailyQuantity,
        "feedingFrequency": feedingFrequency,
        "dailyCostPerAnimal": dailyCost,
        "feedingTips": tips
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF00FF66); // Neon Green matching screenshots

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Feed Planner', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Header Row (matching mockup layout)
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEAF8F2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.restaurant_menu,
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
                          'Feed Planner',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                            fontFamily: 'serif',
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Optimize nutrition and manage feed costs',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Calculate Feed Form Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
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
                        Icon(Icons.calculate_outlined, color: Color(0xFF374151), size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Calculate Feed',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Animal Type Dropdown
                    const Text('Animal Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFFAFAFA),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAnimalType,
                          hint: const Text('Select animal type', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          isExpanded: true,
                          items: _animalTypes
                              .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAnimalType = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Age Group Dropdown
                    const Text('Age Group', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFFAFAFA),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedAgeGroup,
                          hint: const Text('Select age group', style: TextStyle(color: Colors.grey, fontSize: 14)),
                          isExpanded: true,
                          items: _ageGroups
                              .map((group) => DropdownMenuItem(value: group, child: Text(group)))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedAgeGroup = value;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weight TextField
                    const Text('Weight (kg) - Optional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _weightController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Enter weight",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: const Color(0xFFFAFAFA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Number of Animals TextField
                    const Text('Number of Animals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _countController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "1",
                        hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        fillColor: const Color(0xFFFAFAFA),
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Calculate Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _calculateRecommendation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF66), // Vibrant Neon Green
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Calculate Recommendation',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Dynamic Output: Feed Recommendation
              _buildRecommendationPanel(primaryGreen),
              const SizedBox(height: 24),

              // Summer Season Tips Card
              _buildSummerTipsCard(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationPanel(Color primaryGreen) {
    if (_recommendationResult == null) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Select animal type and age group to get feed recommendations",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    final result = _recommendationResult!;
    final feed = result["recommendedFeed"] ?? "";
    final qty = result["dailyQuantity"] ?? "";
    final freq = result["feedingFrequency"] ?? "";
    final dailyCostPerAnimal = result["dailyCostPerAnimal"] ?? 350;
    final List<dynamic> tips = result["feedingTips"] ?? [];

    final int animalCount = int.tryParse(_countController.text.trim()) ?? 1;
    final int monthlyCost = dailyCostPerAnimal * animalCount * 30;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.eco_outlined, color: Colors.green, size: 20),
              SizedBox(width: 8),
              Text(
                'Feed Recommendation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 4 Grid Blocks
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.45,
            children: [
              _buildResultGridTile("Recommended Feed", feed),
              _buildResultGridTile("Daily Quantity (per animal)", qty),
              _buildResultGridTile("Feeding Frequency", freq),
              _buildResultGridTile("Daily Cost (per animal)", "₹ $dailyCostPerAnimal"),
            ],
          ),
          const SizedBox(height: 16),

          // Monthly Cost Estimation Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Monthly Cost Estimation",
                  style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  "₹ $monthlyCost",
                  style: const TextStyle(color: Color(0xFF11382A), fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  "For $animalCount animal(s) * 30 days",
                  style: TextStyle(color: Colors.grey[700], fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Feeding Tips list
          const Text(
            "Feeding Tips",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
          ),
          const SizedBox(height: 8),
          ...tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("• ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.35),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildResultGridTile(String title, String val) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSummerTipsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Summer Season Tips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.1,
            children: [
              _buildSummerTipTile("1", "Increase water availability by 20-30%"),
              _buildSummerTipTile("2", "Provide shade and cooling systems"),
              _buildSummerTipTile("3", "Feed during cooler hours"),
              _buildSummerTipTile("4", "Include electrolytes in water"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummerTipTile(String number, String text) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE5E7EB)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF8F2),
              shape: BoxShape.circle,
            ),
            child: Text(
              number,
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11, color: Color(0xFF374151), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}
