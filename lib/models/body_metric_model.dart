import 'package:cloud_firestore/cloud_firestore.dart';

class BodyMetricModel {
  final String? id;
  final String userId;
  final String metricType; // Weight, Chest, Waist, etc.
  final double value;
  final String unit; // kg, cm, lbs, inches
  final DateTime date;
  
  BodyMetricModel({
    this.id,
    required this.userId,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.date,
  });
  
  factory BodyMetricModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BodyMetricModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      metricType: data['metricType'] ?? '',
      value: (data['value'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'kg',
      date: (data['date'] as Timestamp).toDate(),
    );
  }
  
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'metricType': metricType,
      'value': value,
      'unit': unit,
      'date': Timestamp.fromDate(date),
    };
  }
}
