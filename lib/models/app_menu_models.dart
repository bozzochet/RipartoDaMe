class MenuIngredientModel {
  final String name;
  final double quantity;
  final String unit;
  final String category;

  MenuIngredientModel(
      {required this.name,
      required this.quantity,
      required this.unit,
      this.category = 'Generale'});

  Map<String, dynamic> toMap() =>
      {'name': name, 'quantity': quantity, 'unit': unit, 'category': category};

  factory MenuIngredientModel.fromMap(Map<String, dynamic> map) =>
      MenuIngredientModel(
        name: map['name']?.toString() ?? '',
        quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
        unit: map['unit']?.toString() ?? '',
        category: map['category']?.toString() ?? 'Generale',
      );
}

class MenuMealModel {
  final String mealType;
  final String description;
  final double? calories;
  final List<MenuIngredientModel> ingredients;

  MenuMealModel(
      {required this.mealType,
      required this.description,
      this.calories,
      this.ingredients = const []});

  Map<String, dynamic> toMap() => {
        'mealType': mealType,
        'description': description,
        'calories': calories,
        'ingredients': ingredients.map((item) => item.toMap()).toList(),
      };

  factory MenuMealModel.fromMap(Map<String, dynamic> map) {
    final rawIngredients = map['ingredients'];
    return MenuMealModel(
      mealType: map['mealType']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      calories: (map['calories'] as num?)?.toDouble(),
      ingredients: rawIngredients is List
          ? rawIngredients
              .whereType<Map>()
              .map((item) =>
                  MenuIngredientModel.fromMap(Map<String, dynamic>.from(item)))
              .toList()
          : [],
    );
  }
}

class DailyMenuModel {
  final String dayName;
  final List<MenuMealModel> meals;

  DailyMenuModel({required this.dayName, required this.meals});

  Map<String, dynamic> toMap() =>
      {'dayName': dayName, 'meals': meals.map((meal) => meal.toMap()).toList()};

  factory DailyMenuModel.fromMap(Map<String, dynamic> map) {
    final rawMeals = map['meals'];
    if (rawMeals is List) {
      return DailyMenuModel(
        dayName: map['dayName']?.toString() ?? '',
        meals: rawMeals
            .whereType<Map>()
            .map((meal) =>
                MenuMealModel.fromMap(Map<String, dynamic>.from(meal)))
            .toList(),
      );
    }
    if (rawMeals is Map) {
      return DailyMenuModel(
        dayName: map['dayName']?.toString() ?? '',
        meals: rawMeals.entries
            .map((entry) => MenuMealModel(
                mealType: entry.key.toString(),
                description: entry.value?.toString() ?? ''))
            .toList(),
      );
    }
    return DailyMenuModel(dayName: map['dayName']?.toString() ?? '', meals: []);
  }
}

class ShoppingItemModel {
  String id;
  String name;
  bool isChecked;
  String category;
  double? quantity;
  String? unit;

  ShoppingItemModel(
      {required this.id,
      required this.name,
      this.isChecked = false,
      this.category = 'Generale',
      this.quantity,
      this.unit});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isChecked': isChecked,
        'category': category,
        'quantity': quantity,
        'unit': unit
      };

  factory ShoppingItemModel.fromMap(Map<String, dynamic> map) =>
      ShoppingItemModel(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        isChecked: map['isChecked'] == true,
        category: map['category']?.toString() ?? 'Generale',
        quantity: (map['quantity'] as num?)?.toDouble(),
        unit: map['unit']?.toString(),
      );
}
