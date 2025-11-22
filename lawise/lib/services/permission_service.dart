import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionData {
  final Permission permission;
  final String title;
  final String description;
  final String reason;
  final IconData icon;
  final bool isRequired;
  final bool isGranted;

  PermissionData({
    required this.permission,
    required this.title,
    required this.description,
    required this.reason,
    required this.icon,
    required this.isRequired,
    required this.isGranted,
  });

  PermissionData copyWith({
    Permission? permission,
    String? title,
    String? description,
    String? reason,
    IconData? icon,
    bool? isRequired,
    bool? isGranted,
  }) {
    return PermissionData(
      permission: permission ?? this.permission,
      title: title ?? this.title,
      description: description ?? this.description,
      reason: reason ?? this.reason,
      icon: icon ?? this.icon,
      isRequired: isRequired ?? this.isRequired,
      isGranted: isGranted ?? this.isGranted,
    );
  }
}

class PermissionService {
  static const String _permissionsGrantedKey = 'permissions_granted';
  static const String _permissionsAskedKey = 'permissions_asked';

  // Define all permissions needed by the app
  static final List<PermissionData> _requiredPermissions = [
    PermissionData(
      permission: Permission.storage,
      title: 'Storage Access',
      description: 'Access device storage to save and retrieve legal documents',
      reason: 'Required to store case files, documents, and offline data for your legal work.',
      icon: Icons.folder,
      isRequired: true,
      isGranted: false,
    ),
    PermissionData(
      permission: Permission.camera,
      title: 'Camera Access',
      description: 'Take photos of documents and evidence',
      reason: 'Allows you to capture documents, evidence photos, and scan legal papers.',
      icon: Icons.camera_alt,
      isRequired: true,
      isGranted: false,
    ),
    PermissionData(
      permission: Permission.microphone,
      title: 'Microphone Access',
      description: 'Record audio notes and voice memos',
      reason: 'Enables voice recording for case notes, client interviews, and audio documentation.',
      icon: Icons.mic,
      isRequired: false,
      isGranted: false,
    ),
    PermissionData(
      permission: Permission.notification,
      title: 'Notifications',
      description: 'Receive important case updates and reminders',
      reason: 'Stay informed about case deadlines, court dates, and important legal updates.',
      icon: Icons.notifications,
      isRequired: true,
      isGranted: false,
    ),
    PermissionData(
      permission: Permission.location,
      title: 'Location Access',
      description: 'Find nearby courts and legal services',
      reason: 'Helps locate nearby courts, law firms, and legal service providers.',
      icon: Icons.location_on,
      isRequired: false,
      isGranted: false,
    ),
    PermissionData(
      permission: Permission.phone,
      title: 'Phone Access',
      description: 'Make calls to legal contacts and emergency services',
      reason: 'Enables direct calling to lawyers, courts, and emergency legal services.',
      icon: Icons.phone,
      isRequired: false,
      isGranted: false,
    ),
  ];

