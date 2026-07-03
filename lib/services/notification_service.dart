import 'package:flutter/material.dart';

class AppNotificationService {
  static final ValueNotifier<Map<String, dynamic>?> activeNotification = ValueNotifier<Map<String, dynamic>?>(null);

  static void triggerNotification(Map<String, dynamic> alert) {
    activeNotification.value = alert;
  }

  static void clearNotification() {
    activeNotification.value = null;
  }
}
