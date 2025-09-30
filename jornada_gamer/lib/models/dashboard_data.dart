// lib/models/dashboard_data.dart

import 'activity_event.dart'; // Importa o novo modelo
import 'game_info.dart';
import 'player_archetype.dart';
// Remove o import de recently_played_game, pois será substituído

class DashboardData {
  final PlayerArchetype archetype;
  final List<GameInfo> allGames;
  final List<ActivityEvent> recentActivity; // Substitui a lista antiga

  DashboardData({
    required this.archetype,
    required this.allGames,
    required this.recentActivity, // Usa a nova lista de eventos
  });
}