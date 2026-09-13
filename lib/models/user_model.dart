import '../constants/app_assets.dart';

class UserModel {
  String id;
  String name;
  double currentWeight;
  double targetWeight;
  double startWeight;
  double height;
  int currentHearts;     // Cuori attuali riempiti oggi
  int maxHearts;        // Cuori totali / cap giornaliero
  List<String> claimedStageIds; // Tappe della mappa già riscattate
  int coins;            // Monete/Rupie per comprare abiti e mobili
  int xp;               // Punti esperienza per la progressione
  AvatarConfig avatarConfig;

  UserModel({
    required this.id,
    required this.name,
    required this.currentWeight,
    required this.targetWeight,
    this.startWeight = 95.0,
    this.height = 165.0,
    this.currentHearts = 4,
    this.maxHearts = 10,
    this.coins = 0,
    this.xp = 0,
    required this.avatarConfig,
    List<String>? claimedStageIds,
  }) : claimedStageIds = claimedStageIds ?? [];

  // Alias utili
  int get heartsToday => currentHearts;
  set heartsToday(int val) => currentHearts = val;
  int get maxHeartsDaily => maxHearts;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'currentWeight': currentWeight,
      'targetWeight': targetWeight,
      'startWeight': startWeight,
      'height': height,
      'currentHearts': currentHearts,
      'maxHearts': maxHearts,
      'claimedStageIds': claimedStageIds, // <--- Aggiunto nel toMap
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
      startWeight: (map['startWeight'] ?? 95.0).toDouble(),
      height: (map['height'] ?? 165.0).toDouble(),
      currentHearts: map['currentHearts'] ?? 4,
      maxHearts: map['maxHearts'] ?? 10,
      claimedStageIds: map['claimedStageIds'] != null
          ? List<String>.from(map['claimedStageIds']) // <--- Aggiunto nel fromMap
          : [],
      coins: map['coins'] ?? 0,
      xp: map['xp'] ?? 0,
      avatarConfig: map['avatarConfig'] != null
          ? AvatarConfig.fromMap(Map<String, dynamic>.from(map['avatarConfig']))
          : AvatarConfig(),
    );
  }
}

class AvatarConfig {
  String bodyPath;
  String hairPath;
  String outfitPath;

  AvatarConfig({
    this.bodyPath = AppAssets.bodyBase1,
    this.hairPath = AppAssets.hairBlondeBraids,
    this.outfitPath = AppAssets.outfitAlchemist,
  });

  Map<String, dynamic> toMap() {
    return {
      'bodyPath': bodyPath,
      'hairPath': hairPath,
      'outfitPath': outfitPath,
    };
  }

  factory AvatarConfig.fromMap(Map<String, dynamic> map) {
    return AvatarConfig(
      bodyPath: map['bodyPath'] ?? AppAssets.bodyBase1,
      hairPath: map['hairPath'] ?? AppAssets.hairBlondeBraids,
      outfitPath: map['outfitPath'] ?? AppAssets.outfitAlchemist,
    );
  }
}
