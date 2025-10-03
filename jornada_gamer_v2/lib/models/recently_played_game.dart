// lib/models/recently_played_game.dart
class RecentlyPlayedGame {
  final int appId;
  final String name;
  final int playtime2WeeksMinutes; // Tempo jogado nas últimas 2 semanas
  final int playtimeForeverMinutes; // Tempo jogado total

  RecentlyPlayedGame({
    required this.appId,
    required this.name,
    required this.playtime2WeeksMinutes,
    required this.playtimeForeverMinutes,
  });
}