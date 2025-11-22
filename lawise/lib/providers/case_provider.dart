import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/case_model.dart';
import '../controllers/case_controller.dart';

// Export the case controller providers
export '../controllers/case_controller.dart';

// Legacy provider for backward compatibility
final caseProvider = StateNotifierProvider<CaseController, CaseState>((ref) {
  return ref.watch(caseControllerProvider.notifier);
});

// Legacy providers for backward compatibility
final casesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).cases;
});

final filteredCasesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).filteredCases;
});

final todayHearingsProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).todayHearings;
});

final activeCasesProvider = Provider<List<CaseModel>>((ref) {
  return ref.watch(caseControllerProvider).activeCases;
});

final caseIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(caseControllerProvider).isLoading;
});

final caseErrorProvider = Provider<String?>((ref) {
  return ref.watch(caseControllerProvider).errorMessage;
});
