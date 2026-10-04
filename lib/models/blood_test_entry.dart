class BloodTestEntry {
  final String id;
  final DateTime date;

  // Glicemia & Insulina
  final double? glycemia;
  final double? hba1c;
  final double? insulin;

  // Assetto Marziale (Ferro)
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

  // Emocromo Avanzato
  final double? hemoglobin;
  final double? redBloodCells;
  final double? whiteBloodCells;
  final double? platelets;
  final double? hematocrit;
  final double? mcv;
  final double? neutrophils;
  final double? lymphocytes;

  // Profilo Lipidico
  final double? totalCholesterol;
  final double? hdlCholesterol;
  final double? ldlCholesterol;
  final double? triglycerides;

  // Profilo Renale
  final double? creatinine;
  final double? gfr;

  // Coagulazione & Infiammazione
  final double? pt;
  final double? aptt;
  final double? fibrinogen;
  final double? ves;

  final String? filePath;

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
    this.hematocrit,
    this.mcv,
    this.neutrophils,
    this.lymphocytes,
    this.totalCholesterol,
    this.hdlCholesterol,
    this.ldlCholesterol,
    this.triglycerides,
    this.creatinine,
    this.gfr,
    this.pt,
    this.aptt,
    this.fibrinogen,
    this.ves,
    this.filePath,
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
    'hematocrit': hematocrit,
    'mcv': mcv,
    'neutrophils': neutrophils,
    'lymphocytes': lymphocytes,
    'totalCholesterol': totalCholesterol,
    'hdlCholesterol': hdlCholesterol,
    'ldlCholesterol': ldlCholesterol,
    'triglycerides': triglycerides,
    'creatinine': creatinine,
    'gfr': gfr,
    'pt': pt,
    'aptt': aptt,
    'fibrinogen': fibrinogen,
    'ves': ves,
    'filePath': filePath,
  };

  factory BloodTestEntry.fromMap(Map<String, dynamic> map) => BloodTestEntry(
    id: map['id'] ?? '',
    date: DateTime.parse(map['date']),
    glycemia: map['glycemia'] != null ? (map['glycemia'] as num).toDouble() : null,
    hba1c: map['hba1c'] != null ? (map['hba1c'] as num).toDouble() : null,
    insulin: map['insulin'] != null ? (map['insulin'] as num).toDouble() : null,
    iron: map['iron'] != null ? (map['iron'] as num).toDouble() : null,
    ferritin: map['ferritin'] != null ? (map['ferritin'] as num).toDouble() : null,
    potassium: map['potassium'] != null ? (map['potassium'] as num).toDouble() : null,
    vitaminD: map['vitaminD'] != null ? (map['vitaminD'] as num).toDouble() : null,
    vitaminB12: map['vitaminB12'] != null ? (map['vitaminB12'] as num).toDouble() : null,
    ast: map['ast'] != null ? (map['ast'] as num).toDouble() : null,
    alt: map['alt'] != null ? (map['alt'] as num).toDouble() : null,
    ggt: map['ggt'] != null ? (map['ggt'] as num).toDouble() : null,
    hemoglobin: map['hemoglobin'] != null ? (map['hemoglobin'] as num).toDouble() : null,
    redBloodCells: map['redBloodCells'] != null ? (map['redBloodCells'] as num).toDouble() : null,
    whiteBloodCells: map['whiteBloodCells'] != null ? (map['whiteBloodCells'] as num).toDouble() : null,
    platelets: map['platelets'] != null ? (map['platelets'] as num).toDouble() : null,
    hematocrit: map['hematocrit'] != null ? (map['hematocrit'] as num).toDouble() : null,
    mcv: map['mcv'] != null ? (map['mcv'] as num).toDouble() : null,
    neutrophils: map['neutrophils'] != null ? (map['neutrophils'] as num).toDouble() : null,
    lymphocytes: map['lymphocytes'] != null ? (map['lymphocytes'] as num).toDouble() : null,
    totalCholesterol: map['totalCholesterol'] != null ? (map['totalCholesterol'] as num).toDouble() : null,
    hdlCholesterol: map['hdlCholesterol'] != null ? (map['hdlCholesterol'] as num).toDouble() : null,
    ldlCholesterol: map['ldlCholesterol'] != null ? (map['ldlCholesterol'] as num).toDouble() : null,
    triglycerides: map['triglycerides'] != null ? (map['triglycerides'] as num).toDouble() : null,
    creatinine: map['creatinine'] != null ? (map['creatinine'] as num).toDouble() : null,
    gfr: map['gfr'] != null ? (map['gfr'] as num).toDouble() : null,
    pt: map['pt'] != null ? (map['pt'] as num).toDouble() : null,
    aptt: map['aptt'] != null ? (map['aptt'] as num).toDouble() : null,
    fibrinogen: map['fibrinogen'] != null ? (map['fibrinogen'] as num).toDouble() : null,
    ves: map['ves'] != null ? (map['ves'] as num).toDouble() : null,
    filePath: map['filePath'],
  );
}
