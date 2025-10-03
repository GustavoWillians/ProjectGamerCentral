// lib/models/milestone.dart

enum MilestoneType { achievement, game, stats }

class Milestone {
  final String title;
  final String subtitle;
  final String gameName;
  final MilestoneType type;
  final DateTime? timestamp; // A propriedade que estava faltando

  Milestone({
    required this.title,
    required this.subtitle,
    required this.gameName,
    required this.type,
    this.timestamp, // O parâmetro que estava faltando
  });
}