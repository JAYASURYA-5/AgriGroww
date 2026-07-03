import 'package:flutter/material.dart';

class CropInfo {
  final List<String> preferredSoils;
  final List<String> preferredClimates;
  final String growthDuration;
  final List<CompanionInfo> companions;

  const CropInfo({
    required this.preferredSoils,
    required this.preferredClimates,
    required this.growthDuration,
    required this.companions,
  });
}

class CompanionInfo {
  final String name;
  final String info;
  final String yieldBoost;
  final String spacing;
  final String season;
  final String waterNeed;
  final String nutrients;

  const CompanionInfo({
    required this.name,
    required this.info,
    required this.yieldBoost,
    required this.spacing,
    required this.season,
    required this.waterNeed,
    required this.nutrients,
  });
}

class IntercropAdvisorScreen extends StatefulWidget {
  const IntercropAdvisorScreen({Key? key}) : super(key: key);

  @override
  State<IntercropAdvisorScreen> createState() => _IntercropAdvisorScreenState();
}

class _IntercropAdvisorScreenState extends State<IntercropAdvisorScreen> {
  String? _selectedCrop;
  String? _selectedSoil;
  String? _selectedClimate;
  CropInfo? _calculatedCropInfo;
  String? _selectedCompanionName;

  final List<Map<String, String>> _crops = [
    {'name': 'Wheat', 'emoji': '🌾'},
    {'name': 'Rice', 'emoji': '🌾'},
    {'name': 'Corn/Maize', 'emoji': '🌽'},
    {'name': 'Tomato', 'emoji': '🍅'},
    {'name': 'Cotton', 'emoji': '☁️'},
    {'name': 'Sugarcane', 'emoji': '🎋'},
  ];

  final List<String> _soils = [
    'Loamy Soil - Best all-purpose soil',
    'Clay Soil - Good water retention',
    'Sandy Soil - Good drainage',
    'Alluvial Soil - Rich in nutrients',
  ];

  final List<String> _climates = [
    'Tropical (25-35°C)',
    'Subtropical (15-30°C)',
    'Temperate (10-25°C)',
    'Arid/Semi-arid (20-40°C)',
  ];

