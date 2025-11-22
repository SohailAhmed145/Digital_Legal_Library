import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DataPersistenceService {
  static const String _profileBoxName = 'user_profile';
  static const String _settingsBoxName = 'user_settings';
  static const String _lastLoginEmailKey = 'last_login_email';
  
  static DataPersistenceService? _instance;
  static SharedPreferences? _preferences;
  static Box? _profileBox;
  static Box? _settingsBox;
  
  DataPersistenceService._internal();
  
  static Future<DataPersistenceService> getInstance() async {
    try {
      _instance ??= DataPersistenceService._internal();
      _preferences ??= await SharedPreferences.getInstance();
      
      // Initialize Hive boxes
      if (!Hive.isBoxOpen(_profileBoxName)) {
        _profileBox = await Hive.openBox(_profileBoxName);
      } else {
        _profileBox = Hive.box(_profileBoxName);
      }
      
      if (!Hive.isBoxOpen(_settingsBoxName)) {
        _settingsBox = await Hive.openBox(_settingsBoxName);
      } else {
        _settingsBox = Hive.box(_settingsBoxName);
      }
      
      return _instance!;
    } catch (e) {
      print('Error initializing DataPersistenceService: $e');
      rethrow;
    }
  }
  
  // Profile Data Methods
  Future<bool> saveProfileData({
    required String fullName,
    required String email,
    String? profileImagePath,
  }) async {
    try {
      await _profileBox!.put('fullName', fullName);
      await _profileBox!.put('email', email);
      if (profileImagePath != null) {
        await _profileBox!.put('profileImagePath', profileImagePath);
      }
      
      // Also save to Firebase Firestore
      await _saveProfileToFirebase(fullName, email, profileImagePath);
      
      return true;
    } catch (e) {
      print('Error saving profile data: $e');
      return false;
    }
  }
  
  Map<String, dynamic>? getProfileData() {
    try {
      final fullName = _profileBox!.get('fullName');
      final email = _profileBox!.get('email');
      final profileImagePath = _profileBox!.get('profileImagePath');
      
      if (fullName != null && email != null) {
        return {
          'fullName': fullName,
          'email': email,
          'profileImagePath': profileImagePath,
        };
      }
      return null;
    } catch (e) {
      print('Error getting profile data: $e');
      return null;
    }
  }
  
  // Settings Methods
  Future<bool> saveSettings({
    required bool isDarkMode,
    required String language,
  }) async {
    try {
      if (_settingsBox != null) {
        await _settingsBox!.put('isDarkMode', isDarkMode);
        await _settingsBox!.put('language', language);
        print('Settings saved: isDarkMode=$isDarkMode, language=$language');
        return true;
      } else {
        print('Settings box not initialized');
        return false;
      }
    } catch (e) {
      print('Error saving settings: $e');
      return false;
    }
  }
  
  Map<String, dynamic>? getSettings() {
    try {
      final isDarkMode = _settingsBox!.get('isDarkMode', defaultValue: false);
      final language = _settingsBox!.get('language', defaultValue: 'english');
      
      return {
        'isDarkMode': isDarkMode,
        'language': language,
      };
    } catch (e) {
      print('Error getting settings: $e');
      return null;
    }
  }
  
  // Profile Image Methods
  Future<String?> saveProfileImage(File? imageFile, {Uint8List? imageData}) async {
    try {
      if (kIsWeb) {
        // For web, save image data directly to Hive as base64
        if (imageData != null) {
          final base64String = base64Encode(imageData);
          await _profileBox!.put('profileImageData', base64String);
          final imageId = 'web_image_${DateTime.now().millisecondsSinceEpoch}';
          await _profileBox!.put('profileImagePath', imageId);
          print('Profile image saved to web storage with ID: $imageId');
          return imageId;
        }
        return null;
      } else {
        // For mobile platforms, save to file system
        if (imageFile != null) {
          final appDir = await getApplicationDocumentsDirectory();
          final profileDir = Directory('${appDir.path}/profile_images');
          
          if (!await profileDir.exists()) {
            await profileDir.create(recursive: true);
          }
          
          final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedPath = '${profileDir.path}/$fileName';
          
          // Copy the image to app directory
          await imageFile.copy(savedPath);
          
          // Save the path to persistent storage
          await _profileBox!.put('profileImagePath', savedPath);
          
          return savedPath;
        }
        return null;
      }
    } catch (e) {
      print('Error saving profile image: $e');
      return null;
    }
  }
  
  // Get profile image data for web
  Uint8List? getProfileImageData() {
    try {
      if (kIsWeb) {
        final base64String = _profileBox!.get('profileImageData');
        if (base64String != null) {
          return base64Decode(base64String);
        }
      }
      return null;
    } catch (e) {
      print('Error getting profile image data: $e');
      return null;
    }
  }
  
  String? getProfileImagePath() {
    try {
      return _profileBox!.get('profileImagePath');
    } catch (e) {
      print('Error getting profile image path: $e');
      return null;
    }
  }
  
  Future<bool> deleteProfileImage() async {
    try {
      final imagePath = _profileBox!.get('profileImagePath');
      if (imagePath != null) {
        final imageFile = File(imagePath);
        if (await imageFile.exists()) {
          await imageFile.delete();
        }
        await _profileBox!.delete('profileImagePath');
      }
      return true;
    } catch (e) {
      print('Error deleting profile image: $e');
      return false;
    }
  }
  
  // Last Login Email Methods
  Future<bool> setLastLoginEmail(String email) async {
    try {
      return await _preferences!.setString(_lastLoginEmailKey, email);
    } catch (e) {
      print('Error saving last login email: $e');
      return false;
    }
  }
  
  String? getLastLoginEmail() {
    try {
      return _preferences!.getString(_lastLoginEmailKey);
    } catch (e) {
      print('Error getting last login email: $e');
      return null;
    }
  }
  
  Future<bool> clearLastLoginEmail() async {
    try {
      return await _preferences!.remove(_lastLoginEmailKey);
    } catch (e) {
      print('Error clearing last login email: $e');
      return false;
    }
  }
  
  // Clear all data (for logout)
  Future<bool> clearAllData() async {
    try {
      await _profileBox!.clear();
      await _settingsBox!.clear();
      await _preferences!.clear();
      return true;
    } catch (e) {
      print('Error clearing all data: $e');
      return false;
    }
  }
  
  // Clear Firebase profile data for current user
  Future<void> clearFirebaseProfileData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No authenticated user to clear Firebase profile data');
        return;
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .delete();
      
      print('Firebase profile data cleared successfully for user: ${user.uid}');
    } catch (e) {
      print('Error clearing Firebase profile data: $e');
    }
  }
  
  // Clear all data including Firebase profile
  Future<bool> clearAllDataIncludingFirebase() async {
    try {
      await clearAllData();
      await clearFirebaseProfileData();
      return true;
    } catch (e) {
      print('Error clearing all data including Firebase: $e');
      return false;
    }
  }
  
  // Dispose
  Future<void> dispose() async {
    await _profileBox?.close();
    await _settingsBox?.close();
  }

  // Firebase Methods
  Future<void> _saveProfileToFirebase(String fullName, String email, String? profileImagePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'fullName': fullName,
        'email': email,
        'profileImagePath': profileImagePath,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Profile saved to Firebase successfully');
    } catch (e) {
      print('Error saving profile to Firebase: $e');
    }
  }

  // Save documents to Firebase
  Future<void> saveDocumentToFirebase({
    required String documentId,
    required String title,
    required String content,
    required String category,
    required String type,
    String? filePath,
    Uint8List? fileData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final documentData = {
        'documentId': documentId,
        'title': title,
        'content': content,
        'category': category,
        'type': type,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // If there's a file, upload it to Firebase Storage
      if (filePath != null || fileData != null) {
        String downloadURL = '';
        
        if (kIsWeb && fileData != null) {
          // Upload file data for web
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('documents')
              .child('${user.uid}_${documentId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
          
          final uploadTask = storageRef.putData(fileData);
          final snapshot = await uploadTask;
          downloadURL = await snapshot.ref.getDownloadURL();
        } else if (filePath != null) {
          // Upload file for mobile
          final file = File(filePath);
          if (await file.exists()) {
            final storageRef = FirebaseStorage.instance
                .ref()
                .child('documents')
                .child('${user.uid}_${documentId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
            
            final uploadTask = storageRef.putFile(file);
            final snapshot = await uploadTask;
            downloadURL = await snapshot.ref.getDownloadURL();
          }
        }
        
        documentData['fileURL'] = downloadURL;
      }

      await FirebaseFirestore.instance
          .collection('documents')
          .doc(documentId)
          .set(documentData, SetOptions(merge: true));
      
      print('Document saved to Firebase successfully');
    } catch (e) {
      print('Error saving document to Firebase: $e');
    }
  }

  // Load documents from Firebase
  Future<List<Map<String, dynamic>>> loadDocumentsFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final querySnapshot = await FirebaseFirestore.instance
          .collection('documents')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'documentId': data['documentId'] ?? doc.id,
          'title': data['title'] ?? '',
          'content': data['content'] ?? '',
          'category': data['category'] ?? '',
          'type': data['type'] ?? '',
          'fileURL': data['fileURL'] ?? '',
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'updatedAt': data['updatedAt']?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error loading documents from Firebase: $e');
      return [];
    }
  }

  // Save cases to Firebase
  Future<void> saveCaseToFirebase({
    required String caseId,
    required String title,
    required String description,
    required String status,
    required String type,
    String? clientName,
    String? assignedTo,
    DateTime? dueDate,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('cases')
          .doc(caseId)
          .set({
        'caseId': caseId,
        'title': title,
        'description': description,
        'status': status,
        'type': type,
        'clientName': clientName,
        'assignedTo': assignedTo,
        'dueDate': dueDate != null ? Timestamp.fromDate(dueDate) : null,
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('Case saved to Firebase successfully');
    } catch (e) {
      print('Error saving case to Firebase: $e');
    }
  }

  // Load cases from Firebase
  Future<List<Map<String, dynamic>>> loadCasesFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final querySnapshot = await FirebaseFirestore.instance
          .collection('cases')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'caseId': data['caseId'] ?? doc.id,
          'title': data['title'] ?? '',
          'description': data['description'] ?? '',
          'status': data['status'] ?? '',
          'type': data['type'] ?? '',
          'clientName': data['clientName'] ?? '',
          'assignedTo': data['assignedTo'] ?? '',
          'dueDate': data['dueDate']?.toDate(),
          'createdAt': data['createdAt']?.toDate() ?? DateTime.now(),
          'updatedAt': data['updatedAt']?.toDate() ?? DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error loading cases from Firebase: $e');
      return [];
    }
  }
}
