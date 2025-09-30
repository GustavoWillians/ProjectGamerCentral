// lib/models/dashboard_data.dart

import 'activity_event.dart';
import 'game_info.dart';
import 'player_archetype.dart';

class DashboardData {
  final PlayerArchetype archetype;
  final List<GameInfo> allGames;
  final List<ActivityEvent> recentActivity;
  final double generalMasteryIndex; // <-- NOVA PROPRIEDADE

  DashboardData({
    required this.archetype,
    required this.allGames,
    required this.recentActivity,
    required this.generalMasteryIndex, // <-- NOVA PROPRIEDADE
  });
}