import 'package:cloud_firestore/cloud_firestore.dart';

class BugReportModel {
  final String? id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String priority; // Low, Medium, High
  final String status; // Submitted, In Progress, Resolved
  final DateTime createdAt;
  
  BugReportModel({
    this.id,
    required this.userId,
    required this.userName,
    required this.title,
    required this.description,
    this.priority = 'Medium',
    this.status = 'Submitted',
    required this.createdAt,
  });
  
  factory BugReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BugReportModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      priority: data['priority'] ?? 'Medium',
      status: data['status'] ?? 'Submitted',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
