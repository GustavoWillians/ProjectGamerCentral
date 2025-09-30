// lib/services/steam_api_service.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Importa a nova biblioteca
import 'package:http/http.dart' as http;
import '../models/achievement.dart';
import '../models/activity_event.dart';
import '../models/dashboard_data.dart';
import '../models/game_info.dart';
import '../models/player_archetype.dart';
import '../models/recently_played_game.dart';

class SteamApiService {
  // --- A CORREÇÃO ESTÁ AQUI ---
  // Em vez de 'final String', usamos 'String get' e '=>'.
  // Isso garante que a variável só seja lida quando for usada,
  // e não na criação da classe.
  String get _steamApiKey => dotenv.env['STEAM_API_KEY'] ?? 'CHAVE_PADRAO';
  String get _steamId => dotenv.env['STEAM_ID'] ?? 'ID_PADRAO';
  String get _rawgApiKey => dotenv.env['RAWG_API_KEY'] ?? 'CHAVE_PADRAO';
  // --- FIM DA CORREÇÃO ---

  final Set<String> _tagsToIgnore = {
    'Singleplayer', 'Multiplayer', 'Steam Achievements', 'Full controller support',
    'Steam Cloud', 'steam-trading-cards', 'Co-op', 'Online Co-Op', 'Family Sharing',
    'controller support', 'overlay', 'Online multiplayer', 'In-App Purchases', 'Stats',
    'Family Friendly', 'Replay Value'
  };

