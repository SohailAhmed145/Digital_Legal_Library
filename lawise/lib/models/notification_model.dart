enum NotificationType {
  caseReminder,
  lawUpdate,
  urgent,
  system,
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final NotificationPriority priority;
  final DateTime timestamp;
  final bool isRead;
  final String? caseId;
  final String? documentId;
  final Map<String, dynamic>? metadata;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.priority,
    required this.timestamp,
    required this.isRead,
    this.caseId,
    this.documentId,
    this.metadata,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    NotificationPriority? priority,
    DateTime? timestamp,
    bool? isRead,
    String? caseId,
    String? documentId,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      caseId: caseId ?? this.caseId,
      documentId: documentId ?? this.documentId,
      metadata: metadata ?? this.metadata,
    );
  }
}

// Mock data for development
class MockNotificationData {
  static final List<NotificationItem> mockNotifications = [
    NotificationItem(
      id: '1',
      title: 'Case Reminder',
      message: 'Hearing scheduled for Johnson vs Smith Co. tomorrow at 10:00 AM',
      type: NotificationType.caseReminder,
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      caseId: 'case_123',
      documentId: null,
      metadata: {
        'hearingDate': '2024-03-16T10:00:00Z',
        'court': 'District Court',
        'caseNumber': 'DC-2024-001',
      },
    ),
    NotificationItem(
      id: '2',
      title: 'Law Update',
      message: 'New amendment to Section 123 of Corporate Act has been published',
      type: NotificationType.lawUpdate,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: false,
      caseId: null,
      documentId: 'doc_456',
      metadata: {
        'actName': 'Corporate Act',
        'section': '123',
        'amendmentDate': '2024-03-15',
      },
    ),
    NotificationItem(
      id: '3',
      title: 'Urgent',
      message: 'Document review for Wallace Legal Case required within 24 hours',
      type: NotificationType.urgent,
      priority: NotificationPriority.urgent,
      timestamp: DateTime.now().subtract(const Duration(hours: 6)),
      isRead: false,
      caseId: 'case_789',
      documentId: null,
      metadata: {
        'deadline': '2024-03-17T18:00:00Z',
        'priority': 'high',
        'assignedTo': 'current_user',
      },
    ),
    NotificationItem(
      id: '4',
      title: 'System',
      message: 'Weekly case review is complete. 5 cases require attention',
      type: NotificationType.system,
      priority: NotificationPriority.low,
      timestamp: DateTime.now().subtract(const Duration(hours: 8)),
      isRead: true,
      caseId: null,
      documentId: null,
      metadata: {
        'reviewType': 'weekly',
        'casesCount': 5,
        'reviewDate': '2024-03-15',
      },
    ),
    NotificationItem(
      id: '5',
      title: 'Case Reminder',
      message: 'Filing deadline approaching for Thompson Estate case',
      type: NotificationType.caseReminder,
      priority: NotificationPriority.high,
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      isRead: false,
      caseId: 'case_101',
      documentId: null,
      metadata: {
        'deadline': '2024-03-20T17:00:00Z',
        'filingType': 'motion',
        'court': 'Probate Court',
      },
    ),
    NotificationItem(
      id: '6',
      title: 'Law Update',
      message: 'Environmental Protection Act 2024 has been updated',
      type: NotificationType.lawUpdate,
      priority: NotificationPriority.medium,
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
      isRead: true,
      caseId: null,
      documentId: 'doc_789',
      metadata: {
        'actName': 'Environmental Protection Act',
        'updateDate': '2024-03-13',
        'version': '2024.1',
      },
    ),
  ];

  static List<NotificationItem> getNotificationsByType(NotificationType type) {
    if (type == NotificationType.caseReminder) {
      return mockNotifications.where((n) => n.type == NotificationType.caseReminder).toList();
    } else if (type == NotificationType.lawUpdate) {
      return mockNotifications.where((n) => n.type == NotificationType.lawUpdate).toList();
    } else if (type == NotificationType.urgent) {
      return mockNotifications.where((n) => n.type == NotificationType.urgent).toList();
    } else if (type == NotificationType.system) {
      return mockNotifications.where((n) => n.type == NotificationType.system).toList();
    }
    return mockNotifications;
  }

  static List<NotificationItem> getUnreadNotifications() {
    return mockNotifications.where((n) => !n.isRead).toList();
  }

  static int getUnreadCount() {
    return mockNotifications.where((n) => !n.isRead).length;
  }

  static List<NotificationItem> getNotificationsByPriority(NotificationPriority priority) {
    return mockNotifications.where((n) => n.priority == priority).toList();
  }
}
