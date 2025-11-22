import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_persistence_service.dart';

class ThemeNotifier extends StateNotifier<bool> {
  ThemeNotifier() : super(false);

  void toggleTheme() async {
    final newState = !state;
    state = newState;
    
    // Persist the theme setting
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      await persistenceService.saveSettings(
        isDarkMode: newState,
        language: 'english', // Default language, will be updated by LanguageProvider
      );
      print('Theme setting saved: $newState');
    } catch (e) {
      print('Error saving theme setting: $e');
    }
  }

  void setTheme(bool isDark) async {
    state = isDark;
    
    // Persist the theme setting
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      await persistenceService.saveSettings(
        isDarkMode: isDark,
        language: 'english', // Default language, will be updated by LanguageProvider
      );
      print('Theme setting saved: $isDark');
    } catch (e) {
      print('Error saving theme setting: $e');
    }
  }

  // Load theme from persistence
  Future<void> loadThemeFromPersistence() async {
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      final settings = persistenceService.getSettings();
      
      if (settings != null) {
        state = settings['isDarkMode'] ?? false;
      }
    } catch (e) {
      print('Error loading theme from persistence: $e');
    }
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, bool>((ref) {
  return ThemeNotifier();
});
