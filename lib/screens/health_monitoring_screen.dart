import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/livestock_storage.dart';
import '../services/notification_service.dart';
import 'health_record_detail_sheet.dart';

class HealthMonitoringScreen extends StatefulWidget {
  final int initialTab;
  final bool hideBackButton;
  const HealthMonitoringScreen({
    Key? key,
    this.initialTab = 0,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<HealthMonitoringScreen> createState() => _HealthMonitoringScreenState();
}

class _HealthMonitoringScreenState extends State<HealthMonitoringScreen> {
  List<Map<String, dynamic>> _animals = [];
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  int _activeTab = 0; // 0 for Health Records, 1 for Vaccination Schedule

  // Stat count calculations
  int _healthChecksCount = 24;
  int _vaccinesDueCount = 12;
  int _treatmentsCount = 3;
  double _healthScore = 94.0;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    final animals = await LivestockStorageService.getAnimals();
    final records = await LivestockStorageService.getHealthRecords();
    
    // Calculate dynamic stats
    final completedChecks = records.where((r) => r["type"] == "Health Check" && r["status"] == "completed").length;
    final scheduledVaccines = records.where((r) => r["type"] == "Vaccination" && r["status"] == "scheduled").length;
    final criticalAnimals = animals.where((a) => a["status"] == "Critical").length;
    final healthyAnimals = animals.where((a) => a["status"] == "Healthy").length;

    setState(() {
      _animals = animals;
      _records = records;
      _isLoading = false;

      _healthChecksCount = completedChecks;
      _vaccinesDueCount = scheduledVaccines;
      _treatmentsCount = criticalAnimals;
      
      if (animals.isNotEmpty) {
        _healthScore = (healthyAnimals / animals.length) * 100;
      }
    });
  }

  void _showAddRecordSheet() {
    if (_animals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add an animal first before recording a health record.")),
      );
      return;
    }

    Map<String, dynamic> selectedAnimal = _animals.first;
    String selectedRecordType = "Vaccination";
    final titleController = TextEditingController();
    final notesController = TextEditingController();
    DateTime? selectedDate;
    final dateDisplayController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Add Health Record",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Record a health event, vaccination, or treatment.",
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Animal Selector Dropdown
                    const Text("Animal *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedAnimal["id"],
                          isExpanded: true,
                          items: _animals
                              .map((a) => DropdownMenuItem<String>(
                                    value: a["id"].toString(),
                                    child: Text("${a["name"]} (${a["type"]} - ${a["breed"]})"),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() {
                                selectedAnimal = _animals.firstWhere((a) => a["id"] == value);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Record Type Dropdown
                    const Text("Record Type *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedRecordType,
                          isExpanded: true,
                          items: ["Health Check", "Vaccination", "Treatment"]
                              .map((type) => DropdownMenuItem<String>(value: type, child: Text(type)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setSheetState(() {
                                selectedRecordType = value;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title Field
                    const Text("Title *", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        hintText: "e.g., Annual Vaccination or FMD Booster",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    const Text("Notes", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Add any additional notes about this record...",
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Next Due Date Datepicker
                    const Text("Next Due Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: dateDisplayController,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: Color(0xFF22C55E),
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setSheetState(() {
                            selectedDate = picked;
                            dateDisplayController.text = DateFormat('yyyy-MM-dd').format(picked);
                          });
                        }
                      },
                      decoration: InputDecoration(
                        hintText: "dd-mm-yyyy",
                        suffixIcon: const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF22C55E)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Cancel", style: TextStyle(color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final title = titleController.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Title is required!")),
                                );
                                return;
                              }

                              final dateStr = DateFormat('MMM dd, yyyy').format(DateTime.now());

                              final newRecord = {
                                "animalId": selectedAnimal["id"],
                                "animalName": selectedAnimal["name"],
                                "animalType": selectedAnimal["type"],
                                "type": selectedRecordType,
                                "title": title,
                                "notes": notesController.text.trim().isEmpty 
                                    ? "Healthy record entry" 
                                    : notesController.text.trim(),
                                "date": dateStr,
                                "doctor": "Dr. Jayasurya", // Mock logged in doctor
                                "status": selectedDate == null ? "completed" : "scheduled",
                                "dueDate": selectedDate == null 
                                    ? "" 
                                    : DateFormat('yyyy-MM-dd').format(selectedDate!)
                              };

                              await LivestockStorageService.addHealthRecord(newRecord);
                              await LivestockStorageService.checkAndGenerateAlerts((alert) {
                                AppNotificationService.triggerNotification(alert);
                              });
                              Navigator.pop(context); // Close sheet
                              _loadData(); // Reload stats & records

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Health record for ${selectedAnimal["name"]} added!"),
                                  backgroundColor: const Color(0xFF22C55E),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF22C55E),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text("Add Record", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
      backgroundColor: const Color(0xFFF7F9FB),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  if (!widget.hideBackButton) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF22C55E)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Health Monitoring",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Track health records and vaccination schedules",
                          style: TextStyle(fontSize: 12.5, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showAddRecordSheet,
                    icon: const Icon(Icons.add, color: Colors.white, size: 16),
                    label: const Text("Add Record", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),

            // Statistics Grid (4 cards)
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildHealthStatsGrid(),
            ),

            // Tabs Selector
            _buildTabsSelector(),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Records List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF22C55E)))
                  : _activeTab == 0
                      ? _buildHealthRecordsList()
                      : _buildVaccinationScheduleList(),
            ),
          ],
        ),
      ),
    );
  }

  // Health statistics grid builder
  Widget _buildHealthStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double childAspectRatio = constraints.maxWidth < 450 ? 1.4 : 1.15;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: childAspectRatio,
          children: [
            // Health Checks
            _buildHealthStatCard(
              title: "Health Checks",
              value: "$_healthChecksCount",
              subtext: "This month",
              icon: Icons.favorite_border,
              iconColor: const Color(0xFF22C55E),
              bgIconColor: const Color(0xFFEAF8F2),
              cardColor: const Color(0xFFEAF8F2),
              textColor: const Color(0xFF0F5A3E),
            ),
            // Vaccinations Due
            _buildHealthStatCard(
              title: "Vaccinations Due",
              value: "$_vaccinesDueCount",
              subtext: "Next 30 days",
              icon: Icons.edit_calendar_outlined,
              iconColor: const Color(0xFFF57C00),
              bgIconColor: const Color(0xFFFEEFCD),
              cardColor: const Color(0xFFFFFBEB),
              textColor: const Color(0xFFC26100),
            ),
            // Active Treatments
            _buildHealthStatCard(
              title: "Active Treatments",
              value: "$_treatmentsCount",
              subtext: "High warning",
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFE53935),
              bgIconColor: const Color(0xFFFFD3D1),
              cardColor: const Color(0xFFFFF0F0),
              textColor: const Color(0xFFD32F2F),
            ),
            // Health Score
            _buildHealthStatCard(
              title: "Health Score",
              value: "${_healthScore.toStringAsFixed(0)}%",
              subtext: "↑ 2.5% vs last week",
              icon: Icons.trending_up,
              iconColor: const Color(0xFF22C55E),
              bgIconColor: const Color(0xFFE2FBE9),
              cardColor: Colors.white,
              textColor: Colors.black,
              isWhiteCard: true,
            ),
          ],
        );
      },
    );
  }

  // Health stat card helper
  Widget _buildHealthStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    required Color cardColor,
    required Color textColor,
    bool isWhiteCard = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWhiteCard ? const Color(0xFFE5E7EB) : Colors.transparent,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isWhiteCard ? const Color(0xFF4B5563) : textColor.withOpacity(0.8),
                  ),
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtext,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isWhiteCard ? const Color(0xFF9CA3AF) : textColor.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tab selector builder
  Widget _buildTabsSelector() {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _activeTab = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _activeTab == 0 ? const Color(0xFF22C55E) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                "Health Records",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _activeTab == 0 ? const Color(0xFF22C55E) : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: InkWell(
            onTap: () => setState(() => _activeTab = 1),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: _activeTab == 1 ? const Color(0xFF22C55E) : Colors.transparent,
                    width: 2.5,
                  ),
                ),
              ),
              child: Text(
                "Vaccination Schedule",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _activeTab == 1 ? const Color(0xFF22C55E) : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                  fontSize: 14.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Health records tab list view
  Widget _buildHealthRecordsList() {
    if (_records.isEmpty) {
      return const Center(child: Text("No health records recorded."));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final isCompleted = record["status"] == "completed";

        return InkWell(
          onTap: () => showHealthRecordDetailSheet(context, record, _animals, _loadData),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF8F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite, color: Color(0xFF22C55E), size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              record["animalName"] ?? "Unknown",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                (record["animalType"] ?? "Cattle").toString().toLowerCase(),
                                style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          record["title"] ?? "Checkup",
                          style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        record["date"] ?? "Today",
                        style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isCompleted ? const Color(0xFFE8F5E9) : const Color(0xFFFEEFCD),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          record["status"] ?? "completed",
                          style: TextStyle(
                            fontSize: 10,
                            color: isCompleted ? const Color(0xFF1B4332) : const Color(0xFFC26100),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                record["notes"] ?? "",
                style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.3),
              ),
              const SizedBox(height: 8),
              Text(
                "Examiner: ${record["doctor"] ?? "Vet"}",
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),);
      },
    );
  }

  // Vaccination schedule tab list view
  Widget _buildVaccinationScheduleList() {
    final upcomingVaccines = _records
        .where((r) => r["type"] == "Vaccination" && r["status"] == "scheduled")
        .toList();

    if (upcomingVaccines.isEmpty) {
      return const Center(child: Text("No upcoming vaccinations scheduled."));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Upcoming Vaccinations",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcomingVaccines.length,
            itemBuilder: (context, index) {
              final vac = upcomingVaccines[index];
              
              // Calculate days left
              String daysLeftStr = "7 days left";
              if (vac["dueDate"] != null && vac["dueDate"].toString().isNotEmpty) {
                try {
                  final dueDate = DateTime.parse(vac["dueDate"]);
                  // Calculate diff from Jan 26, 2026 (seeding date) or DateTime.now()
                  final diff = dueDate.difference(DateTime.now()).inDays;
                  if (diff < 0) {
                    daysLeftStr = "Overdue";
                  } else if (diff == 0) {
                    daysLeftStr = "Due Today";
                  } else {
                    daysLeftStr = "$diff days left";
                  }
                } catch (e) {
                  daysLeftStr = "Scheduled";
                }
              }

              return InkWell(
                onTap: () => showHealthRecordDetailSheet(context, vac, _animals, _loadData),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.vaccines, color: Color(0xFFF57C00), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vac["animalName"] ?? "",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            vac["title"] ?? "Booster",
                            style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              vac["date"] ?? "",
                              style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3E0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            daysLeftStr,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFFF57C00),
                              fontWeight: FontWeight.bold,
                            ),
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
        ],
      ),
    );
  }
}