  final Map<String, CropInfo> _cropData = {
    'Wheat': const CropInfo(
      preferredSoils: ['Loamy', 'Alluvial'],
      preferredClimates: ['Temperate', 'Subtropical'],
      growthDuration: '120-150 days',
      companions: [
        CompanionInfo(
          name: 'Chickpea',
          info: 'Nitrogen fixation, complementary root depth',
          yieldBoost: '+15-20%',
          spacing: '30cm between rows',
          season: 'Winter',
          waterNeed: 'Low',
          nutrients: 'Adds nitrogen to soil',
        ),
        CompanionInfo(
          name: 'Mustard',
          info: 'Pest repellent, different nutrient needs',
          yieldBoost: '+12-18%',
          spacing: '25cm between rows',
          season: 'Winter',
          waterNeed: 'Moderate',
          nutrients: 'Light feeder',
        ),
        CompanionInfo(
          name: 'Lentil',
          info: 'Nitrogen enrichment, weed suppression',
          yieldBoost: '+18-25%',
          spacing: '20cm between rows',
          season: 'Winter',
          waterNeed: 'Low',
          nutrients: 'Nitrogen-fixing legume',
        ),
      ],
    ),
    'Rice': const CropInfo(
      preferredSoils: ['Clay', 'Alluvial'],
      preferredClimates: ['Tropical', 'Subtropical'],
      growthDuration: '100-130 days',
      companions: [
        CompanionInfo(
          name: 'Cowpea',
          info: 'Nitrogen fixation along bunds, supplementary forage',
          yieldBoost: '+12-15%',
          spacing: '15cm spacing',
          season: 'Kharif / Monsoon',
          waterNeed: 'Moderate',
          nutrients: 'Enriches soil nitrogen',
        ),
        CompanionInfo(
          name: 'Black Gram',
          info: 'Improves soil health, weed control',
          yieldBoost: '+10-14%',
          spacing: '20cm spacing',
          season: 'Pre-monsoon',
          waterNeed: 'Low',
          nutrients: 'Organic matter builder',
        ),
      ],
    ),
    'Corn/Maize': const CropInfo(
      preferredSoils: ['Loamy', 'Alluvial'],
      preferredClimates: ['Tropical', 'Subtropical'],
      growthDuration: '90-110 days',
      companions: [
        CompanionInfo(
          name: 'Climbing Beans',
          info: 'Uses corn stalks as trellises, nitrogen fixation',
          yieldBoost: '+25-30%',
          spacing: '45cm between plants',
          season: 'Summer',
          waterNeed: 'Moderate',
          nutrients: 'Strong nitrogen contributor',
        ),
        CompanionInfo(
          name: 'Soybean',
          info: 'Ground cover reduces soil moisture loss',
          yieldBoost: '+15-22%',
          spacing: '30cm rows',
          season: 'Summer',
          waterNeed: 'Moderate',
          nutrients: 'High protein residues',
        ),
        CompanionInfo(
          name: 'Pumpkin',
          info: 'Large leaves suppress weeds, locks moisture',
          yieldBoost: '+10-15%',
          spacing: '1.5m spacing',
          season: 'Rainy',
          waterNeed: 'High',
          nutrients: 'Light feeder',
        ),
      ],
    ),
    'Tomato': const CropInfo(
      preferredSoils: ['Loamy', 'Sandy'],
      preferredClimates: ['Subtropical', 'Temperate'],
      growthDuration: '70-90 days',
      companions: [
        CompanionInfo(
          name: 'Marigold',
          info: 'Root exudates repel nematodes, deters whiteflies',
          yieldBoost: '+20-30% Pest Reduction',
          spacing: '30cm spacing',
          season: 'Year-round',
          waterNeed: 'Moderate',
          nutrients: 'No significant draw',
        ),
        CompanionInfo(
          name: 'Basil',
          info: 'Improves tomato taste, repels flies & thrips',
          yieldBoost: '+15-20% Flavor Boost',
          spacing: '20cm spacing',
          season: 'Warm Season',
          waterNeed: 'Moderate',
          nutrients: 'Moderate drawer',
        ),
        CompanionInfo(
          name: 'Lettuce',
          info: 'Uses shade from tomatoes to grow in heat',
          yieldBoost: '+10-15% Multi-crop',
          spacing: '15cm spacing',
          season: 'Cool/Mild Season',
          waterNeed: 'Moderate',
          nutrients: 'Light feeder',
        ),
      ],
    ),
    'Cotton': const CropInfo(
      preferredSoils: ['Clay', 'Alluvial'],
      preferredClimates: ['Tropical', 'Arid/Semi-arid'],
      growthDuration: '150-180 days',
      companions: [
        CompanionInfo(
          name: 'Groundnut',
          info: 'Cover crop suppresses weeds, fixes nitrogen',
          yieldBoost: '+18-25%',
          spacing: '30cm rows',
          season: 'Kharif',
          waterNeed: 'Low',
          nutrients: 'Enriches soil',
        ),
        CompanionInfo(
          name: 'Cowpea',
          info: 'Attracts beneficial predatory insects',
          yieldBoost: '+12-18%',
          spacing: '25cm spacing',
          season: 'Warm Season',
          waterNeed: 'Low',
          nutrients: 'Adds nitrogen',
        ),
      ],
    ),
    'Sugarcane': const CropInfo(
      preferredSoils: ['Loamy', 'Alluvial'],
      preferredClimates: ['Tropical', 'Subtropical'],
      growthDuration: '300-360 days',
      companions: [
        CompanionInfo(
          name: 'Soybean',
          info: 'Quick crop harvested before sugarcane canopy closes',
          yieldBoost: '+15-20% Land Use',
          spacing: 'Inter-row planting',
          season: 'Kharif',
          waterNeed: 'Moderate',
          nutrients: 'Adds nitrogen',
        ),
        CompanionInfo(
          name: 'Mung Bean',
          info: 'Short duration, fits in early row spacing',
          yieldBoost: '+12-18% Additional Crop',
          spacing: '2 rows in between',
          season: 'Spring',
          waterNeed: 'Low',
          nutrients: 'Light drawer',
        ),
      ],
    ),
  };

