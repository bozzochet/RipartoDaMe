class ProgressPhotoEntry {
  final String id;
  final DateTime date;
  final String imagePath; // Percorso del file salvato nello storage locale del dispositivo
  final String? note;      // Nota opzionale (es. "Foto inizio percorso")

  ProgressPhotoEntry({
    required this.id,
    required this.date,
    required this.imagePath,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imagePath': imagePath,
      'note': note,
    };
  }

  factory ProgressPhotoEntry.fromMap(Map<String, dynamic> map) {
    return ProgressPhotoEntry(
      id: map['id'],
      date: DateTime.parse(map['date']),
      imagePath: map['imagePath'],
      note: map['note'],
    );
  }
}
