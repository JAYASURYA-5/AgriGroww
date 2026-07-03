import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/livestock_storage.dart';
import '../services/ad_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  final bool hideBackButton;
  const AnalyticsDashboardScreen({
    Key? key,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  List<Map<String, dynamic>> _animals = [];
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  // Dynamic statistics
  double _totalMilkYield = 0.0;
  int _eggsCollected = 0;
  double _feedEfficiency = 0.0;
  double _healthScore = 0.0;

  // Chart data calculations
  int _cattleCount = 45;
  int _goatsCount = 35;
  int _sheepCount = 28;
  int _chickensCount = 30;
  int _pigsCount = 12;
  int _horsesCount = 6;

  // Monthly values for June (dynamic)
  int _healthyCountJun = 148;
  int _attentionCountJun = 6;
  int _criticalCountJun = 2;

  // Extra logged yield to simulate immediate update
  double _simulatedMilkAdd = 0.0;
  int _simulatedEggsAdd = 0;

  // Interactive chart selections
  int? _selectedMilkIndex;
  int? _selectedEggIndex;
  int? _selectedDistributionIndex;
  int? _selectedHealthIndex;
  int? _selectedFeedIndex;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final animals = await LivestockStorageService.getAnimals();
    final records = await LivestockStorageService.getHealthRecords();

    // Calculate dynamic parameters based on active database entries
    final cattle = animals.where((a) => a["type"] == "Cattle").length;
    final goats = animals.where((a) => a["type"] == "Goats").length;
    final sheep = animals.where((a) => a["type"] == "Sheep").length;
    final chickens = animals.where((a) => a["type"] == "Chickens").length;
    final pigs = animals.where((a) => a["type"] == "Pigs").length;
    final horses = animals.where((a) => a["type"] == "Horses").length;

    final healthy = animals.where((a) => a["status"] == "Healthy").length;
    final attention = animals.where((a) => a["status"] == "Attention" || a["status"] == "Needs Attention").length;
    final critical = animals.where((a) => a["status"] == "Critical").length;

    setState(() {
      _animals = animals;
      _records = records;
      _isLoading = false;

      _cattleCount = cattle;
      _goatsCount = goats;
      _sheepCount = sheep;
      _chickensCount = chickens;
      _pigsCount = pigs;
      _horsesCount = horses;

      _healthyCountJun = healthy;
      _attentionCountJun = attention;
      _criticalCountJun = critical;

      // Dynamic summary stats
      _totalMilkYield = (cattle * 25.0);
      _eggsCollected = (chickens * 5);
      
      final totalForScore = healthy + attention + critical;
      if (totalForScore > 0) {
        _healthScore = (healthy / totalForScore) * 100;
      } else {
        _healthScore = 0.0;
      }

      if (animals.isNotEmpty) {
        _feedEfficiency = 92.0;
      } else {
        _feedEfficiency = 0.0;
      }
    });
  }

  void _showLogProductionSheet() {
    final milkController = TextEditingController();
    final eggController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Log Production Yield",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F2E22)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Add today's output to update report charts instantly.",
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              const Text(
                "Extra Milk Collected (Liters)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: milkController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "e.g., 25",
                  suffixText: "L",
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Extra Eggs Collected (Pieces)",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF374151)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: eggController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: "e.g., 12",
                  suffixText: "pcs",
                  suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                  filled: true,
                  fillColor: const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final milkStr = milkController.text.trim();
                        final eggStr = eggController.text.trim();

                        setState(() {
                          if (milkStr.isNotEmpty) {
                            _simulatedMilkAdd += double.tryParse(milkStr) ?? 0.0;
                          }
                          if (eggStr.isNotEmpty) {
                            _simulatedEggsAdd += int.tryParse(eggStr) ?? 0;
                          }
                        });

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Intake data added. Charts updated!"),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        "Save Entry",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnimals = _animals.isNotEmpty;
    final primaryGreen = const Color(0xFF22C55E);
    final isWide = MediaQuery.of(context).size.width > 800;
    
    // Sum dynamically computed values + user entry
    final displayMilk = _totalMilkYield + _simulatedMilkAdd;
    final displayEggs = _eggsCollected + _simulatedEggsAdd;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Analytics', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Bar (matching image 1)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAF8F2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bar_chart,
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
                                'Analytics Dashboard',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Comprehensive insights into farm productivity',
                                style: TextStyle(fontSize: 12.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Actions Row: Last 6 Months & Export Report
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.calendar_today_outlined, size: 14, color: primaryGreen),
                          label: Text("Last 6 Months", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primaryGreen),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text("Unlock PDF Export"),
                                content: const Text("Watch a short video ad to generate and download your PDF report."),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Cancel"),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      AdService.showRewardedAd(context, () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text("Exporting report as PDF..."),
                                            backgroundColor: Color(0xFF22C55E),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
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
                          },
                          icon: const Icon(Icons.download, size: 14, color: Colors.white),
                          label: const Text("Export Report", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats Grid Cards (Responsive Layout)
                    if (isWide)
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              "Total Milk Yield",
                              "${displayMilk.toStringAsFixed(0)} L",
                              "This month",
                              hasAnimals ? "+ 8.5%" : "0.0%",
                              Icons.water_drop_outlined,
                              const Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              "Eggs Collected",
                              "$displayEggs",
                              "This month",
                              hasAnimals ? "+ 12.3%" : "0.0%",
                              Icons.egg_outlined,
                              const Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              "Feed Efficiency",
                              "${_feedEfficiency.toStringAsFixed(0)}%",
                              "Feed to output ratio",
                              hasAnimals ? "+ 3.2%" : "0.0%",
                              Icons.trending_up,
                              const Color(0xFF22C55E),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildSummaryCard(
                              "Health Score",
                              "${_healthScore.toStringAsFixed(1)}%",
                              "Healthy animals",
                              hasAnimals ? "+ 1.5%" : "0.0%",
                              Icons.favorite_border,
                              const Color(0xFF22C55E),
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  "Total Milk Yield",
                                  "${displayMilk.toStringAsFixed(0)} L",
                                  "This month",
                                  hasAnimals ? "+ 8.5%" : "0.0%",
                                  Icons.water_drop_outlined,
                                  const Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  "Eggs Collected",
                                  "$displayEggs",
                                  "This month",
                                  hasAnimals ? "+ 12.3%" : "0.0%",
                                  Icons.egg_outlined,
                                  const Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSummaryCard(
                                  "Feed Efficiency",
                                  "${_feedEfficiency.toStringAsFixed(0)}%",
                                  "Feed to output ratio",
                                  hasAnimals ? "+ 3.2%" : "0.0%",
                                  Icons.trending_up,
                                  const Color(0xFF22C55E),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSummaryCard(
                                  "Health Score",
                                  "${_healthScore.toStringAsFixed(1)}%",
                                  "Healthy animals",
                                  hasAnimals ? "+ 1.5%" : "0.0%",
                                  Icons.favorite_border,
                                  const Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),

                    // Charts Layout (Responsive Grid)
                    if (isWide) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildChartContainer(
                              title: "Milk Production Trend",
                              icon: const CustomDropletIcon(size: 20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: 260,
                                    width: double.infinity,
                                    child: GestureDetector(
                                      onTapDown: (details) {
                                        final dx = details.localPosition.dx;
                                        final chartWidth = constraints.maxWidth - 56.0;
                                        if (chartWidth > 0) {
                                          final stepX = chartWidth / 5;
                                          final idx = ((dx - 36.0) / stepX).round().clamp(0, 5);
                                          setState(() {
                                            _selectedMilkIndex = (_selectedMilkIndex == idx) ? null : idx;
                                          });
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: MilkTrendPainter(
                                          extraMilk: _simulatedMilkAdd,
                                          selectedIndex: _selectedMilkIndex,
                                          hasAnimals: hasAnimals,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildChartContainer(
                              title: "Weekly Egg Production",
                              icon: const Icon(Icons.circle_outlined, color: Colors.orange, size: 20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: 260,
                                    width: double.infinity,
                                    child: GestureDetector(
                                      onTapDown: (details) {
                                        final dx = details.localPosition.dx;
                                        final chartWidth = constraints.maxWidth - 60.0;
                                        if (chartWidth > 0) {
                                          final sectionWidth = chartWidth / 4;
                                          final idx = ((dx - 40.0) / sectionWidth).floor().clamp(0, 3);
                                          setState(() {
                                            _selectedEggIndex = (_selectedEggIndex == idx) ? null : idx;
                                          });
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: EggProductionPainter(
                                          extraEggs: _simulatedEggsAdd,
                                          selectedIndex: _selectedEggIndex,
                                          hasAnimals: hasAnimals,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildChartContainer(
                              title: "Animal Distribution",
                              icon: Icon(Icons.pie_chart_outline, color: primaryGreen, size: 20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: 320,
                                    width: double.infinity,
                                    child: GestureDetector(
                                      onTapDown: (details) {
                                        final centerX = constraints.maxWidth * 0.5;
                                        final centerY = 320.0 * 0.5;
                                        final dx = details.localPosition.dx - centerX;
                                        final dy = details.localPosition.dy - centerY;
                                        double angle = math.atan2(dy, dx);
                                        double normalizedAngle = angle + math.pi / 2;
                                        if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

                                        final total = (_cattleCount + _horsesCount + _pigsCount + _chickensCount + _sheepCount + _goatsCount).toDouble();
                                        if (total > 0) {
                                          final counts = [
                                            _cattleCount,
                                            _horsesCount,
                                            _pigsCount,
                                            _chickensCount,
                                            _sheepCount,
                                            _goatsCount,
                                          ];
                                          double accumAngle = 0.0;
                                          int matchedIdx = 0;
                                          for (int i = 0; i < counts.length; i++) {
                                            final sweep = (counts[i] / total) * 2 * math.pi;
                                            if (normalizedAngle >= accumAngle && normalizedAngle < accumAngle + sweep) {
                                              matchedIdx = i;
                                              break;
                                            }
                                            accumAngle += sweep;
                                          }
                                          setState(() {
                                            _selectedDistributionIndex = (_selectedDistributionIndex == matchedIdx) ? null : matchedIdx;
                                          });
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: AnimalDistributionPainter(
                                          cattle: _cattleCount,
                                          goats: _goatsCount,
                                          sheep: _sheepCount,
                                          chickens: _chickensCount,
                                          pigs: _pigsCount,
                                          horses: _horsesCount,
                                          selectedIndex: _selectedDistributionIndex,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildChartContainer(
                              title: "Health Status Trends",
                              icon: Icon(Icons.show_chart_rounded, color: primaryGreen, size: 20),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  return SizedBox(
                                    height: 280,
                                    width: double.infinity,
                                    child: GestureDetector(
                                      onTapDown: (details) {
                                        final dx = details.localPosition.dx;
                                        final chartWidth = constraints.maxWidth - 60.0;
                                        if (chartWidth > 0) {
                                          final stepX = chartWidth / 5;
                                          final idx = ((dx - 40.0) / stepX).round().clamp(0, 5);
                                          setState(() {
                                            _selectedHealthIndex = (_selectedHealthIndex == idx) ? null : idx;
                                          });
                                        }
                                      },
                                      child: CustomPaint(
                                        painter: HealthTrendsPainter(
                                          healthy: _healthyCountJun,
                                          attention: _attentionCountJun,
                                          critical: _criticalCountJun,
                                          selectedIndex: _selectedHealthIndex,
                                          hasAnimals: hasAnimals,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildChartContainer(
                        title: "Feed Cost vs Consumption Analysis",
                        icon: Icon(Icons.bar_chart_outlined, color: primaryGreen, size: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 280,
                              width: double.infinity,
                              child: GestureDetector(
                                onTapDown: (details) {
                                  final dx = details.localPosition.dx;
                                  final chartWidth = constraints.maxWidth - 90.0;
                                  if (chartWidth > 0) {
                                    final sectionWidth = chartWidth / 6;
                                    final idx = ((dx - 45.0) / sectionWidth).floor().clamp(0, 5);
                                    setState(() {
                                      _selectedFeedIndex = (_selectedFeedIndex == idx) ? null : idx;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: FeedCostConsumptionPainter(
                                    selectedIndex: _selectedFeedIndex,
                                    hasAnimals: hasAnimals,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ] else ...[
                      // Chart 1: Milk Production Trend (Spline Area)
                      _buildChartContainer(
                        title: "Milk Production Trend",
                        icon: const CustomDropletIcon(size: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: GestureDetector(
                                onTapDown: (details) {
                                  final dx = details.localPosition.dx;
                                  final chartWidth = constraints.maxWidth - 56.0;
                                  if (chartWidth > 0) {
                                    final stepX = chartWidth / 5;
                                    final idx = ((dx - 36.0) / stepX).round().clamp(0, 5);
                                    setState(() {
                                      _selectedMilkIndex = (_selectedMilkIndex == idx) ? null : idx;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: MilkTrendPainter(
                                    extraMilk: _simulatedMilkAdd,
                                    selectedIndex: _selectedMilkIndex,
                                    hasAnimals: hasAnimals,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chart 2: Weekly Egg Production (Bar)
                      _buildChartContainer(
                        title: "Weekly Egg Production",
                        icon: const Icon(Icons.circle_outlined, color: Colors.orange, size: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: GestureDetector(
                                onTapDown: (details) {
                                  final dx = details.localPosition.dx;
                                  final chartWidth = constraints.maxWidth - 60.0;
                                  if (chartWidth > 0) {
                                    final sectionWidth = chartWidth / 4;
                                    final idx = ((dx - 40.0) / sectionWidth).floor().clamp(0, 3);
                                    setState(() {
                                      _selectedEggIndex = (_selectedEggIndex == idx) ? null : idx;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: EggProductionPainter(
                                    extraEggs: _simulatedEggsAdd,
                                    selectedIndex: _selectedEggIndex,
                                    hasAnimals: hasAnimals,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chart 3: Animal Distribution (Doughnut)
                      _buildChartContainer(
                        title: "Animal Distribution",
                        icon: Icon(Icons.pie_chart_outline, color: primaryGreen, size: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 280,
                              width: double.infinity,
                              child: GestureDetector(
                                onTapDown: (details) {
                                  final centerX = constraints.maxWidth * 0.5;
                                  final centerY = 280.0 * 0.5;
                                  final dx = details.localPosition.dx - centerX;
                                  final dy = details.localPosition.dy - centerY;
                                  double angle = math.atan2(dy, dx);
                                  double normalizedAngle = angle + math.pi / 2;
                                  if (normalizedAngle < 0) normalizedAngle += 2 * math.pi;

                                  final total = (_cattleCount + _horsesCount + _pigsCount + _chickensCount + _sheepCount + _goatsCount).toDouble();
                                  if (total > 0) {
                                    final counts = [
                                      _cattleCount,
                                      _horsesCount,
                                      _pigsCount,
                                      _chickensCount,
                                      _sheepCount,
                                      _goatsCount,
                                    ];
                                    double accumAngle = 0.0;
                                    int matchedIdx = 0;
                                    for (int i = 0; i < counts.length; i++) {
                                      final sweep = (counts[i] / total) * 2 * math.pi;
                                      if (normalizedAngle >= accumAngle && normalizedAngle < accumAngle + sweep) {
                                        matchedIdx = i;
                                        break;
                                      }
                                      accumAngle += sweep;
                                    }
                                    setState(() {
                                      _selectedDistributionIndex = (_selectedDistributionIndex == matchedIdx) ? null : matchedIdx;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: AnimalDistributionPainter(
                                    cattle: _cattleCount,
                                    goats: _goatsCount,
                                    sheep: _sheepCount,
                                    chickens: _chickensCount,
                                    pigs: _pigsCount,
                                    horses: _horsesCount,
                                    selectedIndex: _selectedDistributionIndex,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chart 4: Health Status Trends (Multi-line)
                      _buildChartContainer(
                        title: "Health Status Trends",
                        icon: Icon(Icons.show_chart_rounded, color: primaryGreen, size: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: GestureDetector(
                                onTapDown: (details) {
                                  final dx = details.localPosition.dx;
                                  final chartWidth = constraints.maxWidth - 60.0;
                                  if (chartWidth > 0) {
                                    final stepX = chartWidth / 5;
                                    final idx = ((dx - 40.0) / stepX).round().clamp(0, 5);
                                    setState(() {
                                      _selectedHealthIndex = (_selectedHealthIndex == idx) ? null : idx;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: HealthTrendsPainter(
                                    healthy: _healthyCountJun,
                                    attention: _attentionCountJun,
                                    critical: _criticalCountJun,
                                    selectedIndex: _selectedHealthIndex,
                                    hasAnimals: hasAnimals,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Chart 5: Feed Cost vs Consumption (Dual Bar)
                      _buildChartContainer(
                        title: "Feed Cost vs Consumption Analysis",
                        icon: Icon(Icons.bar_chart_outlined, color: primaryGreen, size: 20),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SizedBox(
                              height: 240,
                              width: double.infinity,
                              child: GestureDetector(
                                onTapDown: (details) {
                                  final dx = details.localPosition.dx;
                                  final chartWidth = constraints.maxWidth - 90.0;
                                  if (chartWidth > 0) {
                                    final sectionWidth = chartWidth / 6;
                                    final idx = ((dx - 45.0) / sectionWidth).floor().clamp(0, 5);
                                    setState(() {
                                      _selectedFeedIndex = (_selectedFeedIndex == idx) ? null : idx;
                                    });
                                  }
                                },
                                child: CustomPaint(
                                  painter: FeedCostConsumptionPainter(
                                    selectedIndex: _selectedFeedIndex,
                                    hasAnimals: hasAnimals,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 60),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showLogProductionSheet,
        backgroundColor: const Color(0xFF22C55E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Log Yield Data", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, String subtext, String badgeVal, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, color: Colors.grey, fontWeight: FontWeight.w500)),
              Icon(icon, color: color, size: 16),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF8F2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeVal,
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F5A3E)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtext, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChartContainer({required String title, required Widget icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              icon,
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 17.5, fontWeight: FontWeight.bold, color: Color(0xFF0F2E22)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

// Custom droplet icon and painter matching mockup styling
class CustomDropletIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dropletPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(w * 0.5, h * 0.2);
    path.cubicTo(
      w * 0.85, h * 0.5,
      w * 0.85, h * 0.85,
      w * 0.5, h * 0.85,
    );
    path.cubicTo(
      w * 0.15, h * 0.85,
      w * 0.15, h * 0.5,
      w * 0.5, h * 0.2,
    );
    canvas.drawPath(path, dropletPaint);

    final leafPaint = Paint()
      ..color = const Color(0xFF00FF66)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    final leafPath = Path();
    leafPath.arcTo(
      Rect.fromCircle(center: Offset(w * 0.38, h * 0.58), radius: w * 0.42),
      2.0,
      3.2,
      false,
    );
    canvas.drawPath(leafPath, leafPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CustomDropletIcon extends StatelessWidget {
  final double size;
  const CustomDropletIcon({Key? key, this.size = 24.0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: CustomDropletIconPainter(),
    );
  }
}

// ----------------------------------------------------
// Graphic Drawing Helpers
// ----------------------------------------------------

// Dash Line Drawer
void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, {double dashWidth = 4, double dashSpace = 4}) {
  double distance = (p2 - p1).distance;
  int count = (distance / (dashWidth + dashSpace)).floor();
  Offset direction = (p2 - p1) / distance;
  for (int i = 0; i < count; i++) {
    Offset start = p1 + direction * (i * (dashWidth + dashSpace));
    Offset end = start + direction * dashWidth;
    canvas.drawLine(start, end, paint);
  }
}

// Cubic Bézier Spline Curve Builder
void _drawSmoothSpline(Path path, List<Offset> points) {
  if (points.isEmpty) return;
  path.moveTo(points[0].dx, points[0].dy);
  if (points.length == 1) return;
  if (points.length == 2) {
    path.lineTo(points[1].dx, points[1].dy);
    return;
  }
  for (int i = 0; i < points.length - 1; i++) {
    final p0 = points[i];
    final p1 = points[i + 1];
    final controlPoint1 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
    final controlPoint2 = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
    path.cubicTo(
      controlPoint1.dx, controlPoint1.dy,
      controlPoint2.dx, controlPoint2.dy,
      p1.dx, p1.dy,
    );
  }
}

// Helper to draw a modern rounded tooltip card on canvas
void _drawTooltipCard(
  Canvas canvas,
  Size size,
  Offset position,
  String title,
  List<Map<String, dynamic>> rows,
) {
  final textPainter = TextPainter(textDirection: TextDirection.ltr);
  
  // 1. Measure text to dynamically calculate the tooltip card size
  textPainter.text = TextSpan(
    text: title,
    style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
  );
  textPainter.layout();
  double cardWidth = textPainter.width;
  double cardHeight = textPainter.height + 10; // title height + spacing + padding

  final rowPainters = <TextPainter>[];
  for (var row in rows) {
    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: "${row["label"]} : ${row["value"]}",
      style: TextStyle(fontSize: 11, color: row["color"] as Color, fontWeight: FontWeight.bold),
    );
    tp.layout();
    rowPainters.add(tp);
    cardWidth = math.max(cardWidth, tp.width);
    cardHeight += tp.height + 6;
  }

  // Padding
  double padX = 14.0;
  double padY = 12.0;
  cardWidth += padX * 2;
  cardHeight += padY; // extra breathing room at bottom

  // 2. Determine tooltip position
  // We want the tooltip to center horizontally on 'position.dx', and float above 'position.dy'
  double x = position.dx - cardWidth / 2;
  double y = position.dy - cardHeight - 12; // 12px gap above point

  // Bounds checks: keep tooltip inside the canvas area
  if (x < 6.0) x = 6.0;
  if (x + cardWidth > size.width - 6.0) x = size.width - cardWidth - 6.0;
  if (y < 6.0) {
    // If it goes above the top, show it below the point instead
    y = position.dy + 12;
  }

  final rect = Rect.fromLTWH(x, y, cardWidth, cardHeight);
  final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(10));

  // 3. Draw shadow
  final shadowPaint = Paint()
    ..color = Colors.black.withOpacity(0.08)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
  canvas.drawRRect(rrect.shift(const Offset(0, 3)), shadowPaint);

  // 4. Draw white card background & border
  final bgPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
  final borderPaint = Paint()
    ..color = const Color(0xFFE5E7EB)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  canvas.drawRRect(rrect, bgPaint);
  canvas.drawRRect(rrect, borderPaint);

  // 5. Draw text inside card
  double curY = y + padY;
  
  // Title
  textPainter.text = TextSpan(
    text: title,
    style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937), fontWeight: FontWeight.bold),
  );
  textPainter.layout();
  textPainter.paint(canvas, Offset(x + padX, curY));
  curY += textPainter.height + 6;

  // Rows
  for (var tp in rowPainters) {
    tp.paint(canvas, Offset(x + padX, curY));
    curY += tp.height + 6;
  }
}

// 1. MILK PRODUCTION TREND PAINTER
class MilkTrendPainter extends CustomPainter {
  final double extraMilk;
  final int? selectedIndex;
  final bool hasAnimals;
  MilkTrendPainter({required this.extraMilk, this.selectedIndex, required this.hasAnimals});

  @override
  void paint(Canvas canvas, Size size) {
    final axisLinePaint = Paint()..color = const Color(0xFF888888)..strokeWidth = 1.2;
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 0.8;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double paddingLeft = 36.0;
    double paddingRight = 20.0; // Right padding to prevent label clipping
    double paddingBottom = 48.0; // Bottom padding for labels and legend
    double chartWidth = size.width - paddingLeft - paddingRight;
    double chartHeight = size.height - paddingBottom;

    // Draw solid axis lines (Y on left, X on bottom)
    canvas.drawLine(Offset(paddingLeft, 0), Offset(paddingLeft, chartHeight), axisLinePaint);
    canvas.drawLine(Offset(paddingLeft, chartHeight), Offset(size.width - paddingRight, chartHeight), axisLinePaint);

    // Draw Y grid lines (dashed) and labels (0, 150, 300, 450, 600)
    final yValues = [0, 150, 300, 450, 600];
    for (var val in yValues) {
      double y = chartHeight - (val / 600.0) * chartHeight;
      if (val > 0) {
        _drawDashedLine(canvas, Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
      }
      
      // Tick line extending leftward from axis
      canvas.drawLine(Offset(paddingLeft - 4, y), Offset(paddingLeft, y), axisLinePaint);

      textPainter.text = TextSpan(
        text: "$val", 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    // Draw X months (Jan, Feb, Mar, Apr, May, Jun) and grid lines
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
    double stepX = chartWidth / (months.length - 1);
    for (int i = 0; i < months.length; i++) {
      double x = paddingLeft + i * stepX;
      if (i > 0) {
        _drawDashedLine(canvas, Offset(x, 0), Offset(x, chartHeight), gridPaint);
      }

      textPainter.text = TextSpan(
        text: months[i], 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 6));
    }

    // Plot Points for Green Line (Actual Yield)
    final actualPoints = hasAnimals ? [420.0, 450.0, 480.0, 510.0, 495.0, 520.0 + extraMilk] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final actualOffsets = List.generate(actualPoints.length, (i) {
      return Offset(paddingLeft + i * stepX, chartHeight - (actualPoints[i] / 600.0) * chartHeight);
    });

    // Draw filled spline area
    final fillPath = Path();
    _drawSmoothSpline(fillPath, actualOffsets);
    fillPath.lineTo(actualOffsets.last.dx, chartHeight);
    fillPath.lineTo(actualOffsets.first.dx, chartHeight);
    fillPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFE6F9F0) // Soft light green background fill
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw actual line
    final linePaint = Paint()
      ..color = const Color(0xFF00E65A) // Vibrant green
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final actualPath = Path();
    _drawSmoothSpline(actualPath, actualOffsets);
    canvas.drawPath(actualPath, linePaint);

    // Plot Points for Grey Target Line
    final targetPoints = hasAnimals ? [395.0, 420.0, 445.0, 480.0, 500.0, 515.0] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final targetOffsets = List.generate(targetPoints.length, (i) {
      return Offset(paddingLeft + i * stepX, chartHeight - (targetPoints[i] / 600.0) * chartHeight);
    });

    final targetPaint = Paint()
      ..color = const Color(0xFF4B5563) // Greyish target line color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final targetPath = Path();
    _drawSmoothSpline(targetPath, targetOffsets);

    // Draw dashed spline target path
    final dashPath = Path();
    double dashWidth = 5.0;
    double dashSpace = 4.0;
    for (final metric in targetPath.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        dashPath.addPath(metric.extractPath(distance, distance + dashWidth), Offset.zero);
        distance += dashWidth + dashSpace;
      }
    }
    canvas.drawPath(dashPath, targetPaint);

    // Draw vertical highlight line and popup if selected
    if (selectedIndex != null) {
      double selectedX = paddingLeft + selectedIndex! * stepX;
      
      final selectLinePaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 1.0;
      _drawDashedLine(canvas, Offset(selectedX, 0), Offset(selectedX, chartHeight), selectLinePaint);

      double actY = chartHeight - (actualPoints[selectedIndex!] / 600.0) * chartHeight;
      double trgY = chartHeight - (targetPoints[selectedIndex!] / 600.0) * chartHeight;

      // Draw highlighted node circles
      canvas.drawCircle(Offset(selectedX, actY), 5.5, Paint()..color = const Color(0xFF00E65A)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(selectedX, actY), 5.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);
      
      canvas.drawCircle(Offset(selectedX, trgY), 5.5, Paint()..color = const Color(0xFF4B5563)..style = PaintingStyle.fill);
      canvas.drawCircle(Offset(selectedX, trgY), 5.5, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 1.5);

      final rowData = [
        {"label": "Actual Yield", "value": "${actualPoints[selectedIndex!].toStringAsFixed(0)} L", "color": const Color(0xFF00E65A)},
        {"label": "Target", "value": "${targetPoints[selectedIndex!].toStringAsFixed(0)} L", "color": const Color(0xFF4B5563)},
      ];
      _drawTooltipCard(canvas, size, Offset(selectedX, actY), months[selectedIndex!], rowData);
    }

    // Render Bottom Legend (exactly matching mockup styling dynamically)
    double legendY = size.height - 12;
    
    // Measure item 1 dynamically
    textPainter.text = const TextSpan(
      text: "Actual Yield (L)",
      style: TextStyle(fontSize: 10.5, color: Color(0xFF00E65A), fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    double item1TextWidth = textPainter.width;
    double item1TotalWidth = 22 + item1TextWidth; // 16px line + 6px space + text
    
    // Measure item 2 dynamically
    textPainter.text = const TextSpan(
      text: "Target (L)",
      style: TextStyle(fontSize: 10.5, color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    double item2TextWidth = textPainter.width;
    double item2TotalWidth = 22 + item2TextWidth;

    double spacing = size.width > 500 ? 40.0 : 16.0;
    double totalWidth = item1TotalWidth + item2TotalWidth + spacing;
    double startX = (size.width - totalWidth) / 2;

    // Legend 1: Actual Yield (L) (Green line & hollow dot)
    double x1 = startX;
    final legPaint1 = Paint()
      ..color = const Color(0xFF00E65A)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(x1, legendY), Offset(x1 + 16, legendY), legPaint1);
    canvas.drawCircle(Offset(x1 + 8, legendY), 3.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x1 + 8, legendY), 3.0, Paint()..color = const Color(0xFF00E65A)..style = PaintingStyle.stroke..strokeWidth = 1.2);

    textPainter.text = const TextSpan(
      text: "Actual Yield (L)",
      style: TextStyle(fontSize: 10.5, color: Color(0xFF00E65A), fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x1 + 22, legendY - textPainter.height / 2));

    // Legend 2: Target (L) (Dashed grey line & hollow dot)
    double x2 = startX + item1TotalWidth + spacing;
    final legPaint2 = Paint()
      ..color = const Color(0xFF4B5563)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    _drawDashedLine(canvas, Offset(x2, legendY), Offset(x2 + 16, legendY), legPaint2);
    canvas.drawCircle(Offset(x2 + 8, legendY), 2.5, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x2 + 8, legendY), 2.5, Paint()..color = const Color(0xFF4B5563)..style = PaintingStyle.stroke..strokeWidth = 1.0);

    textPainter.text = const TextSpan(
      text: "Target (L)",
      style: TextStyle(fontSize: 10.5, color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x2 + 22, legendY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant MilkTrendPainter oldDelegate) =>
      oldDelegate.extraMilk != extraMilk || 
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.hasAnimals != hasAnimals;
}

// 2. WEEKLY EGG PRODUCTION PAINTER
class EggProductionPainter extends CustomPainter {
  final int extraEggs;
  final int? selectedIndex;
  final bool hasAnimals;
  EggProductionPainter({required this.extraEggs, this.selectedIndex, required this.hasAnimals});

  @override
  void paint(Canvas canvas, Size size) {
    final axisLinePaint = Paint()..color = const Color(0xFF888888)..strokeWidth = 1.2;
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 0.8;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double paddingLeft = 40.0;
    double paddingRight = 20.0; // Right padding to prevent label clipping
    double paddingBottom = 24.0;
    double chartWidth = size.width - paddingLeft - paddingRight;
    double chartHeight = size.height - paddingBottom;

    // Draw axis lines (Y on left, X on bottom)
    canvas.drawLine(Offset(paddingLeft, 0), Offset(paddingLeft, chartHeight), axisLinePaint);
    canvas.drawLine(Offset(paddingLeft, chartHeight), Offset(size.width - paddingRight, chartHeight), axisLinePaint);

    // Draw Y grid lines (dashed) and labels (0, 60, 120, 180, 240)
    final yValues = [0, 60, 120, 180, 240];
    for (var val in yValues) {
      double y = chartHeight - (val / 240.0) * chartHeight;
      if (val > 0) {
        _drawDashedLine(canvas, Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
      }
      
      canvas.drawLine(Offset(paddingLeft - 4, y), Offset(paddingLeft, y), axisLinePaint);

      textPainter.text = TextSpan(
        text: "$val", 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    final weeks = ["Week 1", "Week 2", "Week 3", "Week 4"];
    double sectionWidth = chartWidth / weeks.length;
    double barWidth = sectionWidth * 0.6; // Responsive width based on viewport
    double barSpace = sectionWidth * 0.2; // Proportional spacing

    final eggValues = hasAnimals ? [180.0, 195.0, 210.0 + extraEggs, 238.0] : [0.0, 0.0, 0.0, 0.0];

    // Draw highlight background overlay if selected
    if (selectedIndex != null) {
      final highlightPaint = Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      double highlightX = paddingLeft + selectedIndex! * sectionWidth;
      canvas.drawRect(
        Rect.fromLTWH(highlightX, 0, sectionWidth, chartHeight),
        highlightPaint,
      );
    }

    for (int i = 0; i < weeks.length; i++) {
      double x = paddingLeft + i * sectionWidth + barSpace;
      double y = chartHeight - (eggValues[i] / 240.0) * chartHeight;

      // Draw Grid Column Line (dashed)
      _drawDashedLine(canvas, Offset(x + barWidth / 2, 0), Offset(x + barWidth / 2, chartHeight), gridPaint);

      // Draw Column Bar (solid amber-orange with sharp corners)
      final barPaint = Paint()
        ..color = const Color(0xFFE2953B) // Solid amber-orange matching mockup
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTRB(x, y, x + barWidth, chartHeight), barPaint);

      // X Label
      textPainter.text = TextSpan(
        text: weeks[i], 
        style: const TextStyle(fontSize: 10.5, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x + barWidth / 2 - textPainter.width / 2, chartHeight + 6));
    }

    // Draw Tooltip Card if selected
    if (selectedIndex != null) {
      double selectedX = paddingLeft + selectedIndex! * sectionWidth + sectionWidth / 2;
      double selectedY = chartHeight - (eggValues[selectedIndex!] / 240.0) * chartHeight;
      final rowData = [
        {"label": "Eggs Collected", "value": "${eggValues[selectedIndex!].toInt()} pcs", "color": const Color(0xFFE2953B)},
      ];
      _drawTooltipCard(canvas, size, Offset(selectedX, selectedY), weeks[selectedIndex!], rowData);
    }
  }

  @override
  bool shouldRepaint(covariant EggProductionPainter oldDelegate) =>
      oldDelegate.extraEggs != extraEggs || 
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.hasAnimals != hasAnimals;
}

// 3. ANIMAL DISTRIBUTION PAINTER
class AnimalDistributionPainter extends CustomPainter {
  final int cattle, goats, sheep, chickens, pigs, horses;
  final int? selectedIndex;
  
  AnimalDistributionPainter({
    required this.cattle,
    required this.goats,
    required this.sheep,
    required this.chickens,
    required this.pigs,
    required this.horses,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double total = (cattle + goats + sheep + chickens + pigs + horses).toDouble();
    double centerX = size.width * 0.5;
    double centerY = size.height * 0.5;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (total == 0) {
      textPainter.text = const TextSpan(
        text: "No animals registered yet",
        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), fontWeight: FontWeight.w500),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(centerX - textPainter.width / 2, centerY - textPainter.height / 2));
      return;
    }

    // Ordered list matching the clockwise layout of the mockup image 3 exactly:
    // Cattle (top right), Horses (middle right), Pigs (bottom right), Chickens (bottom), Sheep (bottom left), Goats (top left)
    final categories = [
      {"name": "Cattle", "count": cattle, "color": const Color(0xFF00FF00)}, // Bright lime green
      {"name": "Horses", "count": horses, "color": const Color(0xFFEF4444)}, // Red
      {"name": "Pigs", "count": pigs, "color": const Color(0xFF6B7280)}, // Grey
      {"name": "Chickens", "count": chickens, "color": const Color(0xFFEF9A0A)}, // Yellow-orange
      {"name": "Sheep", "count": sheep, "color": const Color(0xFF22A35E)}, // Darker green
      {"name": "Goats", "count": goats, "color": const Color(0xFFE2953B)}, // Orange
    ];

    
    // Dynamic radius calculation to leave plenty of safe spacing on mobile edges
    double radius = size.width > 500
        ? math.min(size.width * 0.20, size.height * 0.26)
        : math.min(size.width * 0.16, size.height * 0.22);

    double pointerLength = size.width > 500 ? 20.0 : 12.0;
    double horizontalLength = size.width > 500 ? 16.0 : 8.0;

    double startAngle = -math.pi / 2;
    const double gapAngle = 0.05; // Gap between segments


    Offset? tooltipPos;
    String? tooltipTitle;
    List<Map<String, dynamic>>? tooltipRows;

    for (int i = 0; i < categories.length; i++) {
      final cat = categories[i];
      final count = cat["count"] as int;
      if (count <= 0) continue;

      final double sweepAngle = count / total * 2 * math.pi;
      final isSelected = selectedIndex == i;

      double angle = startAngle + sweepAngle / 2;
      double cosA = math.cos(angle);
      double sinA = math.sin(angle);
      
      double explodeDx = 0.0;
      double explodeDy = 0.0;
      if (isSelected) {
        double explodeDist = 6.0;
        explodeDx = explodeDist * cosA;
        explodeDy = explodeDist * sinA;
      }

      // Draw Arc
      final paint = Paint()
        ..color = cat["color"] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 24;

      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX + explodeDx, centerY + explodeDy), radius: radius),
        startAngle + (gapAngle / 2),
        sweepAngle - gapAngle,
        false,
        paint,
      );

      // Draw Pointer Lines and Labels
      // Starting point on the arc outer boundary (radius + 12 stroke half width)
      Offset lineStart = Offset(centerX + explodeDx + (radius + 12) * cosA, centerY + explodeDy + (radius + 12) * sinA);
      // End point for the diagonal part of the line
      Offset lineMid = Offset(centerX + explodeDx + (radius + 12 + pointerLength) * cosA, centerY + explodeDy + (radius + 12 + pointerLength) * sinA);
      // End point for the horizontal part of the line
      double lineEndDx = lineMid.dx + (cosA >= 0 ? horizontalLength : -horizontalLength);
      Offset lineEnd = Offset(lineEndDx, lineMid.dy);

      // Draw the pointer line
      final linePaint = Paint()
        ..color = cat["color"] as Color
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(lineStart, lineMid, linePaint);
      canvas.drawLine(lineMid, lineEnd, linePaint);

      // Paint the label text
      textPainter.text = TextSpan(
        text: "${cat["name"]}: $count",
        style: TextStyle(
          fontSize: 10.5, 
          color: cat["color"] as Color, 
          fontWeight: FontWeight.bold
        ),
      );
      textPainter.layout();
      double textX = cosA >= 0 ? lineEnd.dx + 4 : lineEnd.dx - textPainter.width - 4;
      double textY = lineEnd.dy - textPainter.height / 2;
      textPainter.paint(canvas, Offset(textX, textY));

      if (isSelected) {
        tooltipPos = Offset(centerX + explodeDx + (radius + 12) * cosA, centerY + explodeDy + (radius + 12) * sinA);
        tooltipTitle = cat["name"] as String;
        double pct = (count / total) * 100;
        tooltipRows = [
          {"label": "Count", "value": "$count", "color": cat["color"] as Color},
          {"label": "Share", "value": "${pct.toStringAsFixed(1)}%", "color": cat["color"] as Color},
        ];
      }

      startAngle += sweepAngle;
    }

    if (tooltipPos != null && tooltipTitle != null && tooltipRows != null) {
      _drawTooltipCard(canvas, size, tooltipPos, tooltipTitle, tooltipRows);
    }
  }

  @override
  bool shouldRepaint(covariant AnimalDistributionPainter oldDelegate) {
    return oldDelegate.cattle != cattle ||
        oldDelegate.goats != goats ||
        oldDelegate.sheep != sheep ||
        oldDelegate.chickens != chickens ||
        oldDelegate.pigs != pigs ||
        oldDelegate.horses != horses ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}

// 4. HEALTH STATUS TRENDS PAINTER
class HealthTrendsPainter extends CustomPainter {
  final int healthy;
  final int attention;
  final int critical;
  final int? selectedIndex;
  final bool hasAnimals;

  HealthTrendsPainter({
    required this.healthy,
    required this.attention,
    required this.critical,
    this.selectedIndex,
    required this.hasAnimals,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final axisLinePaint = Paint()..color = const Color(0xFF888888)..strokeWidth = 1.2;
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 0.8;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    double paddingLeft = 40.0;
    double paddingRight = 20.0; // Right padding to prevent label clipping
    double paddingBottom = 48.0; // Room for legend
    double chartWidth = size.width - paddingLeft - paddingRight;
    double chartHeight = size.height - paddingBottom;

    // Draw axis lines (Y on left, X on bottom)
    canvas.drawLine(Offset(paddingLeft, 0), Offset(paddingLeft, chartHeight), axisLinePaint);
    canvas.drawLine(Offset(paddingLeft, chartHeight), Offset(size.width - paddingRight, chartHeight), axisLinePaint);

    // Draw Y grid lines (0, 40, 80, 120, 160)
    final yValues = [0, 40, 80, 120, 160];
    for (var val in yValues) {
      double y = chartHeight - (val / 160.0) * chartHeight;
      if (val > 0) {
        _drawDashedLine(canvas, Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
      }
      
      canvas.drawLine(Offset(paddingLeft - 4, y), Offset(paddingLeft, y), axisLinePaint);

      textPainter.text = TextSpan(
        text: "$val", 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    // X Months
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
    double stepX = chartWidth / (months.length - 1);
    for (int i = 0; i < months.length; i++) {
      double x = paddingLeft + i * stepX;
      if (i > 0) {
        _drawDashedLine(canvas, Offset(x, 0), Offset(x, chartHeight), gridPaint);
      }

      textPainter.text = TextSpan(
        text: months[i], 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, chartHeight + 6));
    }

    // Line Data definitions
    final criticalData = hasAnimals ? [3.0, 2.0, 1.0, 0.0, 2.0, critical.toDouble()] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final healthyData = hasAnimals ? [148.0, 151.0, 153.0, 155.0, 152.0, healthy.toDouble()] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final attentionData = hasAnimals ? [8.0, 6.0, 5.0, 4.0, 6.0, attention.toDouble()] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    // Draw vertical highlight dashed line
    if (selectedIndex != null) {
      double selectedX = paddingLeft + selectedIndex! * stepX;
      final selectLinePaint = Paint()
        ..color = Colors.grey.withOpacity(0.5)
        ..strokeWidth = 1.0;
      _drawDashedLine(canvas, Offset(selectedX, 0), Offset(selectedX, chartHeight), selectLinePaint);
    }

    _drawSmoothHollowLine(canvas, criticalData, stepX, paddingLeft, chartHeight, const Color(0xFFEF4444), selectedIndex);
    _drawSmoothHollowLine(canvas, healthyData, stepX, paddingLeft, chartHeight, const Color(0xFF22C55E), selectedIndex);
    _drawSmoothHollowLine(canvas, attentionData, stepX, paddingLeft, chartHeight, const Color(0xFFE2953B), selectedIndex);

    // Draw Tooltip Card if selected
    if (selectedIndex != null) {
      double selectedX = paddingLeft + selectedIndex! * stepX;
      // Position tooltip above the healthy data point (the highest line)
      double selectedY = chartHeight - (healthyData[selectedIndex!] / 160.0) * chartHeight;
      final rowData = [
        {"label": "Healthy", "value": "${healthyData[selectedIndex!].toInt()}", "color": const Color(0xFF22C55E)},
        {"label": "Needs Attention", "value": "${attentionData[selectedIndex!].toInt()}", "color": const Color(0xFFE2953B)},
        {"label": "Critical", "value": "${criticalData[selectedIndex!].toInt()}", "color": const Color(0xFFEF4444)},
      ];
      _drawTooltipCard(canvas, size, Offset(selectedX, selectedY), months[selectedIndex!], rowData);
    }

    // Render Bottom Legend (exactly matching layout guidelines dynamically)
    double legendY = size.height - 12;

    // Measure Item 1 dynamically
    textPainter.text = const TextSpan(text: "Critical", style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold));
    textPainter.layout();
    double w1 = 22 + textPainter.width;

    // Measure Item 2 dynamically
    textPainter.text = const TextSpan(text: "Healthy", style: TextStyle(fontSize: 10.5, color: Color(0xFF22C55E), fontWeight: FontWeight.bold));
    textPainter.layout();
    double w2 = 22 + textPainter.width;

    // Measure Item 3 dynamically
    textPainter.text = const TextSpan(text: "Needs Attention", style: TextStyle(fontSize: 10.5, color: Color(0xFFE2953B), fontWeight: FontWeight.bold));
    textPainter.layout();
    double w3 = 22 + textPainter.width;

    double spacing = size.width > 500 ? 24.0 : 10.0;
    double totalWidth = w1 + w2 + w3 + (spacing * 2);
    double startX = (size.width - totalWidth) / 2;

    double x1 = startX;
    double x2 = startX + w1 + spacing;
    double x3 = x2 + w2 + spacing;

    // Item 1: Critical (Red line & hollow dot)
    canvas.drawLine(Offset(x1, legendY), Offset(x1 + 16, legendY), Paint()..color = const Color(0xFFEF4444)..strokeWidth = 2);
    canvas.drawCircle(Offset(x1 + 8, legendY), 3.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x1 + 8, legendY), 3.0, Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    textPainter.text = const TextSpan(text: "Critical", style: TextStyle(fontSize: 10.5, color: Color(0xFFEF4444), fontWeight: FontWeight.bold));
    textPainter.layout();
    textPainter.paint(canvas, Offset(x1 + 22, legendY - textPainter.height / 2));

    // Item 2: Healthy (Green line & hollow dot)
    canvas.drawLine(Offset(x2, legendY), Offset(x2 + 16, legendY), Paint()..color = const Color(0xFF22C55E)..strokeWidth = 2);
    canvas.drawCircle(Offset(x2 + 8, legendY), 3.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x2 + 8, legendY), 3.0, Paint()..color = const Color(0xFF22C55E)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    textPainter.text = const TextSpan(text: "Healthy", style: TextStyle(fontSize: 10.5, color: Color(0xFF22C55E), fontWeight: FontWeight.bold));
    textPainter.layout();
    textPainter.paint(canvas, Offset(x2 + 22, legendY - textPainter.height / 2));

    // Item 3: Needs Attention (Orange line & hollow dot)
    canvas.drawLine(Offset(x3, legendY), Offset(x3 + 16, legendY), Paint()..color = const Color(0xFFE2953B)..strokeWidth = 2);
    canvas.drawCircle(Offset(x3 + 8, legendY), 3.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(x3 + 8, legendY), 3.0, Paint()..color = const Color(0xFFE2953B)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    textPainter.text = const TextSpan(text: "Needs Attention", style: TextStyle(fontSize: 10.5, color: Color(0xFFE2953B), fontWeight: FontWeight.bold));
    textPainter.layout();
    textPainter.paint(canvas, Offset(x3 + 22, legendY - textPainter.height / 2));
  }

  void _drawSmoothHollowLine(Canvas canvas, List<double> data, double stepX, double padLeft, double chartHeight, Color color, int? selectedIndex) {
    final points = List.generate(data.length, (i) {
      return Offset(padLeft + i * stepX, chartHeight - (data[i] / 160.0) * chartHeight);
    });

    final path = Path();
    _drawSmoothSpline(path, points);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    // Draw hollow circle nodes at data points
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isSelected = selectedIndex == i;
      double radius = isSelected ? 5.5 : 3.5;
      double strokeWidth = isSelected ? 2.0 : 1.2;
      canvas.drawCircle(pt, radius, Paint()..color = Colors.white..style = PaintingStyle.fill);
      canvas.drawCircle(pt, radius, Paint()..color = color..strokeWidth = strokeWidth..style = PaintingStyle.stroke);
    }
  }

  @override
  bool shouldRepaint(covariant HealthTrendsPainter oldDelegate) {
    return oldDelegate.healthy != healthy ||
        oldDelegate.attention != attention ||
        oldDelegate.critical != critical ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.hasAnimals != hasAnimals;
  }
}

// 5. FEED COST & CONSUMPTION PAINTER (Dual Bar)
class FeedCostConsumptionPainter extends CustomPainter {
  final int? selectedIndex;
  final bool hasAnimals;
  FeedCostConsumptionPainter({this.selectedIndex, required this.hasAnimals});

  @override
  void paint(Canvas canvas, Size size) {
    double paddingLeft = 45.0;
    double paddingRight = 45.0;
    double paddingBottom = 48.0; // Room for bottom X labels & legend
    double chartWidth = size.width - (paddingLeft + paddingRight);
    double chartHeight = size.height - paddingBottom;

    final axisLinePaint = Paint()..color = const Color(0xFF888888)..strokeWidth = 1.2;
    final gridPaint = Paint()..color = const Color(0xFFE5E7EB)..strokeWidth = 0.8;
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Draw axis lines
    canvas.drawLine(Offset(paddingLeft, 0), Offset(paddingLeft, chartHeight), axisLinePaint);
    canvas.drawLine(Offset(size.width - paddingRight, 0), Offset(size.width - paddingRight, chartHeight), axisLinePaint);
    canvas.drawLine(Offset(paddingLeft, chartHeight), Offset(size.width - paddingRight, chartHeight), axisLinePaint);

    // Left Y Axis: Cost (0, 15000, 30000, 45000, 60000)
    final yLeftValues = [0, 15000, 30000, 45000, 60000];
    for (var val in yLeftValues) {
      double y = chartHeight - (val / 60000.0) * chartHeight;
      if (val > 0) {
        _drawDashedLine(canvas, Offset(paddingLeft, y), Offset(size.width - paddingRight, y), gridPaint);
      }
      
      canvas.drawLine(Offset(paddingLeft - 4, y), Offset(paddingLeft, y), axisLinePaint);

      textPainter.text = TextSpan(
        text: "$val", 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(paddingLeft - textPainter.width - 6, y - textPainter.height / 2));
    }

    // Right Y Axis: Feed (0, 400, 800, 1200, 1600)
    final yRightValues = [0, 400, 800, 1200, 1600];
    for (var val in yRightValues) {
      double y = chartHeight - (val / 1600.0) * chartHeight;
      canvas.drawLine(Offset(size.width - paddingRight, y), Offset(size.width - paddingRight + 4, y), axisLinePaint);

      textPainter.text = TextSpan(
        text: "$val", 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(size.width - paddingRight + 8, y - textPainter.height / 2));
    }

    // Months (Jan, Feb, Mar, Apr, May, Jun)
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun"];
    double sectionWidth = chartWidth / months.length;
    double barWidth = sectionWidth * 0.35; // Proportional width
    double barSpace = 2.0; // Small space between side-by-side bars

    final costData = hasAnimals ? [45000.0, 48000.0, 52000.0, 49000.0, 50000.0, 53000.0] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    final feedData = hasAnimals ? [1200.0, 1250.0, 1380.0, 1310.0, 1360.0, 1420.0] : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

    // Draw highlight background overlay if selected
    if (selectedIndex != null) {
      final highlightPaint = Paint()
        ..color = Colors.black.withOpacity(0.05)
        ..style = PaintingStyle.fill;
      double highlightX = paddingLeft + selectedIndex! * sectionWidth;
      canvas.drawRect(
        Rect.fromLTWH(highlightX, 0, sectionWidth, chartHeight),
        highlightPaint,
      );
    }

    for (int i = 0; i < months.length; i++) {
      double sectionStart = paddingLeft + i * sectionWidth;
      
      // Draw Grid column division line (dashed)
      if (i > 0) {
        _drawDashedLine(canvas, Offset(sectionStart, 0), Offset(sectionStart, chartHeight), gridPaint);
      }

      // Cost Bar (Vibrant solid green, Left Y-axis 60k limit) - sharp corners
      double costY = chartHeight - (costData[i] / 60000.0) * chartHeight;
      double margin = (sectionWidth - (2 * barWidth + barSpace)) / 2;
      double costX = sectionStart + margin;
      canvas.drawRect(
        Rect.fromLTRB(costX, costY, costX + barWidth, chartHeight),
        Paint()..color = const Color(0xFF00FF00)..style = PaintingStyle.fill,
      );

      // Feed Bar (Orange, Right Y-axis 1.6k limit) - sharp corners
      double feedY = chartHeight - (feedData[i] / 1600.0) * chartHeight;
      double feedX = costX + barWidth + barSpace;
      canvas.drawRect(
        Rect.fromLTRB(feedX, feedY, feedX + barWidth, chartHeight),
        Paint()..color = const Color(0xFFE2953B)..style = PaintingStyle.fill,
      );

      // Label X-Axis
      textPainter.text = TextSpan(
        text: months[i], 
        style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280), fontWeight: FontWeight.bold)
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(sectionStart + sectionWidth / 2 - textPainter.width / 2, chartHeight + 6));
    }

    // Draw Tooltip Card if selected
    if (selectedIndex != null) {
      double selectedX = paddingLeft + selectedIndex! * sectionWidth + sectionWidth / 2;
      double costY = chartHeight - (costData[selectedIndex!] / 60000.0) * chartHeight;
      double feedY = chartHeight - (feedData[selectedIndex!] / 1600.0) * chartHeight;
      double selectedY = math.min(costY, feedY);
      final rowData = [
        {"label": "Cost", "value": "₹${costData[selectedIndex!].toInt()}", "color": const Color(0xFF00FF00)},
        {"label": "Feed", "value": "${feedData[selectedIndex!].toInt()} kg", "color": const Color(0xFFE2953B)},
      ];
      _drawTooltipCard(canvas, size, Offset(selectedX, selectedY), months[selectedIndex!], rowData);
    }

    // Render Bottom Legend (exactly matching mockup styling dynamically)
    double legendY = size.height - 12;

    // Measure Item 1 dynamically
    textPainter.text = const TextSpan(text: "Cost (₹)", style: TextStyle(fontSize: 11, color: Color(0xFF00FF00), fontWeight: FontWeight.bold));
    textPainter.layout();
    double w1 = 16 + textPainter.width;

    // Measure Item 2 dynamically
    textPainter.text = const TextSpan(text: "Feed (kg)", style: TextStyle(fontSize: 11, color: Color(0xFFE2953B), fontWeight: FontWeight.bold));
    textPainter.layout();
    double w2 = 16 + textPainter.width;

    double spacing = size.width > 500 ? 32.0 : 12.0;
    double totalWidth = w1 + w2 + spacing;
    double startX = (size.width - totalWidth) / 2;

    // Item 1: Cost (₹)
    double x1 = startX;
    canvas.drawRect(Rect.fromLTWH(x1, legendY - 5, 10, 10), Paint()..color = const Color(0xFF00FF00)..style = PaintingStyle.fill);
    textPainter.text = const TextSpan(
      text: "Cost (₹)", 
      style: TextStyle(fontSize: 11, color: Color(0xFF00FF00), fontWeight: FontWeight.bold)
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x1 + 16, legendY - textPainter.height / 2));

    // Item 2: Feed (kg)
    double x2 = startX + w1 + spacing;
    canvas.drawRect(Rect.fromLTWH(x2, legendY - 5, 10, 10), Paint()..color = const Color(0xFFE2953B)..style = PaintingStyle.fill);
    textPainter.text = const TextSpan(
      text: "Feed (kg)", 
      style: TextStyle(fontSize: 11, color: Color(0xFFE2953B), fontWeight: FontWeight.bold)
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(x2 + 16, legendY - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant FeedCostConsumptionPainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.hasAnimals != hasAnimals;
}
