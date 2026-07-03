import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'animals_screen.dart';
import 'health_monitoring_screen.dart';
import '../services/livestock_storage.dart';
import 'animal_detail_sheet.dart';
import 'animal_disease_scan_screen.dart';
import 'animal_tracking_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'feed_planner_screen.dart';
import 'environment_screen.dart';
import 'alerts_screen.dart';
import '../services/notification_service.dart';

class LivestockHomeScreen extends StatefulWidget {
  const LivestockHomeScreen({Key? key}) : super(key: key);

  @override
  State<LivestockHomeScreen> createState() => _LivestockHomeScreenState();
}

class _LivestockHomeScreenState extends State<LivestockHomeScreen> {
  String _lastUpdatedTime = "8:37:38 am";
  bool _isRefreshingPrices = false;
  int _activeSidebarIndex = 0; // Default starts at Dashboard (index 0)
  Timer? _priceTimer;
  Timer? _notificationTimer;
  Map<String, dynamic>? _incomingNotification;

  List<Map<String, dynamic>> _animals = [];
  List<Map<String, dynamic>> _records = [];
  bool _isLoadingDashboard = true;

  int _totalAnimalsCount = 0;
  int _healthyCount = 0;
  int _attentionCount = 0;
  int _criticalCount = 0;
  int _vaccinesDueCount = 0;
  double _loggedMilk = 0.0;
  int _loggedEggs = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _fetchLivePrices(); // Initial live price fetch
    // Auto update live prices every 30 seconds
    _priceTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _fetchLivePrices();
    });

    // Listen to simulated push notifications
    AppNotificationService.activeNotification.addListener(_onNotificationReceived);

    // Initial alert scan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      LivestockStorageService.checkAndGenerateAlerts((alert) {
        AppNotificationService.triggerNotification(alert);
      });
    });
  }

  @override
  void dispose() {
    _priceTimer?.cancel();
    _notificationTimer?.cancel();
    AppNotificationService.activeNotification.removeListener(_onNotificationReceived);
    super.dispose();
  }

  void _onNotificationReceived() {
    final alert = AppNotificationService.activeNotification.value;
    if (alert != null && mounted) {
      setState(() {
        _incomingNotification = alert;
      });
      _notificationTimer?.cancel();
      _notificationTimer = Timer(const Duration(seconds: 6), () {
        if (mounted) {
          setState(() {
            _incomingNotification = null;
          });
        }
      });
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
    });
    
    final animals = await LivestockStorageService.getAnimals();
    final records = await LivestockStorageService.getHealthRecords();

    final healthy = animals.where((a) => a["status"].toString().toLowerCase() == "healthy").length;
    final attention = animals.where((a) => a["status"].toString().toLowerCase() == "attention" || a["status"].toString().toLowerCase() == "needs attention").length;
    final critical = animals.where((a) => a["status"].toString().toLowerCase() == "critical").length;
    final vaccines = records.where((r) => r["type"] == "Vaccination" && r["status"] == "scheduled").length;

    setState(() {
      _animals = animals;
      _records = records;
      _isLoadingDashboard = false;

      _totalAnimalsCount = animals.length;
      _healthyCount = healthy;
      _attentionCount = attention;
      _criticalCount = critical;
      _vaccinesDueCount = vaccines;
    });
  }

  // Sidebar or Drawer menu options
  final List<Map<String, dynamic>> _menuItems = [
    {"name": "Dashboard", "icon": Icons.grid_view_outlined},       // Index 0
    {"name": "Animals", "icon": Icons.pets_outlined},              // Index 1
    {"name": "Health", "icon": Icons.monitor_heart_outlined},      // Index 2
    {"name": "Tracking", "icon": Icons.location_on_outlined},      // Index 3
    {"name": "Feed Planner", "icon": Icons.restaurant_outlined},   // Index 4
    {"name": "Disease Detection", "icon": Icons.healing_outlined}, // Index 5
    {"name": "Environment", "icon": Icons.thermostat_outlined},    // Index 6
    {"name": "Analytics", "icon": Icons.insert_chart_outlined},    // Index 7
    {"name": "Alerts", "icon": Icons.notifications_none_outlined}, // Index 8
  ];

  // Live Market Prices list that can be updated on refresh
  final List<Map<String, dynamic>> _marketPrices = [
    {"name": "Cattle (Meat)", "unit": "per kg", "price": 320, "change": 2.5, "isUp": true, "icon": Icons.pets},
    {"name": "Buffalo (Meat)", "unit": "per kg", "price": 290, "change": 1.8, "isUp": true, "icon": Icons.pets_outlined},
    {"name": "Goat (Meat)", "unit": "per kg", "price": 720, "change": -0.5, "isUp": false, "icon": Icons.eco_outlined},
    {"name": "Sheep (Meat)", "unit": "per kg", "price": 680, "change": 1.2, "isUp": true, "icon": Icons.bubble_chart_outlined},
    {"name": "Milk (Cow)", "unit": "per litre", "price": 52, "change": 3.5, "isUp": true, "icon": Icons.local_drink_outlined},
    {"name": "Milk (Buffalo)", "unit": "per litre", "price": 65, "change": 2.1, "isUp": true, "icon": Icons.local_drink},
    {"name": "Eggs", "unit": "per piece", "price": 6.5, "change": -1.5, "isUp": false, "icon": Icons.egg_outlined},
    {"name": "Chicken (Meat)", "unit": "per kg", "price": 240, "change": 4.2, "isUp": true, "icon": Icons.restaurant_outlined},
  ];

  Future<void> _refreshPrices() async {
    setState(() {
      _isRefreshingPrices = true;
    });
    await _fetchLivePrices();
    setState(() {
      _isRefreshingPrices = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Market prices updated!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  Future<void> _fetchLivePrices() async {
    final tickers = {
      'LE=F': 'Cattle',
      'HE=F': 'Hog',
      'DA=F': 'Milk',
      'ZC=F': 'Corn',
    };

    final Map<String, double> latestPrices = {};
    final Map<String, double> prevCloses = {};

    try {
      final futures = tickers.keys.map((ticker) async {
        final url = Uri.parse("https://query1.finance.yahoo.com/v8/finance/chart/$ticker");
        final response = await http.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final result = data['chart']['result']?[0];
          final meta = result?['meta'];
          if (meta != null) {
            final double price = (meta['regularMarketPrice'] as num).toDouble();
            final double prev = (meta['chartPreviousClose'] as num).toDouble();
            latestPrices[ticker] = price;
            prevCloses[ticker] = prev;
          }
        }
      }).toList();

      await Future.wait(futures);
    } catch (e) {
      debugPrint("Error fetching live prices: $e");
    }

    if (latestPrices.isNotEmpty && mounted) {
      final now = DateTime.now();
      final hours = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
      final minutes = now.minute.toString().padLeft(2, '0');
      final seconds = now.second.toString().padLeft(2, '0');
      final ampm = now.hour >= 12 ? 'pm' : 'am';

      setState(() {
        _lastUpdatedTime = "$hours:$minutes:$seconds $ampm";
        
        for (var item in _marketPrices) {
          final name = item["name"];
          String? ticker;
          double baseGlobal = 1.0;
          double baseLocal = 1.0;
          bool isFloat = false;

          if (name == "Cattle (Meat)") {
            ticker = 'LE=F';
            baseGlobal = 240.0;
            baseLocal = 320.0;
          } else if (name == "Buffalo (Meat)") {
            ticker = 'LE=F';
            baseGlobal = 240.0;
            baseLocal = 290.0;
          } else if (name == "Goat (Meat)") {
            ticker = 'HE=F';
            baseGlobal = 95.0;
            baseLocal = 720.0;
          } else if (name == "Sheep (Meat)") {
            ticker = 'HE=F';
            baseGlobal = 95.0;
            baseLocal = 680.0;
          } else if (name == "Milk (Cow)") {
            ticker = 'DA=F';
            baseGlobal = 17.5;
            baseLocal = 52.0;
          } else if (name == "Milk (Buffalo)") {
            ticker = 'DA=F';
            baseGlobal = 17.5;
            baseLocal = 65.0;
          } else if (name == "Eggs") {
            ticker = 'ZC=F';
            baseGlobal = 420.0;
            baseLocal = 6.5;
            isFloat = true;
          } else if (name == "Chicken (Meat)") {
            ticker = 'ZC=F';
            baseGlobal = 420.0;
            baseLocal = 240.0;
          }

          if (ticker != null && latestPrices.containsKey(ticker)) {
            final priceGlobal = latestPrices[ticker]!;
            final prevGlobal = prevCloses[ticker]!;
            
            final rawPrice = (priceGlobal / baseGlobal) * baseLocal;
            if (isFloat) {
              item["price"] = double.parse(rawPrice.toStringAsFixed(1));
            } else {
              item["price"] = rawPrice.round();
            }

            final double pctChange = ((priceGlobal - prevGlobal) / prevGlobal) * 100;
            item["change"] = double.parse(pctChange.toStringAsFixed(1));
            item["isUp"] = pctChange >= 0;
          }
        }
      });
    }
  }

  void _showFeatureNotImplemented(String featureName) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.settings_suggest_outlined,
                      color: Color(0xFF22C55E),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          featureName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Feature Coming Soon",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                "We are actively building the agricultural components one by one. The '$featureName' feature will allow full operational tracking in the next update.",
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    "Got it, thanks!",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddProductionSheet() {
    final cattleCount = _animals.where((a) => a["type"] == "Cattle").length;
    final chickensCount = _animals.where((a) => a["type"] == "Chickens").length;
    final milkController = TextEditingController(text: ((cattleCount * 25.0) + _loggedMilk).toStringAsFixed(0));
    final eggsController = TextEditingController(text: ((chickensCount * 5) + _loggedEggs).toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Today's Production"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: milkController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Milk Collected (Liters)",
                suffixText: "L",
                icon: Icon(Icons.water_drop, color: Colors.blue),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: eggsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Eggs Collected (Pieces)",
                suffixText: "pcs",
                icon: Icon(Icons.egg, color: Colors.orange),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              final newMilk = double.tryParse(milkController.text) ?? 0.0;
              final newEggs = int.tryParse(eggsController.text) ?? 0;
              final baseMilk = _animals.where((a) => a["type"] == "Cattle").length * 25.0;
              final baseEggs = _animals.where((a) => a["type"] == "Chickens").length * 5;
              
              setState(() {
                _loggedMilk = (newMilk - baseMilk).clamp(0.0, double.infinity);
                _loggedEggs = (newEggs - baseEggs).clamp(0, 999999);
              });
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Production rates saved successfully!"),
                  backgroundColor: Color(0xFF22C55E),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF22C55E)),
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (isMobile) {
      return _buildDashboardBody(true);
    }
    switch (_activeSidebarIndex) {
      case 0:
        return _buildDashboardBody(false);
      case 1:
        return const AnimalsScreen(hideBackButton: true);
      case 2:
        return const HealthMonitoringScreen(initialTab: 0, hideBackButton: true);
      case 3:
        return const AnimalTrackingScreen(hideBackButton: true);
      case 4:
        return const FeedPlannerScreen(hideBackButton: true);
      case 5:
        return const AnimalDiseaseScanScreen(hideBackButton: true);
      case 6:
        return const EnvironmentScreen(hideBackButton: true);
      case 7:
        return const AnalyticsDashboardScreen(hideBackButton: true);
      case 8:
        return const AlertsScreen(hideBackButton: true);
      default:
        return _buildFeatureNotImplementedWidget(_menuItems[_activeSidebarIndex]["name"]);
    }
  }

  Widget _buildFeatureNotImplementedWidget(String featureName) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        color: Colors.white,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.construction,
                  color: Color(0xFF22C55E),
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                featureName,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "This section is currently under active development.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _activeSidebarIndex = 0; // Go back to Dashboard
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                child: const Text(
                  "Return to Dashboard",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardBody(bool isMobile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back Button Row (Only on mobile as navigation is handled via sidebar on desktop)
          if (isMobile) ...[
            Align(
              alignment: Alignment.topLeft,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.arrow_back, color: Color(0xFF22C55E), size: 18),
                      SizedBox(width: 8),
                      Text(
                        "Back",
                        style: TextStyle(
                          color: Color(0xFF22C55E),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Greeting Row containing Menu Button (if mobile) and Greeting Title/Subtitle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isMobile) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 4), // Align vertically with greeting text
                  child: Builder(
                    builder: (context) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.menu, color: Color(0xFF22C55E), size: 24),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: const TextSpan(
                        text: "Good morning, Farmer! ",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                          fontFamily: 'serif',
                        ),
                        children: [
                          TextSpan(
                            text: "🌾",
                            style: TextStyle(fontFamily: 'sans-serif'),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Here's what's happening on your farm today",
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Stats Grid Layout
          _buildStatsGrid(),
          const SizedBox(height: 32),

          // Your Animals Section
          _buildYourAnimalsHeader(),
          const SizedBox(height: 16),
          _buildYourAnimalsHorizontalList(),
          const SizedBox(height: 32),

          // Weekly Productivity Spline Chart Card
          _buildWeeklyProductivityCard(),
          const SizedBox(height: 32),

          // Quick Actions Grid (Green-bordered items)
          const Text(
            "QUICK ACTIONS",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          _buildQuickActionsGrid(),
          const SizedBox(height: 32),

          // Live Market Prices Card
          _buildLiveMarketPricesCard(),
          const SizedBox(height: 32),

          // Recent Alerts Card
          _buildRecentAlertsHeader(),
          const SizedBox(height: 16),
          _buildRecentAlertsList(),
          const SizedBox(height: 32),

          // Today's Production Card
          _buildTodayProductionCard(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      // Set the mobile Drawer navigation
      drawer: isMobile ? _buildMobileDrawer() : null,
      body: SafeArea(
        child: Stack(
          children: [
            Row(
              children: [
                // Sidebar Section (Only visible on tablet/desktop layouts)
                if (!isMobile) _buildSidebar(),
      
                // Main Content Section
                Expanded(
                  child: _buildBody(isMobile),
                ),
              ],
            ),
            if (_incomingNotification != null) _buildPushNotificationOverlay(isMobile),
          ],
        ),
      ),
    );
  }

  Widget _buildPushNotificationOverlay(bool isMobile) {
    if (_incomingNotification == null) return const SizedBox.shrink();

    final alert = _incomingNotification!;
    final title = alert["title"] ?? "";
    final message = alert["message"] ?? "";

    return Positioned(
      top: 16,
      left: isMobile ? 16 : null,
      right: 16,
      width: isMobile ? MediaQuery.of(context).size.width - 32 : 360,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _incomingNotification = null;
            });
            AppNotificationService.clearNotification();
            
            // Route/navigate to Alerts screen
            if (isMobile) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AlertsScreen(hideBackButton: false)),
              );
            } else {
              setState(() {
                _activeSidebarIndex = 8; // Switch sidebar selection to Alerts (index 8)
              });
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.9), // Premium dark system notification card
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFF14372A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF22C55E),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "AGRIGROW - REMINDER",
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                          Text(
                            "now",
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Persistent Left Sidebar for wide view (Tablet/Desktop) - expanded to match layout design
  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: const Color(0xFF14372A),
      child: Column(
        children: [
          // Sidebar Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2A33A), // Mustard Orange background
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco, // Leaf icon
                    color: Color(0xFF14372A),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "FARMER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          fontFamily: 'serif',
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Livestock Manager",
                        style: TextStyle(
                          color: Color(0xFF8DA399),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),

          // Navigation items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final isSelected = index == _activeSidebarIndex;
                final item = _menuItems[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _activeSidebarIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE2953B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item["icon"],
                          color: isSelected ? const Color(0xFF14372A) : const Color(0xFFD1D5DB),
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item["name"],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF14372A) : const Color(0xFFD1D5DB),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Collapse option
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
            margin: const EdgeInsets.only(top: 12, bottom: 8),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    // Navigate back to home screen
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: const [
                        Icon(Icons.chevron_left, color: Color(0xFF8DA399), size: 22),
                        SizedBox(width: 16),
                        Text(
                          "Collapse",
                          style: TextStyle(
                            color: Color(0xFF8DA399),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mobile Drawer Navigation for narrow view (Mobile phone)
  Widget _buildMobileDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF14372A),
      child: Column(
        children: [
          // Drawer Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            color: const Color(0xFF0C271E), // Darker green accent
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2A33A), // Mustard Orange background
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco, // Leaf icon
                    color: Color(0xFF14372A),
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        "FARMER",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          fontFamily: 'serif',
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        "Livestock Manager",
                        style: TextStyle(
                          color: Color(0xFF8DA399),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          // List of items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                final item = _menuItems[index];
                final isSelected = index == _activeSidebarIndex;
                return InkWell(
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    if (index == 0) {
                      setState(() {
                        _activeSidebarIndex = 0;
                      });
                    } else if (index == 1) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimalsScreen()),
                      ).then((_) => _loadDashboardData());
                    } else if (index == 2) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HealthMonitoringScreen(initialTab: 0)),
                      ).then((_) => _loadDashboardData());
                    } else if (index == 3) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimalTrackingScreen()),
                      );
                    } else if (index == 4) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const FeedPlannerScreen()),
                      );
                    } else if (index == 5) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnimalDiseaseScanScreen()),
                      );
                    } else if (index == 6) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EnvironmentScreen(hideBackButton: false)),
                      );
                    } else if (index == 7) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
                      );
                    } else if (index == 8) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AlertsScreen(hideBackButton: false)),
                      );
                    } else {
                      _showFeatureNotImplemented(item["name"]);
                    }
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE2953B) : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item["icon"],
                          color: isSelected ? const Color(0xFF14372A) : const Color(0xFFD1D5DB),
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          item["name"],
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF14372A) : const Color(0xFFD1D5DB),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.06),
            margin: const EdgeInsets.symmetric(horizontal: 20),
          ),
          // Exit Dashboard option
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.logout, color: Color(0xFFD1D5DB), size: 22),
                  title: const Text("Exit Dashboard", style: TextStyle(color: Color(0xFFD1D5DB), fontSize: 15, fontWeight: FontWeight.w500)),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pop(context); // Return to home screen
                  },
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Stats Grid Builder
  Widget _buildStatsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 6 : 3;
        final isWide = constraints.maxWidth > 800;
        final childAspectRatio = isWide ? 1.15 : 0.78;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: childAspectRatio,
          children: [
            // Total Animals
            _buildStatCard(
              title: "Total Animals",
              value: "$_totalAnimalsCount",
              icon: Icons.pets,
              iconColor: const Color(0xFF22C55E),
              bgIconColor: const Color(0xFFE2FBE9),
              cardColor: Colors.white,
              textColor: Colors.black,
              subtext: "vs last week",
              subvalue: "↑ 3.2%",
              subvalueColor: const Color(0xFF22C55E),
            ),
            // Healthy
            _buildStatCard(
              title: "Healthy",
              value: "$_healthyCount",
              icon: Icons.favorite,
              iconColor: const Color(0xFF0F5A3E),
              bgIconColor: const Color(0xFFC4F2DD),
              cardColor: const Color(0xFFEAF8F2),
              textColor: const Color(0xFF0F5A3E),
            ),
            // Needs Attention
            _buildStatCard(
              title: "Needs Attention",
              value: "$_attentionCount",
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFC26100),
              bgIconColor: const Color(0xFFFEEFCD),
              cardColor: const Color(0xFFFFF7E6),
              textColor: const Color(0xFFC26100),
            ),
            // Critical
            _buildStatCard(
              title: "Critical",
              value: "$_criticalCount",
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFD32F2F),
              bgIconColor: const Color(0xFFFFD3D1),
              cardColor: const Color(0xFFFFF0F0),
              textColor: const Color(0xFFD32F2F),
            ),
            // Vaccines Due
            _buildStatCard(
              title: "Vaccines Due",
              value: "$_vaccinesDueCount",
              icon: Icons.vaccines,
              iconColor: const Color(0xFF22C55E),
              bgIconColor: const Color(0xFFE2FBE9),
              cardColor: Colors.white,
              textColor: Colors.black,
              subtext: "Next 7 days",
            ),
            // Milk Today
            _buildStatCard(
              title: "Milk Today",
              value: "${((_animals.where((a) => a["type"] == "Cattle").length * 25.0) + _loggedMilk).toStringAsFixed(0)}L",
              icon: Icons.water_drop_outlined,
              iconColor: const Color(0xFF22C55E),
              bgIconColor: const Color(0xFFE2FBE9),
              cardColor: Colors.white,
              textColor: Colors.black,
              subtext: "vs last week",
              subvalue: "↑ 8.5%",
              subvalueColor: const Color(0xFF22C55E),
            ),
          ],
        );
      },
    );
  }

  // Stat Card Widget Helper
  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
    required Color cardColor,
    required Color textColor,
    String? subtext,
    String? subvalue,
    Color? subvalueColor,
  }) {
    final isWhiteCard = cardColor == Colors.white;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20), // Rounder corners matching screenshot
        border: Border.all(
          color: isWhiteCard ? const Color(0xFFE5E7EB) : Colors.transparent,
          width: 1.2,
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
                    color: isWhiteCard ? const Color(0xFF4B5563) : textColor.withOpacity(0.85),
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgIconColor,
                  borderRadius: BorderRadius.circular(10), // Squircle matching screenshot
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 32, // Large bold digits
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              if (subvalue != null || subtext != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (subvalue != null)
                      Text(
                        subvalue,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: subvalueColor ?? Colors.black,
                        ),
                      ),
                    if (subtext != null)
                      Text(
                        subtext,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Your Animals Header Builder
  Widget _buildYourAnimalsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Your Animals",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Quick overview of your livestock",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        OutlinedButton(
          onPressed: () {
            if (MediaQuery.of(context).size.width > 768) {
              setState(() {
                _activeSidebarIndex = 1; // Go to Animals panel in-place
              });
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AnimalsScreen()),
              ).then((_) => _loadDashboardData());
            }
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          ),
          child: const Text(
            "View All",
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Your Animals Horizontal List Builder
  Widget _buildYourAnimalsHorizontalList() {
    if (_isLoadingDashboard) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF22C55E)),
        ),
      );
    }

    if (_animals.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.pets_outlined,
                color: Color(0xFF22C55E),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "No animals registered yet",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Add animals to start tracking their health and yield.",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _animals.length,
        itemBuilder: (context, index) {
          final animal = _animals[index];
          final status = animal["status"] ?? "Healthy";
          final isHealthy = status.toString().toLowerCase() == "healthy";
          return InkWell(
            onTap: () => showAnimalDetailSheet(context, animal, _loadDashboardData),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 220,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Stack(
              children: [
                // Background Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    animal["img"] ?? "",
                    height: double.infinity,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      alignment: Alignment.center,
                      child: const Icon(Icons.pets, size: 48, color: Colors.grey),
                    ),
                  ),
                ),
                // Soft Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.7),
                      ],
                    ),
                  ),
                ),
                // Healthy / Needs Attention Status tag
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isHealthy ? const Color(0xFFE8F5E9).withOpacity(0.9) : const Color(0xFFFFEBEE).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status == "Attention" ? "Needs Attention" : status,
                      style: TextStyle(
                        color: isHealthy ? const Color(0xFF1B4332) : const Color(0xFFB71C1C),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                // Details (Name & Breed)
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        animal["name"] ?? "",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        animal["breed"] ?? "",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),);
        },
      ),
    );
  }

  // Weekly Productivity Card Builder (Custom Spline Chart)
  Widget _buildWeeklyProductivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Weekly Productivity",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Milk yield and egg production trends",
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          
          // Custom Spline Chart Drawing
          SizedBox(
            width: double.infinity,
            height: 200,
            child: CustomPaint(
              size: Size.infinite,
              painter: SplineChartPainter(),
            ),
          ),
          
          const SizedBox(height: 16),
          // Legend row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF00FF66), // Match chart color
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Milk (Liters)",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(width: 20),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFF57C00), // Match chart color
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                "Eggs",
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Quick Actions Grid Builder (With green borders and action dialog popups)
  Widget _buildQuickActionsGrid() {
    final List<Map<String, dynamic>> actions = [
      {"name": "Add Animal", "icon": Icons.add_circle_outline, "color": const Color(0xFF22C55E)},
      {"name": "Health Check", "icon": Icons.favorite_border, "color": const Color(0xFF22C55E)},
      {"name": "Feed Planner", "icon": Icons.restaurant_outlined, "color": const Color(0xFF22C55E)},
      {"name": "Disease Scan", "icon": Icons.camera_alt_outlined, "color": const Color(0xFFF57C00)},
      {"name": "Track Location", "icon": Icons.location_on_outlined, "color": const Color(0xFF22C55E)},
      {"name": "Generate Report", "icon": Icons.article_outlined, "color": Colors.grey},
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Change aspect ratio on small screens to avoid clipping icons/text
        final double ratio = constraints.maxWidth < 360 ? 2.2 : (constraints.maxWidth < 500 ? 2.6 : 3.0);
        
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: ratio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final act = actions[index];
            return InkWell(
              onTap: () {
                final isWide = MediaQuery.of(context).size.width > 768;
                if (act["name"] == "Add Animal") {
                  if (isWide) {
                    setState(() {
                      _activeSidebarIndex = 1;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnimalsScreen(openAddForm: true)),
                    ).then((_) => _loadDashboardData());
                  }
                } else if (act["name"] == "Health Check") {
                  if (isWide) {
                    setState(() {
                      _activeSidebarIndex = 2;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HealthMonitoringScreen()),
                    ).then((_) => _loadDashboardData());
                  }
                } else if (act["name"] == "Feed Planner") {
                  if (isWide) {
                    setState(() {
                      _activeSidebarIndex = 4;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const FeedPlannerScreen()),
                    ).then((_) => _loadDashboardData());
                  }
                } else if (act["name"] == "Disease Scan") {
                  if (isWide) {
                    setState(() {
                      _activeSidebarIndex = 5;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnimalDiseaseScanScreen()),
                    ).then((_) => _loadDashboardData());
                  }
                } else if (act["name"] == "Track Location") {
                  if (isWide) {
                    setState(() {
                      _activeSidebarIndex = 3;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnimalTrackingScreen()),
                    ).then((_) => _loadDashboardData());
                  }
                } else if (act["name"] == "Generate Report") {
                  if (isWide) {
                    setState(() {
                      _activeSidebarIndex = 7;
                    });
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
                    ).then((_) => _loadDashboardData());
                  }
                } else {
                  _showFeatureNotImplemented(act["name"]);
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF00FF66), // Bright neon green border matching screenshot
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(act["icon"], color: act["color"], size: 18),
                    const SizedBox(width: 8),
                    Text(
                      act["name"],
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF22C55E), // Match green labeling
                      ),
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

  // Live Market Prices Builder (Interactive Refresh)
  Widget _buildLiveMarketPricesCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.currency_rupee, color: Color(0xFF22C55E), size: 22),
                  SizedBox(width: 6),
                  Text(
                    "Live Market Prices",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: _isRefreshingPrices ? null : _refreshPrices,
                icon: _isRefreshingPrices
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF22C55E)),
                      )
                    : const Icon(Icons.refresh, color: Colors.grey, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            "Last updated: $_lastUpdatedTime",
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          
          // Market price rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _marketPrices.length,
            separatorBuilder: (context, index) => const Divider(height: 20, color: Color(0xFFF3F4F6)),
            itemBuilder: (context, index) {
              final item = _marketPrices[index];
              final priceVal = item["price"];
              final formattedPrice = priceVal is int
                  ? "₹${priceVal.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}"
                  : "₹$priceVal";
              final change = item["change"] as double;
              final isUp = item["isUp"] as bool;

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item["icon"], color: Colors.black54, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item["name"],
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF374151),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item["unit"],
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formattedPrice,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isUp ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isUp ? Icons.trending_up : Icons.trending_down,
                              color: isUp ? const Color(0xFF22C55E) : const Color(0xFFE53935),
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              "${change.abs().toStringAsFixed(1)}%",
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: isUp ? const Color(0xFF22C55E) : const Color(0xFFE53935),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              "Prices based on Indian market averages",
              style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  // Recent Alerts Header Builder
  Widget _buildRecentAlertsHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Recent Alerts",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const HealthMonitoringScreen(initialTab: 0)),
            ).then((_) => _loadDashboardData());
          },
          child: const Text(
            "View All",
            style: TextStyle(
              color: Color(0xFF22C55E),
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // Recent Alerts List Builder
  Widget _buildRecentAlertsList() {
    // Collect active critical animals for warnings
    final criticalAnimals = _animals.where((a) => a["status"].toString().toLowerCase() == "critical" || a["status"].toString().toLowerCase() == "attention").toList();
    // Collect upcoming scheduled vaccinations or health checks
    final scheduledRecords = _records.where((r) => r["status"] == "scheduled").toList();

    final List<Map<String, dynamic>> alerts = [];

    // 1. Critical Animal Alerts
    for (var a in criticalAnimals) {
      final isCrit = a["status"] == "Critical";
      alerts.add({
        "title": isCrit ? "Health Alert - ${a["name"]}" : "Checkup Needed - ${a["name"]}",
        "desc": isCrit 
            ? "${a["name"]} is showing signs of critical illness. Vet attention required."
            : "${a["name"]} is currently flagged for status: ${a["status"]}. Check notes.",
        "time": "Active",
        "icon": Icons.warning_amber_rounded,
        "indicatorColor": isCrit ? const Color(0xFFE53935) : const Color(0xFFF57C00),
        "iconColor": isCrit ? const Color(0xFFE53935) : const Color(0xFFF57C00),
        "bgIconColor": isCrit ? const Color(0xFFFFEBEE) : const Color(0xFFFFF3E0),
        "showDot": true,
      });
    }

    // 2. Upcoming Health Record Alerts
    for (var r in scheduledRecords) {
      final isVaccine = r["type"] == "Vaccination";
      alerts.add({
        "title": isVaccine ? "Vaccination Due" : "Health Check Scheduled",
        "desc": "${r["animalName"]} has an upcoming ${r["title"]} scheduled on ${r["date"]}.",
        "time": "Scheduled",
        "icon": isVaccine ? Icons.vaccines : Icons.favorite_border,
        "indicatorColor": isVaccine ? const Color(0xFF22C55E) : const Color(0xFFF57C00),
        "iconColor": isVaccine ? const Color(0xFF22C55E) : const Color(0xFFF57C00),
        "bgIconColor": isVaccine ? const Color(0xFFE8F5E9) : const Color(0xFFFFFBEB),
        "showDot": false,
      });
    }



    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: alerts.length > 5 ? 5 : alerts.length, // Limit to max 5 alerts
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                // Left colorful indicator bar
                Container(
                  width: 6,
                  height: 76,
                  color: alert["indicatorColor"],
                ),
                const SizedBox(width: 12),
                // Icon block
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: alert["bgIconColor"],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(alert["icon"], color: alert["iconColor"], size: 18),
                ),
                const SizedBox(width: 12),
                // Contents
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              alert["title"],
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937)),
                            ),
                            const Spacer(),
                            Text(
                              alert["time"],
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                            const SizedBox(width: 8),
                            if (alert["showDot"] as bool)
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            const SizedBox(width: 12),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Text(
                            alert["desc"],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF4B5563),
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Today's Production Card Builder
  Widget _buildTodayProductionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Production",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _showAddProductionSheet,
                icon: const Icon(Icons.add, color: Color(0xFF22C55E), size: 12),
                label: const Text(
                  "Add",
                  style: TextStyle(
                    color: Color(0xFF22C55E),
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF22C55E), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Milk row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.water_drop, color: Color(0xFF22C55E), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Milk Collected",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Today's total",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                "${((_animals.where((a) => a["type"] == "Cattle").length * 25.0) + _loggedMilk).toStringAsFixed(0)}L",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF3F4F6)),
          
          // Eggs row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.egg_outlined, color: Color(0xFFF57C00), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Eggs Collected",
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "Today's total",
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text(
                "${(_animals.where((a) => a["type"] == "Chickens").length * 5) + _loggedEggs}",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Painter for Spline Chart Drawing
class SplineChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = const Color(0xFFE5E7EB)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final paintText = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const labelsY = [600, 450, 300, 150, 0];
    const labelsX = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    const paddingLeft = 32.0;
    const paddingRight = 10.0;
    const paddingTop = 10.0;
    const paddingBottom = 24.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    // 1. Draw dashed grid lines and Y axis text
    for (int i = 0; i < labelsY.length; i++) {
      final val = labelsY[i];
      final y = paddingTop + (i / (labelsY.length - 1)) * chartHeight;

      // Draw Y label text
      paintText.text = TextSpan(
        text: val.toString(),
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
      );
      paintText.layout();
      paintText.paint(canvas, Offset(paddingLeft - paintText.width - 6, y - paintText.height / 2));

      // Draw dashed line
      if (i < labelsY.length - 1) {
        final path = Path();
        path.moveTo(paddingLeft, y);
        path.lineTo(paddingLeft + chartWidth, y);
        
        // Custom dash painting
        double curX = paddingLeft;
        const dashWidth = 4.0;
        const spaceWidth = 4.0;
        while (curX < paddingLeft + chartWidth) {
          canvas.drawLine(Offset(curX, y), Offset(curX + dashWidth, y), paintGrid);
          curX += dashWidth + spaceWidth;
        }
      } else {
        // Draw solid baseline
        canvas.drawLine(
          Offset(paddingLeft, y),
          Offset(paddingLeft + chartWidth, y),
          Paint()
            ..color = const Color(0xFF9CA3AF)
            ..strokeWidth = 1.2,
        );
      }
    }

    // 2. Draw X axis text
    final stepX = chartWidth / (labelsX.length - 1);
    for (int i = 0; i < labelsX.length; i++) {
      final text = labelsX[i];
      final x = paddingLeft + i * stepX;
      
      paintText.text = TextSpan(
        text: text,
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
      );
      paintText.layout();
      paintText.paint(canvas, Offset(x - paintText.width / 2, size.height - paddingBottom + 6));
    }

    // 3. Define data points
    final milkData = [420.0, 380.0, 450.0, 410.0, 430.0, 480.0, 450.0];
    final eggData = [180.0, 210.0, 195.0, 220.0, 200.0, 240.0, 225.0];

    Offset getPoint(int index, double val) {
      final x = paddingLeft + index * stepX;
      final y = paddingTop + (1.0 - (val / 600.0)) * chartHeight;
      return Offset(x, y);
    }

    // Draw area gradient and line for Milk (Green)
    _drawSpline(canvas, milkData, getPoint, const Color(0xFF00FF66), const Color(0xFFE8F5E9), chartHeight, paddingTop, paddingLeft, chartWidth);

    // Draw area gradient and line for Eggs (Orange)
    _drawSpline(canvas, eggData, getPoint, const Color(0xFFF57C00), const Color(0xFFFFF3E0), chartHeight, paddingTop, paddingLeft, chartWidth);
  }

  void _drawSpline(
    Canvas canvas,
    List<double> data,
    Offset Function(int, double) getPoint,
    Color lineColor,
    Color areaColor,
    double chartHeight,
    double paddingTop,
    double paddingLeft,
    double chartWidth,
  ) {
    if (data.isEmpty) return;

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      points.add(getPoint(i, data[i]));
    }

    // Smooth Bezier path calculation
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

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

    // Draw gradient area under spline
    final areaPath = Path.from(path);
    areaPath.lineTo(points.last.dx, paddingTop + chartHeight);
    areaPath.lineTo(points.first.dx, paddingTop + chartHeight);
    areaPath.close();

    final paintArea = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          areaColor.withOpacity(0.5),
          areaColor.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTRB(paddingLeft, paddingTop, paddingLeft + chartWidth, paddingTop + chartHeight))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, paintArea);

    // Draw the spline stroke line
    final paintLine = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..isAntiAlias = true;

    canvas.drawPath(path, paintLine);

    // Draw dot points on joints
    final paintDotOuter = Paint()..color = Colors.white;
    final paintDotInner = Paint()..color = lineColor;
    for (var pt in points) {
      canvas.drawCircle(pt, 4, paintDotOuter);
      canvas.drawCircle(pt, 2, paintDotInner);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