  /// Função principal que nosso app vai chamar para buscar todos os dados do dashboard.
  Future<DashboardData> fetchDashboardData() async {
    final ownedGamesRaw = await _getOwnedGames(_steamApiKey, _steamId) ?? [];
    if (ownedGamesRaw.isEmpty) {
      throw Exception('Não foi possível buscar a lista de jogos. O perfil pode ser privado.');
    }
    
    final allGames = ownedGamesRaw.map((game) => GameInfo(
      appId: game['appid'],
      name: game['name'] ?? 'Nome Indisponível',
      playtimeMinutes: game['playtime_forever'] ?? 0,
    )).toList()
    ..sort((a, b) => b.playtimeMinutes.compareTo(a.playtimeMinutes));

    final recentlyPlayedGames = await _fetchRecentlyPlayedGames(_steamApiKey, _steamId);
    
    double totalMasteryScore = 0;
    int gamesForMasteryCount = 0;
    final top5Games = allGames.take(5);

    for (final game in top5Games) {
      try {
        final score = await calculateMasteryIndexForGame(game);
        totalMasteryScore += score;
        gamesForMasteryCount++;
      } catch (e) {
        print("Não foi possível calcular a Maestria para o jogo ${game.name}: $e");
      }
    }
    
    final double generalMasteryIndex = gamesForMasteryCount > 0
        ? totalMasteryScore / gamesForMasteryCount
        : 0.0;

    final Map<int, int> lastPlayedTimestampMap = {
      for (var game in ownedGamesRaw) game['appid']: game['rtime_last_played'] ?? 0
    };

    final results = await Future.wait([
      _calculateArchetype(ownedGamesRaw),
      _fetchRecentAchievements(recentlyPlayedGames, _steamApiKey, _steamId),
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

    return DashboardData(
      archetype: archetype,
      allGames: allGames,
      recentActivity: allActivities,
      generalMasteryIndex: generalMasteryIndex,
    );
  }
  
  /// Calcula o Índice de Maestria para um único jogo sob demanda.
  Future<double> calculateMasteryIndexForGame(GameInfo game) async {
    final results = await Future.wait([
      fetchAchievementsForGame(game.appId),
      _fetchAchievementRarity(game.appId),
      _fetchGameDetailsFromRawgByName(game.name),
    ]);

    final userAchievements = results[0] as List<Achievement>;
    final globalRarities = results[1] as Map<String, double>;
    final rawgDetails = results[2] as Map<String, dynamic>;

    final double userPlaytime = game.playtimeMinutes / 60.0;
    final int averagePlaytime = rawgDetails['playtime'] ?? 30;

    double difficultyScore = 0;
    bool hasAchievements = userAchievements.isNotEmpty;

    if (hasAchievements) {
      double totalRarity = 0;
      int unlockedCount = 0;
      for (var ach in userAchievements) {
        if (ach.isAchieved && globalRarities.containsKey(ach.apiName)) {
          totalRarity += globalRarities[ach.apiName]!;
          unlockedCount++;
        }
      }
      if (unlockedCount > 0) {
        double averageRarity = totalRarity / unlockedCount;
        difficultyScore = (100 - averageRarity);
      }
    }

    double effortScore = 0;
    if (averagePlaytime > 0) {
      double effortRatio = userPlaytime / averagePlaytime;
      effortScore = min(effortRatio * 100, 100.0);
    }
    
    double finalScore;
    if (hasAchievements) {
      finalScore = (difficultyScore + effortScore) / 2;
    } else {
      finalScore = effortScore;
    }

    return min(finalScore, 100.0);
  }

  /// Busca as conquistas do usuário para um único jogo.
  Future<List<Achievement>> fetchAchievementsForGame(int appId) async {
    final url = Uri.parse('https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=$appId&key=$_steamApiKey&steamid=$_steamId&l=brazilian');
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

  /// Busca os detalhes (gêneros e categorias) de um jogo específico na API da Steam.
  Future<Map<String, List<String>>> _getGameDetails(int appId) async {
    final url = Uri.parse('https://store.steampowered.com/api/appdetails?appids=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body) as Map<String, dynamic>;
        final appData = decodedData[appId.toString()] as Map<String, dynamic>?;
        if (appData != null && appData['success'] == true) {
          final gameData = appData['data'] as Map<String, dynamic>? ?? {};
          List<String> genres = [];
          if (gameData.containsKey('genres')) {
            genres = (gameData['genres'] as List).map((g) => g['description'].toString()).toList();
          }
          List<String> tags = [];
          if (gameData.containsKey('categories')) {
            tags = (gameData['categories'] as List).map((c) => c['description'].toString()).toList();
          }
          return {'genres': genres, 'tags': tags};
        }
      }
    } catch (e) { /* Silencia erros */ }
    return {'genres': [], 'tags': []};
  }
  
  /// Busca detalhes (incluindo tags) de um jogo na API da RAWG pelo nome.
  Future<Map<String, dynamic>> _fetchGameDetailsFromRawgByName(String gameName) async {
    if (gameName.isEmpty) return {};
    final url = Uri.parse('https://api.rawg.io/api/games?key=$_rawgApiKey&search=${Uri.encodeComponent(gameName)}&search_exact=true');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          return data['results'][0] as Map<String, dynamic>;
        }
      }
    } catch (e) {
      print("Erro ao buscar detalhes do jogo '$gameName' na RAWG: $e");
    }
    return {};
  }
  
  /// Busca a raridade global das conquistas de um jogo.
  Future<Map<String, double>> _fetchAchievementRarity(int appId) async {
    final url = Uri.parse('https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['achievementpercentages']['achievements'] as List;
        return {
          for (var ach in data)
            ach['name']: double.tryParse(ach['percent'].toString()) ?? 0.0
        };
      }
    } catch (e) {
      print("Erro ao buscar raridade das conquistas: $e");
    }
    return {};
  }

  /// Calcula o arquétipo (VERSÃO 2.0) usando gêneros (Steam) e tags (RAWG).
  Future<PlayerArchetype> _calculateArchetype(List<dynamic> games) async {
    final int totalGames = games.length;
    final int totalPlaytimeMinutes = games.fold(0, (sum, game) => sum + (game['playtime_forever'] ?? 0) as int);
    final int totalPlaytimeHours = (totalPlaytimeMinutes / 60).round();

    Map<String, double> genrePlaytime = {};
    Map<String, double> tagPlaytime = {};
    final significantGames = games.where((game) => (game['playtime_forever'] ?? 0) > 60).toList();

    if (significantGames.isEmpty) {
        throw Exception('Nenhum jogo com mais de 1h de jogo encontrado para análise.');
    }
    
    for (var game in significantGames) {
      final appId = game['appid'];
      final gameName = game['name'] ?? '';
      final playtime = (game['playtime_forever'] as int).toDouble();

      final detailsResults = await Future.wait([
        _getGameDetails(appId),
        _fetchGameDetailsFromRawgByName(gameName), // Usando a busca por nome
      ]);

      final genres = (detailsResults[0] as Map<String, List<String>>)['genres']!;
      final rawgData = detailsResults[1];
      final List rawgTagsRaw = rawgData['tags'] ?? [];
      final tags = rawgTagsRaw.map((t) => t['name'].toString()).where((t) => !_tagsToIgnore.contains(t)).toList();

      for (var genre in genres) {
        genrePlaytime[genre] = (genrePlaytime[genre] ?? 0) + playtime;
      }
      for (var tag in tags) {
        tagPlaytime[tag] = (tagPlaytime[tag] ?? 0) + playtime;
      }
      
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (genrePlaytime.isEmpty) {
      throw Exception('Nenhum dado de gênero encontrado após analisar os jogos.');
    }
    
    final double totalGenrePlaytimeMinutes = genrePlaytime.values.fold(0.0, (sum, item) => sum + item);
    final double totalGenrePlaytimeHours = totalGenrePlaytimeMinutes / 60;

    final sortedGenres = genrePlaytime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagPlaytime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final topGenre = sortedGenres.first.key;
    final topTag = sortedTags.isNotEmpty ? sortedTags.first.key : '';

    String archetype = "Jogador Versátil";

    if (topGenre == 'RPG') {
      if (topTag == 'Open World') archetype = 'Explorador de Mundos Abertos';
      else if (topTag == 'Story Rich') archetype = 'Contador de Histórias Interativas';
      else archetype = 'Aventureiro de RPG';
    } else if (topGenre == 'Strategy') {
      if (topTag == 'Grand Strategy') archetype = 'Grande Estrategista';
      else if (topTag == 'City Builder') archetype = 'Arquiteto de Civilizações';
      else archetype = 'Mestre Tático';
    } else if (topGenre == 'Indie') {
      if (topTag == 'Pixel Graphics') archetype = 'Nostálgico Pixelado';
      else if (topTag == 'Roguelike') archetype = 'Mestre da Adaptação';
      else archetype = 'Curador Independente';
    } else if (topGenre == 'Simulation') {
        if (topTag == 'Survival' || topTag == 'Crafting') archetype = 'Engenheiro Sobrevivente';
        else archetype = 'Virtualizador de Realidades';
    }
    
    final top5Genres = Map.fromEntries(sortedGenres.take(5).map((e) => MapEntry(e.key, (e.value / 60))));

    return PlayerArchetype(
      usuarioId: _steamId,
      arquetipoSugerido: archetype,
      generoPrincipal: topGenre,
      horasNoGeneroPrincipal: (sortedGenres.first.value / 60),
      topGenres: top5Genres,
      totalGames: totalGames,
      totalPlaytimeHours: totalPlaytimeHours,
      totalGenrePlaytimeHours: totalGenrePlaytimeHours,
    );
  }
}