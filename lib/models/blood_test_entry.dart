class BloodTestEntry {
  final String id;
  final DateTime date;

  // Glicemia & Insulina
  final double? glycemia;
  final double? hba1c;
  final double? insulin;

  // Assetto Marziale
  final double? iron;
  final double? ferritin;

  // Vitamine ed Elettroliti
  final double? potassium;
  final double? vitaminD;
  final double? vitaminB12;

  // Funzionalità Epatica
  final double? ast;
  final double? alt;
  final double? ggt;

  // Emocromo
  final double? hemoglobin;
  final double? redBloodCells;
  final double? whiteBloodCells;
  final double? platelets;

  BloodTestEntry({
    required this.id,
    required this.date,
    this.glycemia,
    this.hba1c,
    this.insulin,
    this.iron,
    this.ferritin,
    this.potassium,
    this.vitaminD,
    this.vitaminB12,
    this.ast,
    this.alt,
    this.ggt,
    this.hemoglobin,
    this.redBloodCells,
    this.whiteBloodCells,
    this.platelets,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'date': date.toIso8601String(),
    'glycemia': glycemia,
    'hba1c': hba1c,
    'insulin': insulin,
    'iron': iron,
    'ferritin': ferritin,
    'potassium': potassium,
    'vitaminD': vitaminD,
    'vitaminB12': vitaminB12,
    'ast': ast,
    'alt': alt,
    'ggt': ggt,
    'hemoglobin': hemoglobin,
    'redBloodCells': redBloodCells,
    'whiteBloodCells': whiteBloodCells,
    'platelets': platelets,
  };

  factory BloodTestEntry.fromMap(Map<String, dynamic> map) => BloodTestEntry(
    id: map['id'] ?? DateTime.now().toIso8601String(),
    date: DateTime.parse(map['date']),
    glycemia: (map['glycemia'] as num?)?.toDouble(),
    hba1c: (map['hba1c'] as num?)?.toDouble(),
    insulin: (map['insulin'] as num?)?.toDouble(),
    iron: (map['iron'] as num?)?.toDouble(),
    ferritin: (map['ferritin'] as num?)?.toDouble(),
    potassium: (map['potassium'] as num?)?.toDouble(),
    vitaminD: (map['vitaminD'] as num?)?.toDouble(),
    vitaminB12: (map['vitaminB12'] as num?)?.toDouble(),
    ast: (map['ast'] as num?)?.toDouble(),
    alt: (map['alt'] as num?)?.toDouble(),
    ggt: (map['ggt'] as num?)?.toDouble(),
    hemoglobin: (map['hemoglobin'] as num?)?.toDouble(),
    redBloodCells: (map['redBloodCells'] as num?)?.toDouble(),
    whiteBloodCells: (map['whiteBloodCells'] as num?)?.toDouble(),
    platelets: (map['platelets'] as num?)?.toDouble(),
  );
}
