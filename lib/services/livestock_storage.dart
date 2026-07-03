import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';

class LivestockStorageService {
  static String get _animalsKey => "livestock_animals_${AppState().currentUserId ?? ''}";
  static String get _recordsKey => "livestock_health_records_${AppState().currentUserId ?? ''}";
  static String get _alertsKey => "livestock_alerts_${AppState().currentUserId ?? ''}";

  // Initialize and load seed data if empty
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!prefs.containsKey(_animalsKey)) {
      await prefs.setString(_animalsKey, "[]");
    }
    
    if (!prefs.containsKey(_recordsKey)) {
      await prefs.setString(_recordsKey, "[]");
    }

    if (!prefs.containsKey(_alertsKey)) {
      await prefs.setString(_alertsKey, "[]");
    }
  }

  // Get all animals
  static Future<List<Map<String, dynamic>>> getAnimals() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_animalsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Save animals
  static Future<void> saveAnimals(List<Map<String, dynamic>> animals) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_animalsKey, jsonEncode(animals));
  }

  // Add an animal
  static Future<void> addAnimal(Map<String, dynamic> animal) async {
    final animals = await getAnimals();
    // Auto increment id
    final id = (animals.isEmpty) 
        ? "1" 
        : (animals.map((a) => int.tryParse(a["id"] ?? "0") ?? 0).reduce((curr, next) => curr > next ? curr : next) + 1).toString();
    
    animal["id"] = id;
    animals.add(animal);
    await saveAnimals(animals);
  }

  // Get all health records
  static Future<List<Map<String, dynamic>>> getHealthRecords() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_recordsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Save health records
  static Future<void> saveHealthRecords(List<Map<String, dynamic>> records) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // Add a health record
  static Future<void> addHealthRecord(Map<String, dynamic> record) async {
    final records = await getHealthRecords();
    final id = "r_${DateTime.now().millisecondsSinceEpoch}";
    record["id"] = id;
    records.insert(0, record); // insert at beginning of list
    await saveHealthRecords(records);
  }

  // Update an animal
  static Future<void> updateAnimal(Map<String, dynamic> updatedAnimal) async {
    final animals = await getAnimals();
    final index = animals.indexWhere((a) => a["id"] == updatedAnimal["id"]);
    if (index != -1) {
      animals[index] = updatedAnimal;
      await saveAnimals(animals);

      // Cascade update the associated health records to sync name and type
      final records = await getHealthRecords();
      bool recordChanged = false;
      for (var record in records) {
        if (record["animalId"] == updatedAnimal["id"]) {
          record["animalName"] = updatedAnimal["name"];
          record["animalType"] = updatedAnimal["type"];
          recordChanged = true;
        }
      }
      if (recordChanged) {
        await saveHealthRecords(records);
      }
    }
  }

  // Delete an animal (and cascade delete health records)
  static Future<void> deleteAnimal(String id) async {
    final animals = await getAnimals();
    animals.removeWhere((a) => a["id"] == id);
    await saveAnimals(animals);

    // Cascade delete associated health records
    final records = await getHealthRecords();
    records.removeWhere((r) => r["animalId"] == id);
    await saveHealthRecords(records);
  }

  // Update a health record
  static Future<void> updateHealthRecord(Map<String, dynamic> updatedRecord) async {
    final records = await getHealthRecords();
    final index = records.indexWhere((r) => r["id"] == updatedRecord["id"]);
    if (index != -1) {
      records[index] = updatedRecord;
      await saveHealthRecords(records);
    }
  }

  // Delete a health record
  static Future<void> deleteHealthRecord(String id) async {
    final records = await getHealthRecords();
    records.removeWhere((r) => r["id"] == id);
    await saveHealthRecords(records);
  }

  // Get all alerts
  static Future<List<Map<String, dynamic>>> getAlerts() async {
    await init();
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_alertsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Save alerts
  static Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts));
  }

  // Add an alert manually
  static Future<void> addAlert(Map<String, dynamic> alert) async {
    final alerts = await getAlerts();
    alert["id"] = "alert_${DateTime.now().millisecondsSinceEpoch}";
    alerts.insert(0, alert);
    await saveAlerts(alerts);
  }

  // Mark an alert as read
  static Future<void> markAlertRead(String id) async {
    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a["id"] == id);
    if (index != -1) {
      alerts[index]["isRead"] = true;
      await saveAlerts(alerts);
    }
  }

  // Mark all alerts as read
  static Future<void> markAllAlertsRead() async {
    final alerts = await getAlerts();
    for (var a in alerts) {
      a["isRead"] = true;
    }
    await saveAlerts(alerts);
  }

  // Clear all read alerts
  static Future<void> clearReadAlerts() async {
    final alerts = await getAlerts();
    alerts.removeWhere((a) => a["isRead"] == true);
    await saveAlerts(alerts);
  }

  // Delete an alert by ID
  static Future<void> deleteAlert(String id) async {
    final alerts = await getAlerts();
    alerts.removeWhere((a) => a["id"] == id);
    await saveAlerts(alerts);
  }

  // Check and generate alerts based on scheduled health records (1 day before)
  static Future<void> checkAndGenerateAlerts(void Function(Map<String, dynamic>) onAlertTriggered) async {
    final records = await getHealthRecords();
    final alerts = await getAlerts();
    bool alertsUpdated = false;

    // Parse today's date
    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

    for (var record in records) {
      if (record["status"] == "scheduled" && record["dueDate"] != null && record["dueDate"].toString().isNotEmpty) {
        try {
          final dueDate = DateTime.parse(record["dueDate"]);
          // Calculate 1 day before
          final triggerDate = dueDate.subtract(const Duration(days: 1));
          final triggerDateStr = "${triggerDate.year}-${triggerDate.month.toString().padLeft(2, '0')}-${triggerDate.day.toString().padLeft(2, '0')}";

          // Check if trigger date is today or in the past (since we want to alert 1 day before or if we missed it)
          if (todayStr == triggerDateStr || today.isAfter(triggerDate)) {
            final recordId = record["id"];
            final alreadyAlerted = alerts.any((a) => a["recordId"] == recordId);

            if (!alreadyAlerted) {
              final newAlert = {
                "id": "alert_${DateTime.now().millisecondsSinceEpoch}_${recordId}",
                "recordId": recordId,
                "title": "${record["type"]} Due Tomorrow",
                "message": "${record["animalName"]} (${record["animalType"]}) needs their ${record["title"]}.",
                "animalName": record["animalName"],
                "type": record["type"],
                "priority": "high",
                "isRead": false,
                "timestamp": DateTime.now().toIso8601String(),
              };

              alerts.insert(0, newAlert);
              alertsUpdated = true;
              
              // Trigger notification callback
              onAlertTriggered(newAlert);
            }
          }
        } catch (e) {
          // ignore parsing error
        }
      }
    }

    if (alertsUpdated) {
      await saveAlerts(alerts);
    }
  }
}
