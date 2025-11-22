import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';

// State for notifications
class NotificationState {
  final List<NotificationItem> notifications;
  final List<NotificationItem> filteredNotifications;
  final String selectedFilter;
  final bool isLoading;
  final String? errorMessage;
  final int unreadCount;

  NotificationState({
    required this.notifications,
    required this.filteredNotifications,
    required this.selectedFilter,
    required this.isLoading,
    this.errorMessage,
    required this.unreadCount,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    List<NotificationItem>? filteredNotifications,
    String? selectedFilter,
    bool? isLoading,
    String? errorMessage,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      filteredNotifications: filteredNotifications ?? this.filteredNotifications,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

// Provider for notification state
final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});

// Notifier for notification operations
class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState(
    notifications: [],
    filteredNotifications: [],
    selectedFilter: 'All',
    isLoading: false,
    unreadCount: 0,
  )) {
    _initializeData();
  }

  void _initializeData() {
    final notifications = MockNotificationData.mockNotifications;
    final unreadCount = MockNotificationData.getUnreadCount();
    
    state = state.copyWith(
      notifications: notifications,
      filteredNotifications: notifications,
      unreadCount: unreadCount,
    );
  }

  void setFilter(String filter) {
    state = state.copyWith(selectedFilter: filter);
    _applyFilter();
  }

  void _applyFilter() {
    List<NotificationItem> filtered;
    
    switch (state.selectedFilter) {
      case 'Case Reminders':
        filtered = MockNotificationData.getNotificationsByType(NotificationType.caseReminder);
        break;
      case 'Law Updates':
        filtered = MockNotificationData.getNotificationsByType(NotificationType.lawUpdate);
        break;
      case 'Urgent':
        filtered = MockNotificationData.getNotificationsByType(NotificationType.urgent);
        break;
      default:
        filtered = state.notifications;
    }

    state = state.copyWith(filteredNotifications: filtered);
  }

  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
    _applyFilter();
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications.map((notification) {
      return notification.copyWith(isRead: true);
    }).toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );
    _applyFilter();
  }

  void deleteNotification(String notificationId) {
    final updatedNotifications = state.notifications.where((n) => n.id != notificationId).toList();
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
    _applyFilter();
  }

  void clearAllNotifications() {
    state = state.copyWith(
      notifications: [],
      filteredNotifications: [],
      unreadCount: 0,
    );
  }

  List<NotificationItem> getNotificationsByType(NotificationType type) {
    return MockNotificationData.getNotificationsByType(type);
  }

  List<NotificationItem> getUnreadNotifications() {
    return MockNotificationData.getUnreadNotifications();
  }

  List<NotificationItem> getNotificationsByPriority(NotificationPriority priority) {
    return MockNotificationData.getNotificationsByPriority(priority);
  }

  void refreshData() {
    _initializeData();
  }

  void clearFilters() {
    state = state.copyWith(
      selectedFilter: 'All',
      filteredNotifications: state.notifications,
    );
  }
}

// Provider for filtered notifications
final filteredNotificationsProvider = Provider<List<NotificationItem>>((ref) {
  final state = ref.watch(notificationProvider);
  return state.filteredNotifications;
});

// Provider for unread count
final unreadNotificationsCountProvider = Provider<int>((ref) {
  final state = ref.watch(notificationProvider);
  return state.unreadCount;
});

// Provider for selected filter
final selectedNotificationFilterProvider = Provider<String>((ref) {
  final state = ref.watch(notificationProvider);
  return state.selectedFilter;
});
