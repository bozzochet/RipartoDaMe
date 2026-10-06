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

class MenuAiValidationException implements Exception {
  final String message;

  const MenuAiValidationException(this.message);

  @override
  String toString() => message;
}

class MenuAiContract {
  static const List<String> expectedDays = [
    'Lunedì',
    'Martedì',
    'Mercoledì',
    'Giovedì',
    'Venerdì',
    'Sabato',
    'Domenica',
  ];

  static const List<String> expectedMealTypes = [
    'Colazione',
    'Spuntino',
    'Pranzo',
    'Merenda',
    'Cena',
  ];

  static const Set<String> allowedCategories = {
    'Frigo',
    'Carne e Pesce',
    'Frutta',
    'Verdura',
    'Dispensa',
    'Pane',
    'Generale',
  };

  static const String jsonShape = r'''
{
  "days": [
    {
      "dayName": "Lunedì",
      "meals": [
        {
          "mealType": "Colazione",
          "description": "Descrizione sintetica del pasto",
          "calories": 350,
          "ingredients": [
            {
              "name": "Yogurt greco",
              "quantity": 150,
              "unit": "g",
              "category": "Frigo"
            }
          ]
        }
      ]
    }
  ]
}
''';

  static List<DailyMenuModel> parseResponse(Map<String, dynamic> json) {
    final rawDays = json['days'];
    if (rawDays is! List) {
      throw const MenuAiValidationException(
        'La risposta AI non contiene una lista "days" valida.',
      );
    }
    if (rawDays.length != expectedDays.length) {
      throw MenuAiValidationException(
        'La risposta AI deve contenere esattamente 7 giorni, ma ne contiene ${rawDays.length}.',
      );
    }

    final parsedByDay = <String, DailyMenuModel>{};

    for (final rawDay in rawDays) {
      if (rawDay is! Map) {
        throw const MenuAiValidationException(
          'Un giorno del menu non è un oggetto JSON valido.',
        );
      }

      final day = Map<String, dynamic>.from(rawDay);
      final dayName = day['dayName']?.toString().trim() ?? '';

      if (!expectedDays.contains(dayName)) {
        throw MenuAiValidationException(
          'Giorno non valido nella risposta AI: "$dayName".',
        );
      }
      if (parsedByDay.containsKey(dayName)) {
        throw MenuAiValidationException(
          'Il giorno "$dayName" compare più di una volta.',
        );
      }

      final rawMeals = day['meals'];
      if (rawMeals is! List || rawMeals.length != expectedMealTypes.length) {
        throw MenuAiValidationException(
          '$dayName deve contenere esattamente 4 pasti.',
        );
      }

      final parsedMeals = <String, MenuMealModel>{};

      for (final rawMeal in rawMeals) {
        if (rawMeal is! Map) {
          throw MenuAiValidationException(
            '$dayName contiene un pasto non valido.',
          );
        }

        final meal = Map<String, dynamic>.from(rawMeal);
        final mealType = meal['mealType']?.toString().trim() ?? '';

        if (!expectedMealTypes.contains(mealType)) {
          throw MenuAiValidationException(
            '$dayName contiene un tipo di pasto non valido: "$mealType".',
          );
        }
        if (parsedMeals.containsKey(mealType)) {
          throw MenuAiValidationException(
            '$dayName contiene due pasti di tipo "$mealType".',
          );
        }

        final description = meal['description']?.toString().trim() ?? '';
        if (description.isEmpty) {
          throw MenuAiValidationException(
            '$dayName - $mealType non contiene una descrizione.',
          );
        }

        double? calories;
        final rawCalories = meal['calories'];
        if (rawCalories != null) {
          if (rawCalories is! num || rawCalories <= 0) {
            throw MenuAiValidationException(
              '$dayName - $mealType contiene calorie non valide.',
            );
          }
          calories = rawCalories.toDouble();
        }

        final rawIngredients = meal['ingredients'];
        if (rawIngredients is! List || rawIngredients.isEmpty) {
          throw MenuAiValidationException(
            '$dayName - $mealType deve contenere almeno un ingrediente.',
          );
        }

        final ingredients = <MenuIngredientModel>[];
        for (final rawIngredient in rawIngredients) {
          if (rawIngredient is! Map) {
            throw MenuAiValidationException(
              '$dayName - $mealType contiene un ingrediente non valido.',
            );
          }

          final ingredient = Map<String, dynamic>.from(rawIngredient);
          final name = ingredient['name']?.toString().trim() ?? '';
          final quantity = ingredient['quantity'];
          final unit = ingredient['unit']?.toString().trim() ?? '';
          final category = ingredient['category']?.toString().trim() ?? '';

          if (name.isEmpty) {
            throw MenuAiValidationException(
              '$dayName - $mealType contiene un ingrediente senza nome.',
            );
          }
          if (quantity is! num || quantity <= 0) {
            throw MenuAiValidationException(
              '$dayName - $mealType: quantità non valida per "$name".',
            );
          }
          if (unit.isEmpty) {
            throw MenuAiValidationException(
              '$dayName - $mealType: unità mancante per "$name".',
            );
          }
          if (!allowedCategories.contains(category)) {
            throw MenuAiValidationException(
              '$dayName - $mealType: categoria non valida per "$name": "$category".',
            );
          }

          ingredients.add(
            MenuIngredientModel(
              name: name,
              quantity: quantity.toDouble(),
              unit: unit,
              category: category,
            ),
          );
        }

        parsedMeals[mealType] = MenuMealModel(
          mealType: mealType,
          description: description,
          calories: calories,
          ingredients: ingredients,
        );
      }

      for (final mealType in expectedMealTypes) {
        if (!parsedMeals.containsKey(mealType)) {
          throw MenuAiValidationException(
            '$dayName non contiene il pasto "$mealType".',
          );
        }
      }

      parsedByDay[dayName] = DailyMenuModel(
        dayName: dayName,
        meals: expectedMealTypes.map((type) => parsedMeals[type]!).toList(),
      );
    }

    for (final dayName in expectedDays) {
      if (!parsedByDay.containsKey(dayName)) {
        throw MenuAiValidationException(
          'La risposta AI non contiene "$dayName".',
        );
      }
    }

    return expectedDays.map((day) => parsedByDay[day]!).toList();
  }