  // Check if permissions have been requested before
  static Future<bool> hasAskedForPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsAskedKey) ?? false;
  }

  // Check if permissions have been requested before (alias for compatibility)
  static Future<bool> hasRequestedPermissions() async {
    return await hasAskedForPermissions();
  }

  // Mark that permissions have been asked
  static Future<void> markPermissionsAsked() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsAskedKey, true);
  }

  // Mark that permissions have been requested (alias for compatibility)
  static Future<void> markPermissionsRequested() async {
    await markPermissionsAsked();
  }

  // Check if all required permissions are granted
  static Future<bool> areRequiredPermissionsGranted() async {
    final permissions = await getPermissionStatuses();
    return permissions
        .where((p) => p.isRequired)
        .every((p) => p.isGranted);
  }

  // Get current status of all permissions
  static Future<List<PermissionData>> getPermissionStatuses() async {
    final List<PermissionData> permissionStatuses = [];
    
    for (final permissionData in _requiredPermissions) {
      final status = await permissionData.permission.status;
      permissionStatuses.add(
        permissionData.copyWith(
          isGranted: status == PermissionStatus.granted,
        ),
      );
    }
    
    return permissionStatuses;
  }

  // Request a single permission
  static Future<bool> requestPermission(Permission permission) async {
    final status = await permission.request();
    return status == PermissionStatus.granted;
  }

  // Request multiple permissions
  static Future<Map<Permission, PermissionStatus>> requestPermissions(
    List<Permission> permissions,
  ) async {
    return await permissions.request();
  }

  // Request all required permissions
  static Future<bool> requestAllRequiredPermissions() async {
    final requiredPermissions = _requiredPermissions
        .where((p) => p.isRequired)
        .map((p) => p.permission)
        .toList();
    
    final results = await requestPermissions(requiredPermissions);
    
    // Check if all required permissions were granted
    final allGranted = results.values
        .every((status) => status == PermissionStatus.granted);
    
    if (allGranted) {
      await markPermissionsAsGranted();
    }
    
    return allGranted;
  }

  // Request all permissions (required and optional)
  static Future<Map<Permission, PermissionStatus>> requestAllPermissions() async {
    final allPermissions = _requiredPermissions
        .map((p) => p.permission)
        .toList();
    
    final results = await requestPermissions(allPermissions);
    
    // Check if all required permissions were granted
    final requiredResults = results.entries
        .where((entry) => _requiredPermissions
            .where((p) => p.isRequired)
            .map((p) => p.permission)
            .contains(entry.key))
        .map((entry) => entry.value);
    
    final allRequiredGranted = requiredResults
        .every((status) => status == PermissionStatus.granted);
    
    if (allRequiredGranted) {
      await markPermissionsAsGranted();
    }
    
    await markPermissionsAsked();
    
    return results;
  }

  // Request only essential permissions for core app functionality
  static Future<void> requestEssentialPermissions() async {
    // Only request the most critical permissions: storage and notifications
    final essentialPermissions = [
      Permission.storage,
      Permission.notification,
    ];
    
    try {
      final results = await requestPermissions(essentialPermissions);
      
      // Log results but don't block app functionality
      for (final entry in results.entries) {
        print('Permission ${entry.key}: ${entry.value}');
      }
      
      // Mark permissions as asked regardless of result
      await markPermissionsAsked();
    } catch (e) {
      print('Error requesting essential permissions: $e');
      // Continue without blocking the app
    }
  }

  // Mark permissions as granted
  static Future<void> markPermissionsAsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_permissionsGrantedKey, true);
  }

  // Check if permissions are marked as granted
  static Future<bool> arePermissionsMarkedAsGranted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_permissionsGrantedKey) ?? false;
  }

  // Open app settings for manual permission management
  static Future<bool> openAppSettings() async {
    return await openAppSettings();
  }

  // Check if permission is permanently denied
  static Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await permission.status;
    return status == PermissionStatus.permanentlyDenied;
  }

  // Get permission rationale text
  static String getPermissionRationale(Permission permission) {
    final permissionData = _requiredPermissions
        .firstWhere((p) => p.permission == permission);
    return permissionData.reason;
  }

  // Get all permission data
  static List<PermissionData> getAllPermissionData() {
    return List.from(_requiredPermissions);
  }

  // Get required permissions only
  static List<PermissionData> getRequiredPermissionData() {
    return _requiredPermissions.where((p) => p.isRequired).toList();
  }

  // Get optional permissions only
  static List<PermissionData> getOptionalPermissionData() {
    return _requiredPermissions.where((p) => !p.isRequired).toList();
  }

  // Reset permission preferences (for testing)
  static Future<void> resetPermissionPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_permissionsGrantedKey);
    await prefs.remove(_permissionsAskedKey);
  }

  // Check if app should show permission request
  static Future<bool> shouldShowPermissionRequest() async {
    final hasAsked = await hasAskedForPermissions();
    final areGranted = await areRequiredPermissionsGranted();
    
    // Show if we haven't asked before or if required permissions are not granted
    return !hasAsked || !areGranted;
  }
}

// Riverpod providers for permission management
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

final permissionStatusProvider = FutureProvider<List<PermissionData>>((ref) async {
  return await PermissionService.getPermissionStatuses();
});

final requiredPermissionsGrantedProvider = FutureProvider<bool>((ref) async {
  return await PermissionService.areRequiredPermissionsGranted();
});

final shouldShowPermissionRequestProvider = FutureProvider<bool>((ref) async {
  return await PermissionService.shouldShowPermissionRequest();
});