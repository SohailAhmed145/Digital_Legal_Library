import 'package:cloud_firestore/cloud_firestore.dart';

class CaseNote {
  final String id;
  final String text;
  final DateTime createdAt;
  final String createdBy;

  CaseNote({
    required this.id,
    required this.text,
    required this.createdAt,
    required this.createdBy,
  });

  // Create from Firestore document
  factory CaseNote.fromMap(Map<String, dynamic> map) {
    return CaseNote(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] ?? '',
    );
  }

  // Create from JSON (for API calls)
  factory CaseNote.fromJson(Map<String, dynamic> json) {
    return CaseNote(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      createdBy: json['createdBy'] ?? '',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  // Convert to JSON (for API calls)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  CaseNote copyWith({
    String? id,
    String? text,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return CaseNote(
      id: id ?? this.id,
      text: text ?? this.text,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}