  void _calculateSuggestions() {
    if (_selectedCrop == null || _selectedSoil == null || _selectedClimate == null) return;
    setState(() {
      _calculatedCropInfo = _cropData[_selectedCrop];
      _selectedCompanionName = null;
    });
  }

  bool _hasSoilMismatch() {
    if (_selectedCrop == null || _selectedSoil == null) return false;
    final info = _cropData[_selectedCrop];
    if (info == null) return false;
    for (final prefSoil in info.preferredSoils) {
      if (_selectedSoil!.toLowerCase().contains(prefSoil.toLowerCase())) {
        return false;
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF22C55E);
    final secondaryGreen = const Color(0xFF10B981);
    final themeBg = const Color(0xFFF4F6F8);

    return Scaffold(
      backgroundColor: themeBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryGreen, secondaryGreen],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. HEADER CARD WITH COMPANION PILLS
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [primaryGreen, secondaryGreen],
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.eco, color: primaryGreen, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Intercropping Advisor',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Smart companion planting for maximum yield',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildPillTag(Icons.trending_up, 'Increase Yield'),
                      const SizedBox(width: 8),
                      _buildPillTag(Icons.opacity, 'Save Water'),
                      const SizedBox(width: 8),
                      _buildPillTag(Icons.eco, 'Improve Soil'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. MAIN DETAILS SELECTION FORM
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, color: primaryGreen, size: 20),
                        const SizedBox(width: 6),
                        const Text(
                          'Select Your Farming Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Main Crop *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _crops.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final crop = _crops[index];
                        final isSelected = _selectedCrop == crop['name'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCrop = crop['name'];
                              _calculatedCropInfo = null;
                              _selectedCompanionName = null;
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.white : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? primaryGreen : Colors.grey[200]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  crop['emoji']!,
                                  style: const TextStyle(fontSize: 32),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  crop['name']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? primaryGreen : const Color(0xFF475569),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Icon(Icons.waves, color: Colors.black45, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Soil Type',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedSoil,
                          hint: const Text('Select soil type'),
                          items: _soils.map((soil) {
                            return DropdownMenuItem(
                              value: soil,
                              child: Text(soil),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedSoil = val;
                              _calculatedCropInfo = null;
                              _selectedCompanionName = null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: const [
                        Icon(Icons.wb_sunny_outlined, color: Colors.black45, size: 18),
                        SizedBox(width: 6),
                        Text(
                          'Climate Zone',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedClimate,
                          hint: const Text('Select climate'),
                          items: _climates.map((climate) {
                            return DropdownMenuItem(
                              value: climate,
                              child: Text(climate),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedClimate = val;
                              _calculatedCropInfo = null;
                              _selectedCompanionName = null;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: (_selectedCrop != null && _selectedSoil != null && _selectedClimate != null)
                          ? _calculateSuggestions
                          : null,
                      icon: const Icon(Icons.menu_book, color: Colors.white, size: 18),
                      label: const Text(
                        'Get Intercropping Suggestions',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        disabledBackgroundColor: Colors.grey[350],
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. SUGGESTIONS OUTPUT CARD PANEL
            if (_calculatedCropInfo != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Builder(builder: (context) {
                        final selectedCropEmoji = _crops.firstWhere(
                          (c) => c['name'] == _selectedCrop,
                          orElse: () => {'emoji': '🌱'},
                        )['emoji'];

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Text(
                                selectedCropEmoji ?? '🌱',
                                style: const TextStyle(fontSize: 36),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Companion\nCrops for $_selectedCrop',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'These crops work best when planted alongside $_selectedCrop',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 20),

                      if (_hasSoilMismatch()) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF0),
                            borderRadius: BorderRadius.circular(12),
                            border: const Border(
                              left: BorderSide(
                                color: Color(0xFFFBC02D),
                                width: 4,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning,
                                color: Color(0xFFD97706),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF92400E),
                                      height: 1.4,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Note on Soil: ',
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: '$_selectedCrop usually prefers ${_calculatedCropInfo!.preferredSoils.join(" or ")} soil. You selected ${_selectedSoil!.split(" - ")[0]}.',
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Crop Information',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Best Soil Types',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _calculatedCropInfo!.preferredSoils.map((soil) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  soil,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Best Climate',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _calculatedCropInfo!.preferredClimates.map((climate) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDBEAFE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  climate.split(' (')[0],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              )).toList(),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Growth Duration',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF5E6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _calculatedCropInfo!.growthDuration,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF9333EA),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      Column(
                        children: _calculatedCropInfo!.companions.map((companion) {
                          final isSelected = _selectedCompanionName == companion.name;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.eco,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      companion.name,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFF64748B),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        companion.info,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.trending_up,
                                        color: Color(0xFF16A34A),
                                        size: 18,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Yield Increase: ${companion.yieldBoost}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                GridView.count(
                                  crossAxisCount: 2,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 2.2,
                                  children: [
                                    _buildMetricTile(
                                      title: 'Spacing',
                                      value: companion.spacing,
                                      bgColor: const Color(0xFFEFF6FF),
                                      titleColor: const Color(0xFF2563EB),
                                    ),
                                    _buildMetricTile(
                                      title: 'Season',
                                      value: companion.season,
                                      bgColor: const Color(0xFFFFFBEB),
                                      titleColor: const Color(0xFFD97706),
                                    ),
                                    _buildMetricTile(
                                      title: 'Water Need',
                                      value: companion.waterNeed,
                                      bgColor: const Color(0xFFF0FDFA),
                                      titleColor: const Color(0xFF0D9488),
                                    ),
                                    _buildMetricTile(
                                      title: 'Nutrients',
                                      value: companion.nutrients,
                                      bgColor: const Color(0xFFFAF5FF),
                                      titleColor: const Color(0xFF7C3AED),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Divider(color: Colors.grey[200]),
                                const SizedBox(height: 12),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCompanionName = isSelected ? null : companion.name;
                                    });
                                  },
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        isSelected ? Icons.check_circle : Icons.check_circle_outline,
                                        color: const Color(0xFF10B981),
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        isSelected ? 'Selected Companion' : 'Select This Companion',
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 4. WHY INTERCROPPING? EDUCATIONAL BLOCK
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Why Intercropping?',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildBenefitCard(
                      icon: Icons.opacity,
                      title: 'Water Efficiency',
                      description: 'Better moisture retention and reduced irrigation needs through complementary root systems',
                      iconBgColor: const Color(0xFF3B82F6),
                      cardBgColor: const Color(0xFFEFF6FF),
                    ),
                    _buildBenefitCard(
                      icon: Icons.calendar_month,
                      title: 'Extended Season',
                      description: 'Multiple harvests throughout the growing season with staggered planting schedules',
                      iconBgColor: const Color(0xFFF59E0B),
                      cardBgColor: const Color(0xFFFFFBEB),
                    ),
                    _buildBenefitCard(
                      icon: Icons.eco,
                      title: 'Soil Health',
                      description: 'Improved soil structure and nutrient balance through diverse root systems',
                      iconBgColor: const Color(0xFF8B5CF6),
                      cardBgColor: const Color(0xFFFAF5FF),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          '💚',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Sustainable farming for a better tomorrow',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
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

  Widget _buildPillTag(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color bgColor,
    required Color titleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: titleColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required String title,
    required String description,
    required Color iconBgColor,
    required Color cardBgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF475569),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
