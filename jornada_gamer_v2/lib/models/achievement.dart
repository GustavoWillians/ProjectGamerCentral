// lib/models/achievement.dart

class Achievement {
  final String apiName; // Nome interno da API
  final String displayName; // Nome visível para o jogador
  final String description;
  final bool isAchieved;
  final DateTime? unlockTime;

  Achievement({
    required this.apiName,
    required this.displayName,
    required this.description,
    required this.isAchieved,
    this.unlockTime,
  });
}