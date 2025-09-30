// lib/services/steam_api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/achievement.dart';
import '../models/activity_event.dart';
import '../models/dashboard_data.dart';
import '../models/game_info.dart';
import '../models/player_archetype.dart';
import '../models/recently_played_game.dart';

class SteamApiService {
  // --- CONFIGURAÇÃO ---
  final String _apiKey = "48C424D69881697ED5756D576A2CD69C";
  final String _steamId = "76561198219730140";
  // --- FIM DA CONFIGURAÇÃO ---

  /// Função principal que nosso app vai chamar para buscar todos os dados do dashboard.
  Future<DashboardData> fetchDashboardData() async {
    final ownedGames = await _getOwnedGames(_apiKey, _steamId) ?? [];
    final recentlyPlayedGames = await _fetchRecentlyPlayedGames(_apiKey, _steamId);

    if (ownedGames.isEmpty) {
      throw Exception('Não foi possível buscar a lista de jogos. O perfil pode ser privado.');
    }

    final Map<int, int> lastPlayedTimestampMap = {
      for (var game in ownedGames) game['appid']: game['rtime_last_played'] ?? 0
    };

    final results = await Future.wait([
      _calculateArchetype(ownedGames),
      _fetchRecentAchievements(recentlyPlayedGames, _apiKey, _steamId),
    ]);

    final archetype = results[0] as PlayerArchetype;
    final recentAchievements = results[1] as List<ActivityEvent>;

    final playedEvents = recentlyPlayedGames.map((game) {
      final hours = (game.playtime2WeeksMinutes / 60).toStringAsFixed(1);
      final lastPlayedTimestamp = lastPlayedTimestampMap[game.appId] ?? 0;
      
      return ActivityEvent(
        title: game.name,
        description: 'Jogou por ${hours}h',
        timestamp: DateTime.fromMillisecondsSinceEpoch(lastPlayedTimestamp * 1000),
        type: ActivityEventType.played,
        appId: game.appId,
      );
    }).toList();

    final allActivities = [...recentAchievements, ...playedEvents]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final allGames = ownedGames.map((game) => GameInfo(
      appId: game['appid'],
      name: game['name'] ?? 'Nome Indisponível',
      playtimeMinutes: game['playtime_forever'] ?? 0,
    )).toList()
    ..sort((a, b) => b.playtimeMinutes.compareTo(a.playtimeMinutes));

    return DashboardData(
      archetype: archetype,
      allGames: allGames,
      recentActivity: allActivities,
    );
  }
  
