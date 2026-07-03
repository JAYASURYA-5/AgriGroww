// File: lib/services/firebase_service.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  /// Check if Firebase has been initialized successfully.
  bool get isAvailable {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseFirestore? get firestore {
    if (!isAvailable) return null;
    return FirebaseFirestore.instance;
  }

  FirebaseStorage? get storage {
    if (!isAvailable) return null;
    return FirebaseStorage.instance;
  }

  // ==========================================
  // FIREBASE STORAGE UTILITIES
  // ==========================================

  /// Uploads an image to Firebase Storage and returns its public Download URL.
  /// Falls back to the local file path string if Firebase is unavailable.
  Future<String?> uploadImage(File file, String folderPath) async {
    if (!isAvailable || storage == null) {
      debugPrint("Firebase Storage not available. Using local file path.");
      return file.path;
    }

    try {
      final fileName = "${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}";
      final ref = storage!.ref().child(folderPath).child(fileName);
      final uploadTask = await ref.putFile(file);
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint("Error uploading image to storage: $e");
      return file.path; // Return local path as fail-safe
    }
  }

  // ==========================================
  // FIRESTORE USER COLLECTIONS
  // ==========================================

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    if (firestore == null) return;
    try {
      await firestore!.collection('users').doc(uid).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving user profile: $e");
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    if (firestore == null) return null;
    try {
      final doc = await firestore!.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint("Error getting user profile: $e");
      return null;
    }
  }

  // ==========================================
  // FIRESTORE NOTES OPERATIONS
  // ==========================================

  Future<List<Map<String, dynamic>>> getNotes(String uid) async {
    if (firestore == null) return [];
    try {
      final querySnapshot = await firestore!
          .collection('notes')
          .where('userId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error getting notes from Firestore: $e");
      return [];
    }
  }

  Future<void> saveNote(String uid, String noteId, Map<String, dynamic> noteData) async {
    if (firestore == null) return;
    try {
      noteData['userId'] = uid;
      await firestore!.collection('notes').doc(noteId).set(noteData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving note to Firestore: $e");
    }
  }

  Future<void> deleteNote(String noteId) async {
    if (firestore == null) return;
    try {
      await firestore!.collection('notes').doc(noteId).delete();
    } catch (e) {
      debugPrint("Error deleting note: $e");
    }
  }

  // ==========================================
  // FIRESTORE LIVESTOCK (ANIMALS) OPERATIONS
  // ==========================================

  Future<List<Map<String, dynamic>>> getAnimals(String uid) async {
    if (firestore == null) return [];
    try {
      final querySnapshot = await firestore!
          .collection('animals')
          .where('userId', isEqualTo: uid)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error getting animals: $e");
      return [];
    }
  }

  Future<void> saveAnimal(String uid, String animalId, Map<String, dynamic> animalData) async {
    if (firestore == null) return;
    try {
      animalData['userId'] = uid;
      await firestore!.collection('animals').doc(animalId).set(animalData, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving animal: $e");
    }
  }

  Future<void> deleteAnimal(String animalId) async {
    if (firestore == null) return;
    try {
      await firestore!.collection('animals').doc(animalId).delete();
      
      // Cascade delete health records of this animal
      final recordsSnapshot = await firestore!
          .collection('health_records')
          .where('animalId', isEqualTo: animalId)
          .get();
      
      final batch = firestore!.batch();
      for (var doc in recordsSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint("Error deleting animal: $e");
    }
  }

  // ==========================================
  // FIRESTORE HEALTH RECORDS
  // ==========================================

  Future<List<Map<String, dynamic>>> getHealthRecords(String uid) async {
    if (firestore == null) return [];
    try {
      final querySnapshot = await firestore!
          .collection('health_records')
          .where('userId', isEqualTo: uid)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error getting health records: $e");
      return [];
    }
  }

  Future<void> saveHealthRecord(String uid, String recordId, Map<String, dynamic> data) async {
    if (firestore == null) return;
    try {
      data['userId'] = uid;
      await firestore!.collection('health_records').doc(recordId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving health record: $e");
    }
  }

  Future<void> deleteHealthRecord(String recordId) async {
    if (firestore == null) return;
    try {
      await firestore!.collection('health_records').doc(recordId).delete();
    } catch (e) {
      debugPrint("Error deleting health record: $e");
    }
  }

  // ==========================================
  // FIRESTORE ALERTS
  // ==========================================

  Future<List<Map<String, dynamic>>> getAlerts(String uid) async {
    if (firestore == null) return [];
    try {
      final querySnapshot = await firestore!
          .collection('alerts')
          .where('userId', isEqualTo: uid)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error getting alerts: $e");
      return [];
    }
  }

  Future<void> saveAlert(String uid, String alertId, Map<String, dynamic> data) async {
    if (firestore == null) return;
    try {
      data['userId'] = uid;
      await firestore!.collection('alerts').doc(alertId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving alert: $e");
    }
  }

  Future<void> deleteAlert(String alertId) async {
    if (firestore == null) return;
    try {
      await firestore!.collection('alerts').doc(alertId).delete();
    } catch (e) {
      debugPrint("Error deleting alert: $e");
    }
  }

  // ==========================================
  // FIRESTORE FINANCE TRANSACTIONS
  // ==========================================

  Future<List<Map<String, dynamic>>> getTransactions(String uid) async {
    if (firestore == null) return [];
    try {
      final querySnapshot = await firestore!
          .collection('finance_transactions')
          .where('userId', isEqualTo: uid)
          .get();
      return querySnapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint("Error getting finance transactions: $e");
      return [];
    }
  }

  Future<void> saveTransaction(String uid, String transactionId, Map<String, dynamic> data) async {
    if (firestore == null) return;
    try {
      data['userId'] = uid;
      await firestore!.collection('finance_transactions').doc(transactionId).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving finance transaction: $e");
    }
  }

  Future<void> deleteTransaction(String transactionId) async {
    if (firestore == null) return;
    try {
      await firestore!.collection('finance_transactions').doc(transactionId).delete();
    } catch (e) {
      debugPrint("Error deleting finance transaction: $e");
    }
  }
}
