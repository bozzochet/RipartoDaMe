class FoodItemModel {
  final String name;
  final String quantity;
  final int calories;
  final double proteins;
  final double carbs;
  final double fats;

  FoodItemModel({
    required this.name,
    required this.quantity,
    required this.calories,
    this.proteins = 0.0,
    this.carbs = 0.0,
    this.fats = 0.0,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'quantity': quantity,
    'calories': calories,
    'proteins': proteins,
    'carbs': carbs,
    'fats': fats,
  };

  factory FoodItemModel.fromMap(Map<String, dynamic> map) => FoodItemModel(
    name: map['name'] ?? '',
    quantity: map['quantity'] ?? '',
    calories: (map['calories'] as num?)?.toInt() ?? 0,
    proteins: (map['proteins'] as num?)?.toDouble() ?? 0.0,
    carbs: (map['carbs'] as num?)?.toDouble() ?? 0.0,
    fats: (map['fats'] as num?)?.toDouble() ?? 0.0,
  );
}

class MealEntryModel {
  final String title;
  final String icon;
  final List<FoodItemModel> items;
  String? photoPath;
  bool isRewardClaimed;

  MealEntryModel({
      required this.title,
      required this.icon,
      List<FoodItemModel>? items,
      this.photoPath,
      this.isRewardClaimed = false,
  }) : items = items ?? [];

  int get totalCalories => items.fold(0, (sum, item) => sum + item.calories);

  Map<String, dynamic> toMap() => {
    'title': title,
    'icon': icon,
    'items': items.map((i) => i.toMap()).toList(),
    'photoPath': photoPath,
    'isRewardClaimed': isRewardClaimed,
  };

  factory MealEntryModel.fromMap(Map<String, dynamic> map) => MealEntryModel(
    title: map['title'] ?? '',
    icon: map['icon'] ?? '',
    items: (map['items'] as List<dynamic>?)
    ?.map((i) {
        final itemMap = Map<dynamic, dynamic>.from(i);
        return FoodItemModel.fromMap(itemMap.map((k, v) => MapEntry(k.toString(), v)));
    })
    .toList() ??
    [],
    photoPath: map['photoPath'],
    isRewardClaimed: map['isRewardClaimed'] ?? false,
  );

}
