class DailyMenuModel {
  final String dayName; // Es. "Lunedì"
  final Map<String, String> meals; // Es. {"Colazione": " yogurt e mandorle", "Pranzo": "Petto di pollo con insalata", ...}

  DailyMenuModel({required this.dayName, required this.meals});

  Map<String, dynamic> toMap() => {
        'dayName': dayName,
        'meals': meals,
      };

  factory DailyMenuModel.fromMap(Map<String, dynamic> map) => DailyMenuModel(
        dayName: map['dayName'] ?? '',
        meals: Map<String, String>.from(map['meals'] ?? {}),
      );
}

class ShoppingItemModel {
  String id;
  String name;
  bool isChecked;
  String category; // Es. "Verdure", "Carne", "Dispensa"

  ShoppingItemModel({
    required this.id,
    required this.name,
    this.isChecked = false,
    this.category = 'Generale',
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isChecked': isChecked,
        'category': category,
      };

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) => ShoppingItemModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        isChecked: map['isChecked'] ?? false,
        category: map['category'] ?? 'Generale',
      );
}
