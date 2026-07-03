import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/livestock_storage.dart';

class AnimalTrackingScreen extends StatefulWidget {
  final bool hideBackButton;
  const AnimalTrackingScreen({
    Key? key,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<AnimalTrackingScreen> createState() => _AnimalTrackingScreenState();
}

class _AnimalTrackingScreenState extends State<AnimalTrackingScreen> {
  List<Map<String, dynamic>> _animals = [];
  List<Map<String, dynamic>> _trackedAnimals = [];
  bool _isLoading = true;
  Timer? _simulationTimer;
  double _zoomScale = 1.0;
  
  // Coordinates mapping (simulated X, Y offsets between 0.1 and 0.9)
  final Map<String, Offset> _positions = {};
  final math.Random _random = math.Random();

  // Selected animal ID to highlight on map
  String? _highlightedAnimalId;

  // Stats
  int _trackedCount = 107;
  int _activeGpsCount = 103;
  int _alertCount = 2;
  int _outsideCount = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startMovementSimulation();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final animals = await LivestockStorageService.getAnimals();
    
    final tracked = animals.where((a) => a["gpsId"] != null && a["gpsId"].toString().isNotEmpty).toList();
    
    // Seed positions if they don't exist yet
    for (var animal in tracked) {
      final id = animal["id"].toString();
      if (!_positions.containsKey(id)) {
        // Mock default coordinates based on their seeded locations
        if (animal["name"] == "Bella") {
          _positions[id] = const Offset(0.25, 0.6);
        } else if (animal["name"] == "Woolly") {
          _positions[id] = const Offset(0.6, 0.3);
        } else if (animal["name"] == "Max") {
          _positions[id] = const Offset(0.45, 0.7);
        } else if (animal["name"] == "Ginger") {
          _positions[id] = const Offset(0.8, 0.7);
        } else {
          // random placement
          _positions[id] = Offset(_random.nextDouble() * 0.7 + 0.1, _random.nextDouble() * 0.7 + 0.1);
        }
      }
    }

    final outsideCount = tracked.where((a) => a["isOutsideBoundary"] == true).length;

    setState(() {
      _animals = animals;
      _trackedAnimals = tracked;
      _isLoading = false;

      _trackedCount = tracked.length;
      _activeGpsCount = tracked.length; // assuming all entered ones are online
      _outsideCount = outsideCount;
      _alertCount = outsideCount;
    });
  }

  // Periodic timer to simulate grazing drift
  void _startMovementSimulation() {
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (mounted && _trackedAnimals.isNotEmpty) {
        setState(() {
          for (var animal in _trackedAnimals) {
            final id = animal["id"].toString();
            final current = _positions[id] ?? const Offset(0.5, 0.5);
            
            // Generate tiny drift
            double dx = current.dx + (_random.nextDouble() * 0.04 - 0.02);
            double dy = current.dy + (_random.nextDouble() * 0.04 - 0.02);
            
            // Constrain within map boundaries (10% to 90%)
            dx = dx.clamp(0.1, 0.9);
            dy = dy.clamp(0.1, 0.9);
            
            _positions[id] = Offset(dx, dy);
          }
        });
      }
    });
  }

  void _showAddGpsDialog() {
    // Filter animals that don't have a GPS tag yet
    final untracked = _animals.where((a) => a["gpsId"] == null || a["gpsId"].toString().isEmpty).toList();

    if (untracked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All animals already have active GPS tags connected!")),
      );
      return;
    }

    Map<String, dynamic> selectedAnimal = untracked.first;
    final gpsController = TextEditingController();
    String selectedZone = "North Pasture";
    bool forceOutside = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Text("Register GPS Tag"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Select Animal *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAnimal["id"],
                          isExpanded: true,
                          items: untracked
                              .map((a) => DropdownMenuItem<String>(
                                    value: a["id"].toString(),
                                    child: Text("${a["name"]} (${a["type"]} - ${a["breed"]})"),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedAnimal = untracked.firstWhere((a) => a["id"] == value);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("GPS Tag Serial ID *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: gpsController,
                      decoration: InputDecoration(
                        hintText: "e.g., GPS-9981",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text("Geo-fence Assigned pasture *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedZone,
                          isExpanded: true,
                          items: ["North Pasture", "East Field", "Stable Area", "Hill Pasture"]
                              .map((zone) => DropdownMenuItem<String>(value: zone, child: Text(zone)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                selectedZone = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Simulate Outside Boundary", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Switch(
                          value: forceOutside,
                          activeColor: const Color(0xFF22C55E),
                          onChanged: (val) {
                            setDialogState(() {
                              forceOutside = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final tag = gpsController.text.trim();
                    if (tag.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("GPS Tag Serial is required!")),
                      );
                      return;
                    }

                    Navigator.pop(context); // close dialog

                    final updatedAnimal = Map<String, dynamic>.from(selectedAnimal);
                    updatedAnimal["gpsId"] = tag;
                    updatedAnimal["location"] = selectedZone; // assign location to matched zone
                    updatedAnimal["isOutsideBoundary"] = forceOutside;
                    if (forceOutside) {
                      updatedAnimal["status"] = "Attention";
                    }

                    await LivestockStorageService.updateAnimal(updatedAnimal);
                    
                    // Trigger dynamic placement offset
                    final id = updatedAnimal["id"].toString();
                    setState(() {
                      if (forceOutside) {
                        _positions[id] = const Offset(0.7, 0.15); // near edge
                      } else {
                        _positions[id] = Offset(
                          _random.nextDouble() * 0.4 + 0.3,
                          _random.nextDouble() * 0.4 + 0.3,
                        );
                      }
                    });

                    _loadData(); // reload stats

                    ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text("GPS Tag $tag connected to ${selectedAnimal["name"]}!"),
                        backgroundColor: const Color(0xFF22C55E),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
                  child: const Text("Connect Tag", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLiveViewFullscreen() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Scaffold(
              backgroundColor: const Color(0xFFF3F4F6),
              appBar: AppBar(
                title: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text('Live Tracking View', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
                  ],
                ),
                backgroundColor: Colors.white,
                elevation: 0.5,
                actions: [
                  TextButton.icon(
                    onPressed: () {
                      _loadData();
                      setSheetState(() {});
                    },
                    icon: const Icon(Icons.refresh, color: Color(0xFF22C55E), size: 16),
                    label: const Text("Refresh", style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              body: Column(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: _buildMapWidget(true),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text(
                              "Tracked Animals (${_trackedAnimals.length})",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _trackedAnimals.length,
                              separatorBuilder: (context, idx) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final animal = _trackedAnimals[idx];
                                final isOutside = animal["isOutsideBoundary"] == true;
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundImage: NetworkImage(animal["img"] ?? ""),
                                  ),
                                  title: Text(animal["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text("${animal["type"]} • ${animal["location"]}"),
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: isOutside ? const Color(0xFFFFF0F0) : const Color(0xFFEAF8F2),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isOutside ? Colors.redAccent : const Color(0xFF22C55E)),
                                    ),
                                    child: Text(
                                      isOutside ? "Alert" : "Safe",
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: isOutside ? Colors.red : const Color(0xFF0F5A3E),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Animal Tracking', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937))),
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
                    // Header Area (matching image 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Animal Tracking',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Monitor animal locations and geo-fence alerts',
                                style: TextStyle(fontSize: 12.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showLiveViewFullscreen,
                          icon: const Icon(Icons.navigation, color: Colors.white, size: 16),
                          label: const Text("Live View", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF22C55E),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Stats Grid Row (4 cards matching image 1)
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Tracked Animals",
                            "$_trackedCount",
                            Icons.location_on,
                            const Color(0xFF22C55E),
                            const Color(0xFFEAF8F2),
                            null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Active GPS Tags",
                            "$_activeGpsCount",
                            Icons.send,
                            const Color(0xFF0F5A3E),
                            const Color(0xFFEAF8F2),
                            "96% online",
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            "Geo-fence Alerts",
                            "$_alertCount",
                            Icons.warning_amber_rounded,
                            const Color(0xFFF57C00),
                            const Color(0xFFFFFBEB),
                            "Today",
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            "Outside Boundary",
                            "$_outsideCount",
                            Icons.warning_amber_rounded,
                            Colors.redAccent,
                            const Color(0xFFFFF0F0),
                            null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Map Section
                    _buildMapHeader(),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 280,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: _buildMapWidget(false),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Active Alerts List (matching image 2)
                    _buildActiveAlertsSection(),
                    const SizedBox(height: 24),

                    // Recently Active List (matching image 3)
                    _buildRecentlyActiveSection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddGpsDialog,
        backgroundColor: const Color(0xFF22C55E),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Add GPS Option", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildStatCard(String title, String val, IconData icon, Color iconColor, Color bgIconColor, String? subtitle) {
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
              Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: bgIconColor, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(val, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w500)),
          ]
        ],
      ),
    );
  }

  Widget _buildMapHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Live Tracking Pasture Map",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.zoom_in, color: Color(0xFF22C55E)),
              onPressed: () {
                setState(() {
                  _zoomScale = (_zoomScale + 0.1).clamp(0.8, 1.8);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.zoom_out, color: Color(0xFF22C55E)),
              onPressed: () {
                setState(() {
                  _zoomScale = (_zoomScale - 0.1).clamp(0.8, 1.8);
                });
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMapWidget(bool isLarge) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Grid background painter
            Positioned.fill(
              child: CustomPaint(
                painter: MapGridPainter(zoomScale: _zoomScale),
              ),
            ),

            // Geo-fence boundary circles / overlays
            Positioned(
              left: constraints.maxWidth * 0.15,
              top: constraints.maxHeight * 0.15,
              child: _buildFenceOverlay("North Pasture", constraints.maxWidth * 0.45, constraints.maxHeight * 0.45, Colors.green),
            ),
            Positioned(
              left: constraints.maxWidth * 0.55,
              top: constraints.maxHeight * 0.12,
              child: _buildFenceOverlay("East Field", constraints.maxWidth * 0.35, constraints.maxHeight * 0.38, Colors.green),
            ),
            Positioned(
              left: constraints.maxWidth * 0.3,
              top: constraints.maxHeight * 0.5,
              child: _buildFenceOverlay("Stable Area", constraints.maxWidth * 0.3, constraints.maxHeight * 0.38, Colors.orange),
            ),

            // Map Pins for tracked animals
            ..._trackedAnimals.map((animal) {
              final id = animal["id"].toString();
              final pos = _positions[id] ?? const Offset(0.5, 0.5);
              final isHighlighted = id == _highlightedAnimalId;
              final isOutside = animal["isOutsideBoundary"] == true;

              return Positioned(
                left: constraints.maxWidth * pos.dx - 20,
                top: constraints.maxHeight * pos.dy - 35,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _highlightedAnimalId = isHighlighted ? null : id;
                    });
                  },
                  child: Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isOutside ? Colors.red : const Color(0xFF22C55E),
                          boxShadow: [
                            BoxShadow(
                              color: isHighlighted ? Colors.yellowAccent : Colors.black26,
                              blurRadius: isHighlighted ? 12 : 4,
                              spreadRadius: isHighlighted ? 4 : 0,
                            )
                          ],
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          isOutside ? Icons.warning_amber_rounded : Icons.location_on,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(
                          animal["name"] ?? "",
                          style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Geo-fence legend table (matching image 2)
            if (!isLarge)
              Positioned(
                left: 10,
                bottom: 10,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("GEO-FENCE ZONES", style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 6),
                      _buildLegendRow("North Pasture", 42, Colors.green),
                      _buildLegendRow("East Field", 28, Colors.green),
                      _buildLegendRow("Stable Area", 15, Colors.orange),
                      _buildLegendRow("Hill Pasture", 22, Colors.orange),
                    ],
                  ),
                ),
              ),

            // Zoom level indicator
            Positioned(
              right: 10,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "Zoom: ${(_zoomScale * 100).toStringAsFixed(0)}%",
                  style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFenceOverlay(String zoneName, double width, double height, Color boundaryColor) {
    return Container(
      width: width * _zoomScale,
      height: height * _zoomScale,
      decoration: BoxDecoration(
        color: boundaryColor.withOpacity(0.04),
        border: Border.all(
          color: boundaryColor.withOpacity(0.4),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(100), // round pasture zones
      ),
    );
  }

  Widget _buildLegendRow(String zone, int count, Color col) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: col, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(zone, style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
          const SizedBox(width: 4),
          Text("($count)", style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildActiveAlertsSection() {
    final outside = _trackedAnimals.where((a) => a["isOutsideBoundary"] == true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
            SizedBox(width: 8),
            Text(
              "Active Alerts",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (outside.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              "All animals are safe inside pasture boundaries.",
              style: TextStyle(color: Color(0xFF0F5A3E), fontSize: 13, fontWeight: FontWeight.bold),
            ),
          )
        else
          ...outside.map((animal) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0F0),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFD3D1)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                    child: const Icon(Icons.priority_high, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${animal["name"]} - Outside Boundary",
                          style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF7F1D1D)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Detected 50m outside ${animal["location"]} geo-fence.",
                          style: const TextStyle(fontSize: 11.5, color: Color(0xFFB91C1C)),
                        ),
                      ],
                    ),
                  ),
                  const Text("Just now", style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildRecentlyActiveSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Recently Active",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _trackedAnimals.length,
          itemBuilder: (context, index) {
            final animal = _trackedAnimals[index];
            final id = animal["id"].toString();
            final isOutside = animal["isOutsideBoundary"] == true;
            final isSelected = id == _highlightedAnimalId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFEAF8F2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isSelected ? const Color(0xFF22C55E) : const Color(0xFFE5E7EB)),
              ),
              child: ListTile(
                onTap: () {
                  setState(() {
                    _highlightedAnimalId = isSelected ? null : id;
                  });
                },
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(animal["img"] ?? ""),
                  radius: 20,
                ),
                title: Text(animal["name"] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(animal["location"] ?? ""),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: isOutside ? const Color(0xFFFFF0F0) : const Color(0xFFEAF8F2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isOutside ? Colors.red : const Color(0xFF22C55E)),
                      ),
                      child: Text(
                        isOutside ? "Alert" : "Safe",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isOutside ? Colors.red : const Color(0xFF0F5A3E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right,
                      color: isSelected ? const Color(0xFF22C55E) : Colors.grey,
                    )
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

// Custom Painter to draw grid lines on map
class MapGridPainter extends CustomPainter {
  final double zoomScale;

  MapGridPainter({required this.zoomScale});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFC8E6C9).withOpacity(0.35)
      ..strokeWidth = 1;

    final double step = 25.0 * zoomScale;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MapGridPainter oldDelegate) => oldDelegate.zoomScale != zoomScale;
}

// Reusable dashed border painter
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
