import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'case_model.g.dart';

@HiveType(typeId: 0, adapterName: 'CaseModelAdapter')
class CaseModel extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String title;
  
  @HiveField(2)
  final String plaintiff;
  
  @HiveField(3)
  final String defendant;
  
  @HiveField(4)
  final String caseNumber;
  
  @HiveField(5)
  final String court;
  
  @HiveField(6)
  final DateTime hearingDate;
  
  @HiveField(7)
  final CaseStatus status;
  
  @HiveField(8)
  final String? notes;
  
  @HiveField(9)
  final List<String> attachmentPaths;
  
  @HiveField(10)
  final List<String> attachmentUrls;
  
  @HiveField(11)
  final bool isSynced;
  
  @HiveField(12)
  final DateTime createdAt;
  
  @HiveField(13)
  final DateTime updatedAt;
  
  @HiveField(14)
  final String ownerId;
  
  @HiveField(15)
  final String? lastNotePreview;

  @HiveField(16)
  final String category;

  CaseModel({
    required this.id,
    required this.title,
    required this.plaintiff,
    required this.defendant,
    required this.caseNumber,
    required this.court,
    required this.hearingDate,
    required this.status,
    this.notes,
    this.attachmentPaths = const [],
    this.attachmentUrls = const [],
    this.isSynced = false,
    required this.createdAt,
    required this.updatedAt,
    required this.ownerId,
    this.lastNotePreview,
    this.category = 'Civil Law',
  });

  // Getter for case number (alias for caseNumber)
  String get caseNo => caseNumber;

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      plaintiff: json['plaintiff'] ?? '',
      defendant: json['defendant'] ?? '',
      caseNumber: json['caseNumber'] ?? '',
      court: json['court'] ?? '',
      hearingDate: DateTime.parse(json['hearingDate']),
      status: CaseStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CaseStatus.draft,
      ),
      notes: json['notes'],
      attachmentPaths: List<String>.from(json['attachmentPaths'] ?? []),
      attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
      isSynced: json['isSynced'] ?? true,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      ownerId: json['ownerId'] ?? '',
      lastNotePreview: json['lastNotePreview'],
      category: json['category'] ?? 'Civil Law',
    );
  }

  factory CaseModel.fromMap(Map<String, dynamic> map) {
    return CaseModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      plaintiff: map['plaintiff'] ?? '',
      defendant: map['defendant'] ?? '',
      caseNumber: map['caseNumber'] ?? '',
      court: map['court'] ?? '',
      hearingDate: (map['hearingDate'] as Timestamp).toDate(),
      status: CaseStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CaseStatus.draft,
      ),
      notes: map['notes'],
      attachmentPaths: List<String>.from(map['attachmentPaths'] ?? []),
      attachmentUrls: List<String>.from(map['attachmentUrls'] ?? []),
      isSynced: map['isSynced'] ?? true,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      ownerId: map['ownerId'] ?? '',
      lastNotePreview: map['lastNotePreview'],
      category: map['category'] ?? 'Civil Law',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'plaintiff': plaintiff,
      'defendant': defendant,
      'caseNumber': caseNumber,
      'court': court,
      'hearingDate': Timestamp.fromDate(hearingDate),
      'status': status.name,
      'notes': notes,
      'attachmentPaths': attachmentPaths,
      'attachmentUrls': attachmentUrls,
      'isSynced': isSynced,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'ownerId': ownerId,
      'lastNotePreview': lastNotePreview,
      'category': category,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'plaintiff': plaintiff,
      'defendant': defendant,
      'caseNumber': caseNumber,
      'court': court,
      'hearingDate': hearingDate.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'attachmentPaths': attachmentPaths,
      'attachmentUrls': attachmentUrls,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'ownerId': ownerId,
      'lastNotePreview': lastNotePreview,
    };
  }

  CaseModel copyWith({
    String? id,
    String? title,
    String? plaintiff,
    String? defendant,
    String? caseNumber,
    String? court,
    DateTime? hearingDate,
    CaseStatus? status,
    String? notes,
    List<String>? attachmentPaths,
    List<String>? attachmentUrls,
    bool? isSynced,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? ownerId,
    String? lastNotePreview,
    String? category,
  }) {
    return CaseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      plaintiff: plaintiff ?? this.plaintiff,
      defendant: defendant ?? this.defendant,
      caseNumber: caseNumber ?? this.caseNumber,
      court: court ?? this.court,
      hearingDate: hearingDate ?? this.hearingDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      isSynced: isSynced ?? this.isSynced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      ownerId: ownerId ?? this.ownerId,
      lastNotePreview: lastNotePreview ?? this.lastNotePreview,
      category: category ?? this.category,
    );
  }
}

@HiveType(typeId: 1)
enum CaseStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  closed,
}

extension CaseStatusExtension on CaseStatus {
  String get name {
    switch (this) {
      case CaseStatus.draft:
        return 'draft';
      case CaseStatus.inProgress:
        return 'in_progress';
      case CaseStatus.closed:
        return 'closed';
    }
  }

  String get displayName {
    switch (this) {
      case CaseStatus.draft:
        return 'Draft';
      case CaseStatus.inProgress:
        return 'In Progress';
      case CaseStatus.closed:
        return 'Closed';
    }
  }

  String get statusDisplay {
    switch (this) {
      case CaseStatus.draft:
        return 'Draft';
      case CaseStatus.inProgress:
        return 'In Progress';
      case CaseStatus.closed:
        return 'Closed';
    }
  }
}

// Pakistan Court Names
class PakistanCourts {
  static const List<String> courts = [
    'Supreme Court of Pakistan',
    'Lahore High Court',
    'Sindh High Court',
    'Peshawar High Court',
    'Balochistan High Court',
    'Islamabad High Court',
    'Banking Court',
    'Anti-Terrorism Court',
    'Family Court',
    'Civil Court',
    'Sessions Court',
  ];
}

// Case Categories
class CaseCategories {
  static const List<String> categories = [
    'Civil Law',
    'Criminal Law',
    'Family Law',
    'Corporate Law',
    'Labor Law',
    'Property Law',
    'Tax Law',
    'Banking Law',
    'Environmental Law',
    'Constitutional Law',
    'Administrative Law',
    'Immigration Law',
    'Cyber Law',
  ];

  static String getDefaultCategory() => 'Civil Law';

  static bool isValidCategory(String category) {
    return categories.contains(category);
  }
}
