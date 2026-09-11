class UserModel {
  String id;
  String name;
  double currentWeight;
  double targetWeight;
  double height;
  int currentHearts;     // Cuori attuali riempiti oggi
  int maxHearts;        // Cuori totali / cap giornaliero
  int coins;            // Monete/Rupie per comprare abiti e mobili
  int xp;               // Punti esperienza per la progressione
  AvatarConfig avatarConfig;

  UserModel({
    required this.id,
    required this.name,
    required this.currentWeight,
    required this.targetWeight,
    this.height = 165.0,
    this.currentHearts = 4,
    this.maxHearts = 10,
    this.coins = 0,
    this.xp = 0,
    required this.avatarConfig,
  });

  // Alias utili se nel codice usi "heartsToday" o "maxHeartsDaily"
  int get heartsToday => currentHearts;
  set heartsToday(int val) => currentHearts = val;
  int get maxHeartsDaily => maxHearts;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'height': height,
      'currentHearts': currentHearts,
      'maxHearts': maxHearts,
      'coins': coins,
      'xp': xp,
      'avatarConfig': avatarConfig.toMap(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? 'user_local',
      name: map['name'] ?? 'Giada',
      currentWeight: (map['currentWeight'] ?? 94.0).toDouble(),
      targetWeight: (map['targetWeight'] ?? 80.0).toDouble(),
      height: (map['height'] ?? 165.0).toDouble(),
      currentHearts: map['currentHearts'] ?? 4,
      maxHearts: map['maxHearts'] ?? 10,
      coins: map['coins'] ?? 0,
      xp: map['xp'] ?? 0,
      avatarConfig: map['avatarConfig'] != null
          ? AvatarConfig.fromMap(Map<String, dynamic>.from(map['avatarConfig']))
          : AvatarConfig(),
    );
  }
}

class AvatarConfig {
  String hairStyle;
  String hairColor;
  String skinColor;
  String outfitId;
  String headwearId;

  AvatarConfig({
    this.hairStyle = 'short',
    this.hairColor = '#4A3525',
    this.skinColor = '#F5D0A9',
    this.outfitId = 'default_sweater',
    this.headwearId = 'none',
  });

  Map<String, dynamic> toMap() {
    return {
      'hairStyle': hairStyle,
      'hairColor': hairColor,
      'skinColor': skinColor,
      'outfitId': outfitId,
      'headwearId': headwearId,
    };
  }

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    return AvatarConfig(
      hairStyle: map['hairStyle'] ?? 'short',
      hairColor: map['hairColor'] ?? '#4A3525',
      skinColor: map['skinColor'] ?? '#F5D0A9',
      outfitId: map['outfitId'] ?? 'default_sweater',
      headwearId: map['headwearId'] ?? 'none',
    );
  }
}
