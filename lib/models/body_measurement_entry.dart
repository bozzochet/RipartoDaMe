class BodyMeasurementEntry {
  final DateTime date;
  final double? waist; // Vita (cm)
  final double? hips;  // Fianchi (cm)
  final double? arms;  // Braccia (cm)
  final double? thighs;// Cosce (cm)
  final double? chest; // Petto/Seno (cm)

  BodyMeasurementEntry({
    required this.date,
    this.waist,
    this.hips,
    this.arms,
    this.thighs,
    this.chest,
  });

  double? get legs => thighs;

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'waist': waist,
      'hips': hips,
      'arms': arms,
      'thighs': thighs,
      'chest': chest,
    };
  }

  factory BodyMeasurementEntry.fromMap(Map<String, dynamic> map) {
    return BodyMeasurementEntry(
      date: DateTime.parse(map['date']),
      waist: (map['waist'] as num?)?.toDouble(),
      hips: (map['hips'] as num?)?.toDouble(),
      arms: (map['arms'] as num?)?.toDouble(),
      thighs: (map['thighs'] as num?)?.toDouble(),
      chest: (map['chest'] as num?)?.toDouble(),
    );
  }
}
