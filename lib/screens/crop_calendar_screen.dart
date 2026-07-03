import 'package:flutter/material.dart';
import '../services/ad_service.dart';

class CropData {
  final String name;
  final String season;
  final String sowingTime;
  final String harvestingTime;
  final int duration;
  final String bestSoil;

  CropData({
    required this.name,
    required this.season,
    required this.sowingTime,
    required this.harvestingTime,
    required this.duration,
    required this.bestSoil,
  });
}

class CropCalendarScreen extends StatefulWidget {
  const CropCalendarScreen({Key? key}) : super(key: key);

  @override
  State<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends State<CropCalendarScreen> {
  final List<CropData> crops = [
    // KHARIF Crops
    CropData(
      name: 'Rice',
      season: 'KHARIF',
      sowingTime: 'June-July',
      harvestingTime: 'October-November',
      duration: 120,
      bestSoil: 'Clay/Loamy',
    ),
    CropData(
      name: 'Maize',
      season: 'KHARIF',
      sowingTime: 'June-July',
      harvestingTime: 'September-October',
      duration: 90,
      bestSoil: 'Loamy/Sandy',
    ),
    CropData(
      name: 'Soybean',
      season: 'KHARIF',
      sowingTime: 'June-July',
      harvestingTime: 'October-November',
      duration: 90,
      bestSoil: 'Clay/Loamy',
    ),
    CropData(
      name: 'Groundnut',
      season: 'KHARIF',
      sowingTime: 'June-July',
      harvestingTime: 'September-October',
      duration: 110,
      bestSoil: 'Loamy/Sandy',
    ),
    CropData(
      name: 'Bajra',
      season: 'KHARIF',
      sowingTime: 'July-August',
      harvestingTime: 'October-November',
      duration: 90,
      bestSoil: 'Sandy/Loamy',
    ),
    CropData(
      name: 'Jowar',
      season: 'KHARIF',
      sowingTime: 'July-August',
      harvestingTime: 'October-November',
      duration: 120,
      bestSoil: 'Clay/Loamy',
    ),

    // RABI Crops
    CropData(
      name: 'Wheat',
      season: 'RABI',
      sowingTime: 'November-December',
      harvestingTime: 'April-May',
      duration: 120,
      bestSoil: 'Loamy',
    ),
    CropData(
      name: 'Chickpea',
      season: 'RABI',
      sowingTime: 'November-December',
      harvestingTime: 'March-April',
      duration: 120,
      bestSoil: 'Clay/Loamy',
    ),
    CropData(
      name: 'Mustard',
      season: 'RABI',
      sowingTime: 'October-November',
      harvestingTime: 'March-April',
      duration: 150,
      bestSoil: 'Clay/Loamy',
    ),
    CropData(
      name: 'Barley',
      season: 'RABI',
      sowingTime: 'November-December',
      harvestingTime: 'April-May',
      duration: 130,
      bestSoil: 'Loamy',
    ),
    CropData(
      name: 'Linseed',
      season: 'RABI',
      sowingTime: 'October-November',
      harvestingTime: 'March-April',
      duration: 150,
      bestSoil: 'Loamy',
    ),

    // YEAR-ROUND / PERENNIAL Crops
    CropData(
      name: 'Cotton',
      season: 'YEAR-ROUND',
      sowingTime: 'April-May',
      harvestingTime: 'October-December',
      duration: 180,
      bestSoil: 'Black/Loamy',
    ),
    CropData(
      name: 'Sugarcane',
      season: 'YEAR-ROUND',
      sowingTime: 'February-March',
      harvestingTime: 'December-March',
      duration: 365,
      bestSoil: 'Loamy',
    ),
    CropData(
      name: 'Tea',
      season: 'YEAR-ROUND',
      sowingTime: 'Year-round',
      harvestingTime: 'Year-round',
      duration: 365,
      bestSoil: 'Well-drained Loamy',
    ),
    CropData(
      name: 'Coffee',
      season: 'YEAR-ROUND',
      sowingTime: 'Year-round',
      harvestingTime: 'September-December',
      duration: 365,
      bestSoil: 'Well-drained Loamy',
    ),
    CropData(
      name: 'Banana',
      season: 'YEAR-ROUND',
      sowingTime: 'Year-round',
      harvestingTime: 'Year-round',
      duration: 365,
      bestSoil: 'Well-drained Loamy',
    ),

    // Summer Crops
    CropData(
      name: 'Tomato',
      season: 'Summer',
      sowingTime: 'February-March',
      harvestingTime: 'May-June',
      duration: 90,
      bestSoil: 'Loamy',
    ),
    CropData(
      name: 'Cucumber',
      season: 'Summer',
      sowingTime: 'February-March',
      harvestingTime: 'April-May',
      duration: 60,
      bestSoil: 'Loamy',
    ),
    CropData(
      name: 'Watermelon',
      season: 'Summer',
      sowingTime: 'March-April',
      harvestingTime: 'June-July',
      duration: 90,
      bestSoil: 'Sandy/Loamy',
    ),
  ];

  String selectedSeason = 'All';
  String searchQuery = '';
  TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CropData> getFilteredCrops() {
    List<CropData> filtered = crops;

    // Filter by season
    if (selectedSeason != 'All') {
      filtered = filtered.where((crop) => crop.season == selectedSeason).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((crop) => crop.name.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();
    }

    return filtered;
  }

  Color getSeasonColor(String season) {
    switch (season) {
      case 'KHARIF':
        return const Color(0xFF22C55E);
      case 'RABI':
        return const Color(0xFFF59E0B);
      case 'YEAR-ROUND':
        return const Color(0xFF8B5CF6);
      case 'Summer':
        return const Color(0xFFF97316);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Crop Calendar',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Guide Section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00BCD4),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crop Calendar Guide',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0277BD),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Plan your agricultural activities throughout the year with planting and harvesting schedules for major crops.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Field
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search crops by name...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF22C55E),
                    size: 22,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            setState(() {
                              searchQuery = '';
                            });
                          },
                          child: const Icon(
                            Icons.close,
                            color: Colors.grey,
                            size: 20,
                          ),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF22C55E),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),

            // Season Filter Chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Season',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ['All', 'KHARIF', 'RABI', 'Summer', 'YEAR-ROUND'].map((season) {
                      final isSelected = selectedSeason == season;
                      return FilterChip(
                        label: Text(season),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            selectedSeason = season;
                          });
                        },
                        backgroundColor: Colors.white,
                        selectedColor: const Color(0xFF22C55E),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.transparent : const Color(0xFFE5E7EB),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Crops List
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crops (${getFilteredCrops().length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  getFilteredCrops().isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.search_off,
                                  size: 64,
                                  color: Colors.grey[300],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No crops found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  searchQuery.isNotEmpty
                                      ? 'Try searching for a different crop'
                                      : 'Try selecting a different season',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: getFilteredCrops().length,
                          itemBuilder: (context, index) {
                            final crop = getFilteredCrops()[index];
                            return CropCalendarCard(
                              crop: crop,
                              seasonColor: getSeasonColor(crop.season),
                              onTap: () {
                                showCropDetailsBottomSheet(context, crop);
                              },
                            );
                          },
                        ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AdService.getNativeAdWidget(height: 90),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void showCropDetailsBottomSheet(BuildContext context, CropData crop) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => CropDetailsSheet(crop: crop),
    );
  }
}

