// Simple script to clear persistent dummy data
// This script clears Hive boxes and SharedPreferences without Flutter dependencies

import 'dart:io';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  try {
    print('Starting to clear persistent dummy data...');
    
    // Initialize Hive with a simple path
    final appDocDir = await getApplicationDocumentsDirectory();
    Hive.init('${appDocDir.path}/hive');
    
    // Clear Hive boxes
    try {
      final profileBox = await Hive.openBox('user_profile');
      await profileBox.clear();
      await profileBox.close();
      print('✅ Cleared user_profile Hive box');
    } catch (e) {
      print('Note: user_profile box was already empty or not found');
    }
    
    try {
      final settingsBox = await Hive.openBox('app_settings');
      await settingsBox.clear();
      await settingsBox.close();
      print('✅ Cleared app_settings Hive box');
    } catch (e) {
      print('Note: app_settings box was already empty or not found');
    }
    
    // Clear SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print('✅ Cleared SharedPreferences');
    
    print('');
    print('🎉 All persistent dummy data cleared successfully!');
    print('You can now restart the app and the "Alexander Mitchell" profile should be gone.');
    print('Create a new account or sign in with your real name.');
    
  } catch (e) {
    print('❌ Error clearing dummy data: $e');
    exit(1);
  }
}