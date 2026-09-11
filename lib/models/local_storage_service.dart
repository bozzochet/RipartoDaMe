class LocalStorageService {
  // ... codice esistente ...

  // 1. Assegna CUORI (Per le abitudini giornaliere)
  Future<void> addHearts(int amount) async {
    final user = getUser();
    user.currentHearts = (user.currentHearts + amount).clamp(0, user.maxHearts);
    await saveUser(user);
  }

  // 2. Assegna MONETE (Per i traguardi sulla mappa e gli obiettivi grandi)
  Future<void> addCoins(int amount) async {
    final user = getUser();
    user.coins += amount;
    await saveUser(user);
  }
}