class CropCalendarCard extends StatelessWidget {
  final CropData crop;
  final Color seasonColor;
  final VoidCallback onTap;

  const CropCalendarCard({
    Key? key,
    required this.crop,
    required this.seasonColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Crop Name and Season Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  crop.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: seasonColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    crop.season,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Crop Details Grid
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    label: 'Sowing',
                    value: crop.sowingTime,
                    icon: Icons.cloud_upload_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailItem(
                    label: 'Harvest',
                    value: crop.harvestingTime,
                    icon: Icons.grain,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    label: 'Duration',
                    value: '${crop.duration} days',
                    icon: Icons.schedule,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DetailItem(
                    label: 'Best Soil',
                    value: crop.bestSoil,
                    icon: Icons.landscape,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Tap for more info
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Tap for more info',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: Colors.grey[500],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _DetailItem({
    Key? key,
    required this.label,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: const Color(0xFF22C55E),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class CropDetailsSheet extends StatelessWidget {
  final CropData crop;

  const CropDetailsSheet({Key? key, required this.crop}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                crop.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(
                  Icons.close,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Details Table
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2),
              1: FlexColumnWidth(3),
            },
            children: [
              _buildTableRow('Crop Season', crop.season, Colors.grey[100]!),
              _buildTableRow('Sowing Time', crop.sowingTime, Colors.white),
              _buildTableRow('Harvesting Time', crop.harvestingTime, Colors.grey[100]!),
              _buildTableRow('Duration', '${crop.duration} days', Colors.white),
              _buildTableRow('Best Soil Type', crop.bestSoil, Colors.grey[100]!),
            ],
          ),

          const SizedBox(height: 20),

          // Tips Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF22C55E),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Growing Tips',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF22C55E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getGrowingTips(crop.name),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Close Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String label, String value, Color backgroundColor) {
    return TableRow(
      decoration: BoxDecoration(
        color: backgroundColor,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  String _getGrowingTips(String cropName) {
    final tips = {
      'Rice':
          'Requires flooded fields. Maintain standing water during growing season. Apply fertilizer at tillering and panicle initiation stages.',
      'Wheat':
          'Requires cool season. Sow in well-prepared field. Irrigate at critical growth stages. Control weeds by timely hoeing.',
      'Cotton':
          'Requires high temperature. Space 90x60cm. Apply FYM before sowing. Spray pesticides for pest control.',
      'Sugarcane':
          'Requires long growing period. Plant on ridges. Apply high nitrogen fertilizer. Mulch with crop residues.',
      'Maize':
          'Spacing 60x20cm. Apply balanced fertilizer. Provide irrigation during critical stages. Harvest at milk stage.',
      'Soybean':
          'Inoculate seeds with rhizobium. Space 45x10cm. Provide weed management. Harvest at physiological maturity.',
      'Groundnut':
          'Space 30x10cm. Pegging is crucial. Use gypsum at flowering stage. Harvest after foliage turns yellow.',
      'Chickpea':
          'Sow in lines 30cm apart. Require cool season. Provide light irrigation. Control ascochyta blight.',
      'Banana':
          'Spacing 2.5x2.5m. Requires year-round irrigation. Remove suckers regularly. Mulch for moisture retention.',
      'Tomato':
          'Transplant seedlings 60x45cm. Provide support and staking. Train to 2-3 stems. Harvest at full red stage.',
    };
    return tips[cropName] ??
        'Follow standard agricultural practices and consult local agricultural extension office for specific guidance.';
  }
}