  /// Busca as conquistas para um único jogo.
  Future<List<Achievement>> fetchAchievementsForGame(int appId) async {
    final url = Uri.parse('https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=$appId&key=$_apiKey&steamid=$_steamId&l=brazilian');
    List<Achievement> achievements = [];

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['playerstats'];
        if (data['success'] == true && data.containsKey('achievements')) {
          final List gameAchievements = data['achievements'];
          for (final ach in gameAchievements) {
            if (ach['achieved'] == 1) {
              achievements.add(Achievement(
                apiName: ach['apiname'],
                displayName: ach['name'] ?? 'Conquista',
                description: ach['description'] ?? 'Sem descrição.',
                isAchieved: true,
                unlockTime: DateTime.fromMillisecondsSinceEpoch(ach['unlocktime'] * 1000),
              ));
            }
          }
        }
      }
    } catch (e) {
      print("Erro ao buscar conquistas para o jogo $appId: $e");
    }
    achievements.sort((a, b) => b.unlockTime!.compareTo(a.unlockTime!));
    return achievements;
  }
  
  /// Busca as conquistas recentes para os jogos jogados recentemente.
  Future<List<ActivityEvent>> _fetchRecentAchievements(List<RecentlyPlayedGame> recentGames, String apiKey, String steamId) async {
    List<ActivityEvent> achievements = [];
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

    for (final game in recentGames) {
      final url = Uri.parse('https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=${game.appId}&key=$apiKey&steamid=$steamId');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body)['playerstats'];
          if (data.containsKey('achievements') && data['success'] == true) {
            final List gameAchievements = data['achievements'];
            for (final ach in gameAchievements) {
              if (ach['achieved'] == 1) {
                final unlockTime = DateTime.fromMillisecondsSinceEpoch(ach['unlocktime'] * 1000);
                if (unlockTime.isAfter(twoWeeksAgo)) {
                  achievements.add(ActivityEvent(
                    title: game.name,
                    description: ach['name'] ?? ach['apiname'] ?? 'Conquista Secreta',
                    timestamp: unlockTime,
                    type: ActivityEventType.achievement,
                    appId: game.appId,
                  ));
                }
              }
            }
          }
        }
      } catch (e) {
        print("Erro ao buscar conquistas para o jogo ${game.appId}: $e");
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
    return achievements;
  }

  /// Busca a lista de jogos jogados recentemente (últimas 2 semanas).
  Future<List<RecentlyPlayedGame>> _fetchRecentlyPlayedGames(String apiKey, String steamId) async {
    final url = Uri.parse('https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=$apiKey&steamid=$steamId&format=json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['response'];
        if (data.containsKey('total_count') && data['total_count'] > 0) {
          final List games = data['games'];
          return games.map((game) => RecentlyPlayedGame(
            appId: game['appid'],
            name: game['name'],
            playtime2WeeksMinutes: game['playtime_2weeks'],
            playtimeForeverMinutes: game['playtime_forever'],
          )).toList();
        }
      }
    } catch(e) {
      print("Erro ao buscar jogos recentes: $e");
    }
    return [];
  }

  /// Busca a lista completa de jogos do usuário.
  Future<List<dynamic>?> _getOwnedGames(String apiKey, String steamId) async {
    final url = Uri.parse('https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=$apiKey&steamid=$steamId&format=json&include_appinfo=1&include_played_free_games=1');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['response'] != null && data['response']['games'] != null) {
          return data['response']['games'];
        }
      }
    } catch (e) {
      print("Erro em _getOwnedGames: $e");
    }
    return null;
  }

  /// Busca os detalhes (gêneros) de um jogo específico.
  Future<List<String>> _getGameDetails(int appId) async {
    final url = Uri.parse('https://store.steampowered.com/api/appdetails?appids=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data[appId.toString()]['success'] == true) {
          final List genres = data[appId.toString()]['data']['genres'] ?? [];
          return genres.map((genre) => genre['description'] as String).toList();
        }
      }
    } catch (e) {
      // Silencia erros.
    }
    return [];
  }

  /// Calcula o arquétipo e outras métricas com base na lista de jogos.
  Future<PlayerArchetype> _calculateArchetype(List<dynamic> games) async {
    final int totalGames = games.length;
    final int totalPlaytimeMinutes = games.fold(0, (sum, game) => sum + (game['playtime_forever'] ?? 0) as int);
    final int totalPlaytimeHours = (totalPlaytimeMinutes / 60).round();

    Map<String, double> genrePlaytime = {};
    final significantGames = games.where((game) => (game['playtime_forever'] ?? 0) > 60).toList();

    if (significantGames.isEmpty) {
        throw Exception('Nenhum jogo com mais de 1h de jogo encontrado para análise.');
    }
    
    for (var game in significantGames) {
      final appId = game['appid'];
      final playtime = (game['playtime_forever'] as int).toDouble();
      final genres = await _getGameDetails(appId);
      for (var genre in genres) {
        genrePlaytime[genre] = (genrePlaytime[genre] ?? 0) + playtime;
      }
      await Future.delayed(const Duration(milliseconds: 800)); 
    }

    if (genrePlaytime.isEmpty) {
      throw Exception('Nenhum dado de gênero encontrado após analisar os jogos.');
    }

    final double totalGenrePlaytimeMinutes = genrePlaytime.values.fold(0.0, (sum, item) => sum + item);
    final double totalGenrePlaytimeHours = totalGenrePlaytimeMinutes / 60;

    final sortedGenres = genrePlaytime.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final topGenre = sortedGenres.first.key;
    String archetype = "Jogador Versátil";

    if (["RPG", "Adventure"].contains(topGenre)) {
      archetype = "Explorador de Mundos";
    } else if (["Strategy", "Simulation"].contains(topGenre)) {
      archetype = "Mestre Estrategista";
    } else if (["Action", "Free to Play", "Massively Multiplayer"].contains(topGenre)) {
      archetype = "Competidor Nato";
    } else if (["Indie", "Casual"].contains(topGenre)) {
      archetype = "Aventureiro Indie";
    }
    
    // Pega os 5 primeiros gêneros em vez de 3
    final top5 = Map.fromEntries(sortedGenres.take(5).map((e) => MapEntry(e.key, (e.value / 60))));

    return PlayerArchetype(
      usuarioId: _steamId,
      arquetipoSugerido: archetype,
      generoPrincipal: topGenre,
      horasNoGeneroPrincipal: (sortedGenres.first.value / 60),
      topGenres: top5,
      totalGames: totalGames,
      totalPlaytimeHours: totalPlaytimeHours,
      totalGenrePlaytimeHours: totalGenrePlaytimeHours,
    );
  }
}