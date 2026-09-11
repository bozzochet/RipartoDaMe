class HabitModel {
  final String id;
  final String title;
  final String icon;
  final int rewardHearts;
  final int rewardXp;
  bool isCompletedToday;

  HabitModel({
    required this.id,
    required this.title,
    this.icon = 'favorite',
    this.rewardHearts = 1,
    this.rewardXp = 10,
    this.isCompletedToday = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'icon': icon,
        'rewardHearts': rewardHearts,
        'rewardXp': rewardXp,
        'isCompletedToday': isCompletedToday,
      };

  factory HabitModel.fromMap(Map<String, dynamic> map) => HabitModel(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        icon: map['icon'] ?? 'favorite',
        rewardHearts: map['rewardHearts'] ?? 1,
        rewardXp: map['rewardXp'] ?? 10,
        isCompletedToday: map['isCompletedToday'] ?? false,
      );
}
