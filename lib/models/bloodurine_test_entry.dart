class BloodUrineTestEntry {
  final String id;
  final DateTime date;

  // --- ESAME URINE (Chimico-fisico, Striscia, Sedimento) ---
  final double? specificGravity;
  final double? ph;
  final double? proteins;
  final double? urineHemoglobin; // Distinto dall'emoglobina del sangue (double)
  final double? leukocyteEsterase;
  final double? nitrites;
  final double? urineGlucose;    // Distinto dalla glicemia del sangue (double)
  final double? ketones;
  final double? urobilinogen;
  final double? bilirubin;
  final double? urineRedBloodCells;    // Distinto dai globuli rossi del sangue (double)
  final double? urineWhiteBloodCells;   // Distinto dai globuli bianchi del sangue (double)
  final double? casts;
  final double? epithelialCells;

  final String? urineSediment;

  // --- ESAME SANGUE (Emocromo, Metabolico, Lipidico, Renale, ecc.) ---
  final double? glycemia;
  final double? hba1c;
  final double? insulin;
  final double? iron;
  final double? ferritin;
  final double? potassium;
  final double? vitaminD;
  final double? vitaminB12;
  final double? ast;
  final double? alt;
  final double? ggt;
  final double? hemoglobin;          // Emoglobina ematica (double)
  final double? redBloodCells;       // Globuli rossi ematici (double)
  final double? whiteBloodCells;     // Globuli bianchi ematici (double)
  final double? platelets;
  final double? hematocrit;
  final double? mcv;
  final double? neutrophils;
  final double? lymphocytes;
  final double? totalCholesterol;
  final double? hdlCholesterol;
  final double? ldlCholesterol;
  final double? triglycerides;
  final double? creatinine;
  final double? gfr;
  final double? pt;
  final double? aptt;
  final double? fibrinogen;
  final double? ves;

  final String? filePath;

  BloodUrineTestEntry({
    required this.id,
    required this.date,
    // Urine
    this.specificGravity,
    this.ph,
    this.proteins,
    this.urineHemoglobin,
    this.leukocyteEsterase,
    this.nitrites,
    this.urineGlucose,
    this.ketones,
    this.urobilinogen,
    this.bilirubin,
    this.urineRedBloodCells,
    this.urineWhiteBloodCells,
    this.casts,
    this.epithelialCells,
    this.urineSediment,
    // Blood
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
    // Urine mapping
    'specificGravity': specificGravity,
    'ph': ph,
    'proteins': proteins,
    'urineHemoglobin': urineHemoglobin,
    'leukocyteEsterase': leukocyteEsterase,
    'nitrites': nitrites,
    'urineGlucose': urineGlucose,
    'ketones': ketones,
    'urobilinogen': urobilinogen,
    'bilirubin': bilirubin,
    'urineRedBloodCells': urineRedBloodCells,
    'urineWhiteBloodCells': urineWhiteBloodCells,
    'casts': casts,
    'epithelialCells': epithelialCells,
    'urineSediment': urineSediment,
    // Blood mapping
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

  factory BloodUrineTestEntry.fromMap(Map<String, dynamic> map) => BloodUrineTestEntry(
    id: map['id'] ?? '',
    date: DateTime.parse(map['date']),
    // Urine unmarshaling
    specificGravity: map['specificGravity'] != null ? (map['specificGravity'] as num).toDouble() : null,
    ph: map['ph'] != null ? (map['ph'] as num).toDouble() : null,
    proteins: map['proteins'],
    urineHemoglobin: map['urineHemoglobin'],
    leukocyteEsterase: map['leukocyteEsterase'],
    nitrites: map['nitrites'],
    urineGlucose: map['urineGlucose'],
    ketones: map['ketones'],
    urobilinogen: map['urobilinogen'] != null ? (map['urobilinogen'] as num).toDouble() : null,
    bilirubin: map['bilirubin'] != null ? (map['bilirubin'] as num).toDouble() : null,
    urineRedBloodCells: map['urineRedBloodCells'] != null ? (map['urineRedBloodCells'] as num).toDouble() : null,
    urineWhiteBloodCells: map['urineWhiteBloodCells'] != null ? (map['urineWhiteBloodCells'] as num).toDouble() : null,
    casts: map['casts'] != null ? (map['casts'] as num).toDouble() : null,
    epithelialCells: map['epithelialCells'] != null ? (map['epithelialCells'] as num).toDouble() : null,
    urineSediment: map['urineSediment'],
    // Blood unmarshaling
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
