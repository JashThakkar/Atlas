class BugReportModel {
  final String? id;
  final String userId;
  final String userName;
  final String title;
  final String description;
  final String priority;
  final String status;
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

  factory BugReportModel.fromMap(Map<String, dynamic> map) {
    return BugReportModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      priority: map['priority'] as String? ?? 'Medium',
      status: map['status'] as String? ?? 'Submitted',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'title': title,
      'description': description,
      'priority': priority,
      'status': status,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }
}
