import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_state.dart';
import 'firebase_service.dart';

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
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        final list = await FirebaseService().getAnimals(uid);
        if (list.isNotEmpty) return list;
      }
    }

    await init();
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_animalsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Save animals
  static Future<void> saveAnimals(List<Map<String, dynamic>> animals) async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        for (var animal in animals) {
          final id = animal["id"] ?? DateTime.now().millisecondsSinceEpoch.toString();
          animal["id"] = id;
          await FirebaseService().saveAnimal(uid, id, animal);
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_animalsKey, jsonEncode(animals));
  }

  // Add an animal
  static Future<void> addAnimal(Map<String, dynamic> animal) async {
    final id = "a_${DateTime.now().millisecondsSinceEpoch}";
    animal["id"] = id;

    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        await FirebaseService().saveAnimal(uid, id, animal);
      }
    }

    final animals = await getAnimals();
    animals.add(animal);
    
    // Save to SharedPreferences local copy
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_animalsKey, jsonEncode(animals));
  }

  // Get all health records
  static Future<List<Map<String, dynamic>>> getHealthRecords() async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        final list = await FirebaseService().getHealthRecords(uid);
        if (list.isNotEmpty) return list;
      }
    }

    await init();
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_recordsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Save health records
  static Future<void> saveHealthRecords(List<Map<String, dynamic>> records) async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        for (var record in records) {
          final id = record["id"] ?? "r_${DateTime.now().millisecondsSinceEpoch}";
          record["id"] = id;
          await FirebaseService().saveHealthRecord(uid, id, record);
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // Add a health record
  static Future<void> addHealthRecord(Map<String, dynamic> record) async {
    final id = "r_${DateTime.now().millisecondsSinceEpoch}";
    record["id"] = id;

    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        await FirebaseService().saveHealthRecord(uid, id, record);
      }
    }

    final records = await getHealthRecords();
    records.insert(0, record); // insert at beginning of list
    
    // Save local copy
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // Update an animal
  static Future<void> updateAnimal(Map<String, dynamic> updatedAnimal) async {
    final id = updatedAnimal["id"];
    if (id == null) return;

    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        await FirebaseService().saveAnimal(uid, id, updatedAnimal);

        // Cascade update the associated health records to sync name and type
        final records = await FirebaseService().getHealthRecords(uid);
        for (var record in records) {
          if (record["animalId"] == id) {
            record["animalName"] = updatedAnimal["name"];
            record["animalType"] = updatedAnimal["type"];
            await FirebaseService().saveHealthRecord(uid, record["id"], record);
          }
        }
      }
    }

    // Local update
    final animals = await getAnimals();
    final index = animals.indexWhere((a) => a["id"] == id);
    if (index != -1) {
      animals[index] = updatedAnimal;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_animalsKey, jsonEncode(animals));

      // Cascade local update
      final records = await getHealthRecords();
      bool recordChanged = false;
      for (var record in records) {
        if (record["animalId"] == id) {
          record["animalName"] = updatedAnimal["name"];
          record["animalType"] = updatedAnimal["type"];
          recordChanged = true;
        }
      }
      if (recordChanged) {
        await prefs.setString(_recordsKey, jsonEncode(records));
      }
    }
  }

  // Delete an animal (and cascade delete health records)
  static Future<void> deleteAnimal(String id) async {
    if (FirebaseService().isAvailable) {
      await FirebaseService().deleteAnimal(id);
    }

    // Local delete
    final animals = await getAnimals();
    animals.removeWhere((a) => a["id"] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_animalsKey, jsonEncode(animals));

    // Cascade delete associated health records locally
    final records = await getHealthRecords();
    records.removeWhere((r) => r["animalId"] == id);
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // Update a health record
  static Future<void> updateHealthRecord(Map<String, dynamic> updatedRecord) async {
    final id = updatedRecord["id"];
    if (id == null) return;

    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        await FirebaseService().saveHealthRecord(uid, id, updatedRecord);
      }
    }

    // Local update
    final records = await getHealthRecords();
    final index = records.indexWhere((r) => r["id"] == id);
    if (index != -1) {
      records[index] = updatedRecord;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_recordsKey, jsonEncode(records));
    }
  }

  // Delete a health record
  static Future<void> deleteHealthRecord(String id) async {
    if (FirebaseService().isAvailable) {
      await FirebaseService().deleteHealthRecord(id);
    }

    // Local delete
    final records = await getHealthRecords();
    records.removeWhere((r) => r["id"] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_recordsKey, jsonEncode(records));
  }

  // Get all alerts
  static Future<List<Map<String, dynamic>>> getAlerts() async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        final list = await FirebaseService().getAlerts(uid);
        if (list.isNotEmpty) return list;
      }
    }

    await init();
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_alertsKey);
    if (jsonStr == null) return [];
    
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  // Save alerts
  static Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        for (var alert in alerts) {
          final id = alert["id"] ?? "alert_${DateTime.now().millisecondsSinceEpoch}";
          alert["id"] = id;
          await FirebaseService().saveAlert(uid, id, alert);
        }
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts));
  }

  // Add an alert manually
  static Future<void> addAlert(Map<String, dynamic> alert) async {
    final id = "alert_${DateTime.now().millisecondsSinceEpoch}";
    alert["id"] = id;

    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        await FirebaseService().saveAlert(uid, id, alert);
      }
    }

    final alerts = await getAlerts();
    alerts.insert(0, alert);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts));
  }

  // Mark an alert as read
  static Future<void> markAlertRead(String id) async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        final alerts = await FirebaseService().getAlerts(uid);
        final index = alerts.indexWhere((a) => a["id"] == id);
        if (index != -1) {
          alerts[index]["isRead"] = true;
          await FirebaseService().saveAlert(uid, id, alerts[index]);
        }
      }
    }

    final alerts = await getAlerts();
    final index = alerts.indexWhere((a) => a["id"] == id);
    if (index != -1) {
      alerts[index]["isRead"] = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertsKey, jsonEncode(alerts));
    }
  }

  // Mark all alerts as read
  static Future<void> markAllAlertsRead() async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        final alerts = await FirebaseService().getAlerts(uid);
        for (var a in alerts) {
          a["isRead"] = true;
          await FirebaseService().saveAlert(uid, a["id"], a);
        }
      }
    }

    final alerts = await getAlerts();
    for (var a in alerts) {
      a["isRead"] = true;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts));
  }

  // Clear all read alerts
  static Future<void> clearReadAlerts() async {
    if (FirebaseService().isAvailable) {
      final uid = AppState().currentUserId;
      if (uid != null) {
        final alerts = await FirebaseService().getAlerts(uid);
        for (var a in alerts) {
          if (a["isRead"] == true) {
            await FirebaseService().deleteAlert(a["id"]);
          }
        }
      }
    }

    final alerts = await getAlerts();
    alerts.removeWhere((a) => a["isRead"] == true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts));
  }

  // Delete an alert by ID
  static Future<void> deleteAlert(String id) async {
    if (FirebaseService().isAvailable) {
      await FirebaseService().deleteAlert(id);
    }

    final alerts = await getAlerts();
    alerts.removeWhere((a) => a["id"] == id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_alertsKey, jsonEncode(alerts));
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
              final newId = "alert_${DateTime.now().millisecondsSinceEpoch}_$recordId";
              final newAlert = {
                "id": newId,
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
              
              if (FirebaseService().isAvailable) {
                final uid = AppState().currentUserId;
                if (uid != null) {
                  await FirebaseService().saveAlert(uid, newId, newAlert);
                }
              }

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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_alertsKey, jsonEncode(alerts));
    }
  }
}
