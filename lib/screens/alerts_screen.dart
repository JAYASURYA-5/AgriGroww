import 'package:flutter/material.dart';
import '../services/livestock_storage.dart';

class AlertsScreen extends StatefulWidget {
  final bool hideBackButton;
  const AlertsScreen({
    Key? key,
    this.hideBackButton = false,
  }) : super(key: key);

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<Map<String, dynamic>> _alerts = [];
  bool _isLoading = true;
  String _activeTab = "All";

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
    });
    final alerts = await LivestockStorageService.getAlerts();
    setState(() {
      _alerts = alerts;
      _isLoading = false;
    });
  }

  // Formatting timestamp to human readable string
  String _formatTimestamp(String timestampStr) {
    try {
      final timestamp = DateTime.parse(timestampStr);
      final difference = DateTime.now().difference(timestamp);
      
      if (difference.inMinutes < 60) {
        final m = difference.inMinutes;
        return m <= 1 ? "Just now" : "$m minutes ago";
      } else if (difference.inHours < 24) {
        final h = difference.inHours;
        return h == 1 ? "1 hour ago" : "$h hours ago";
      } else {
        final d = difference.inDays;
        return d == 1 ? "1 day ago" : "$d days ago";
      }
    } catch (e) {
      return "2 hours ago"; // Default fallback
    }
  }

  // Get leading icon and color based on alert type
  IconData _getLeadingIcon(String type) {
    switch (type.toLowerCase()) {
      case "vaccination":
      case "vaccines":
        return Icons.vaccines_outlined;
      case "health":
        return Icons.favorite_border;
      case "feeding":
      case "feed":
        return Icons.restaurant_outlined;
      case "environment":
        return Icons.thermostat_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _getLeadingIconColor(String type) {
    switch (type.toLowerCase()) {
      case "vaccination":
      case "vaccines":
        return const Color(0xFFF2A33A); // Orange
      case "health":
        return const Color(0xFFEF4444); // Red
      case "feeding":
      case "feed":
        return const Color(0xFF10B981); // Green
      case "environment":
        return const Color(0xFF3B82F6); // Blue
      default:
        return Colors.grey;
    }
  }

  Future<void> _markAllRead() async {
    await LivestockStorageService.markAllAlertsRead();
    await _loadAlerts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All alerts marked as read!"),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  Future<void> _clearRead() async {
    await LivestockStorageService.clearReadAlerts();
    await _loadAlerts();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cleared all read alerts!"),
          backgroundColor: Color(0xFF22C55E),
        ),
      );
    }
  }

  Future<void> _markSingleRead(String id) async {
    await LivestockStorageService.markAlertRead(id);
    await _loadAlerts();
  }

  Future<void> _deleteAlert(String id) async {
    await LivestockStorageService.deleteAlert(id);
    await _loadAlerts();
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _alerts.where((a) => a["isRead"] == false).length;
    final highPriorityCount = _alerts
        .where((a) => a["isRead"] == false && a["priority"] == "high")
        .length;

    // Filter alerts by tab
    List<Map<String, dynamic>> filteredAlerts = [];
    if (_activeTab == "All") {
      filteredAlerts = _alerts;
    } else if (_activeTab.startsWith("Unread")) {
      filteredAlerts = _alerts.where((a) => a["isRead"] == false).toList();
    } else {
      filteredAlerts = _alerts
          .where((a) => a["type"].toString().toLowerCase() == _activeTab.toLowerCase())
          .toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          'Alerts & Notifications',
          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1F2937)),
        ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Responsive Header block: Icon, Title, Actions
                        _buildHeaderSection(unreadCount),
                        const SizedBox(height: 24),

                        // High Priority warning card (Only visible if there are unread high priority items)
                        if (highPriorityCount > 0) ...[
                          _buildHighPriorityWarningCard(highPriorityCount),
                          const SizedBox(height: 20),
                        ],

                        // Custom Tabs track layout
                        _buildCategoryTabsTrack(unreadCount),
                        const SizedBox(height: 24),

                        // List of Alerts
                        if (filteredAlerts.isEmpty)
                          _buildEmptyAlertsState()
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredAlerts.length,
                            itemBuilder: (context, index) {
                              final alert = filteredAlerts[index];
                              return _buildAlertCard(alert);
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeaderSection(int unreadCount) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 500;
        final headerLayout = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF8F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_outlined,
                color: Color(0xFF22C55E),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Alerts &',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDC2626), // Solid red badge
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "$unreadCount unread",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      fontFamily: 'serif',
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Stay updated on critical farm events and reminders',
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
        );

        final actionButtons = Row(
          mainAxisAlignment: isWide ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: unreadCount > 0 ? _markAllRead : null,
              icon: const Icon(Icons.check, size: 16),
              label: const Text("Mark All Read"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              onPressed: _alerts.any((a) => a["isRead"] == true) ? _clearRead : null,
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text("Clear Read"),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E), width: 1.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: headerLayout),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              headerLayout,
              const SizedBox(height: 16),
              actionButtons,
            ],
          );
        }
      },
    );
  }

  Widget _buildHighPriorityWarningCard(int count) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1), // Light red background
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.2),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count High Priority Alerts",
                  style: const TextStyle(
                    color: Color(0xFF991B1B),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Immediate attention required",
                  style: TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabsTrack(int unreadCount) {
    final tabs = [
      "All",
      "Unread ($unreadCount)",
      "Vaccination",
      "Health",
      "Feeding",
      "Environment",
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5), // Pill track background
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: tabs.map((tab) {
            final isSelected = tab == _activeTab || 
                (tab.startsWith("Unread") && _activeTab.startsWith("Unread"));
            
            return GestureDetector(
              onTap: () {
                setState(() {
                  _activeTab = tab;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  tab,
                  style: TextStyle(
                    color: isSelected ? Colors.black87 : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isRead = alert["isRead"] ?? false;
    final type = alert["type"] ?? "Notification";
    final priority = alert["priority"] ?? "medium";
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isRead ? Colors.white : const Color(0xFFF0FDF4), // Light green tint for unread
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Solid green left indicator bar
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 5,
                color: const Color(0xFF22C55E), // Solid green left bar indicator
              ),
            ),
            
            // Content Layout
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Leading round icon container
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F3F5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getLeadingIcon(type),
                      color: _getLeadingIconColor(type),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Texts
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                alert["title"] ?? "",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ),
                            if (priority == "high")
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "high",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert["message"] ?? "",
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.grey[700],
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Tags & Time
                        Row(
                          children: [
                            if (alert["animalName"] != null && alert["animalName"].toString().isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  alert["animalName"],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            const Icon(Icons.access_time_outlined, color: Colors.grey, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              _formatTimestamp(alert["timestamp"] ?? ""),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            
                            // Interactive Actions
                            if (!isRead)
                              TextButton.icon(
                                onPressed: () => _markSingleRead(alert["id"]),
                                icon: const Icon(Icons.check_circle_outline, size: 15),
                                label: const Text("Mark Read"),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF374151),
                                  padding: EdgeInsets.zero,
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            const SizedBox(width: 14),
                            IconButton(
                              onPressed: () => _deleteAlert(alert["id"]),
                              icon: const Icon(Icons.delete_outline, color: Colors.grey),
                              iconSize: 18,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              splashRadius: 16,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyAlertsState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.notifications_off_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            "No Alerts Found",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 6),
          Text(
            "Everything is quiet. No notifications in this category.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13.5, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