  static Map<String, dynamic> demoJsonFromMenu(
    List<DailyMenuModel> menu,
  ) =>
      {
        'days': menu.map((day) => day.toMap()).toList(),
      };
}

class MenuGenerationInfo {
  final int? targetCalories;
  final String dietStyle;
  final List<String> excludedFoods;
  final bool halal;
  final bool kosher;
  final String? dietDocumentName;
  final DateTime generatedAt;

  MenuGenerationInfo({
    this.targetCalories,
    required this.dietStyle,
    this.excludedFoods = const [],
    this.halal = false,
    this.kosher = false,
    this.dietDocumentName,
    required this.generatedAt,
  });

  Map<String, dynamic> toMap() => {
        'targetCalories': targetCalories,
        'dietStyle': dietStyle,
        'excludedFoods': excludedFoods,
        'halal': halal,
        'kosher': kosher,
        'dietDocumentName': dietDocumentName,
        'generatedAt': generatedAt.toIso8601String(),
      };

  factory MenuGenerationInfo.fromMap(Map<String, dynamic> map) {
    final rawExcluded = map['excludedFoods'];
    return MenuGenerationInfo(
      targetCalories: (map['targetCalories'] as num?)?.round(),
      dietStyle: map['dietStyle']?.toString() ?? 'Standard',
      excludedFoods: rawExcluded is List
          ? rawExcluded.map((item) => item.toString()).toList()
          : [],
      halal: map['halal'] == true,
      kosher: map['kosher'] == true,
      dietDocumentName: map['dietDocumentName']?.toString(),
      generatedAt: DateTime.tryParse(map['generatedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}
