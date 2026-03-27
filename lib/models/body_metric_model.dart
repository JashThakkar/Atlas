class BodyMetricModel {
  final String? id;
  final String userId;
  final String metricType;
  final double value;
  final String unit;
  final DateTime date;

  BodyMetricModel({
    this.id,
    required this.userId,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.date,
  });

  factory BodyMetricModel.fromMap(Map<String, dynamic> map) {
    return BodyMetricModel(
      id: map['id'] as String?,
      userId: map['userId'] as String? ?? '',
      metricType: map['metricType'] as String? ?? '',
      value: (map['value'] as num? ?? 0).toDouble(),
      unit: map['unit'] as String? ?? 'kg',
      date: DateTime.fromMillisecondsSinceEpoch(
          map['date'] as int? ?? DateTime.now().millisecondsSinceEpoch),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'metricType': metricType,
      'value': value,
      'unit': unit,
      'date': date.millisecondsSinceEpoch,
    };
  }
}
