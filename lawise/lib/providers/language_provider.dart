import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/data_persistence_service.dart';

class LanguageNotifier extends StateNotifier<String> {
  LanguageNotifier() : super('english');

  void setLanguage(String language) async {
    state = language;
    
    // Persist the language setting
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      await persistenceService.saveSettings(
        isDarkMode: false, // Default theme, will be updated by ThemeProvider
        language: language,
      );
      print('Language setting saved: $language');
    } catch (e) {
      print('Error saving language setting: $e');
    }
  }

  String get currentLanguage => state;

  // Load language from persistence
  Future<void> loadLanguageFromPersistence() async {
    try {
      final persistenceService = await DataPersistenceService.getInstance();
      final settings = persistenceService.getSettings();
      
      if (settings != null) {
        state = settings['language'] ?? 'english';
      }
    } catch (e) {
      print('Error loading language from persistence: $e');
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, String>((ref) {
  return LanguageNotifier();
});
