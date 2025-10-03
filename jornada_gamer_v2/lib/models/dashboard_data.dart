// lib/models/dashboard_data.dart

import 'activity_event.dart';
import 'game_info.dart';
import 'insight.dart';
import 'player_archetype.dart';

class DashboardData {
  final PlayerArchetype archetype;
  final List<GameInfo> allGames;
  final List<dynamic> ownedGamesRaw; // <-- NOVA PROPRIEDADE
  final List<ActivityEvent> recentActivity;
  final double generalMasteryIndex;
  final List<Insight> insights;

  DashboardData({
    required this.archetype,
    required this.allGames,
    required this.ownedGamesRaw, // <-- NOVA PROPRIEDADE
    required this.recentActivity,
    required this.generalMasteryIndex,
    required this.insights,
  });
}