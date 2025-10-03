import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/achievement.dart';
import '../models/activity_event.dart';
import '../models/dashboard_data.dart';
import '../models/game_info.dart';
import '../models/insight.dart';
import '../models/player_archetype.dart';
import '../models/recently_played_game.dart';
import '../models/game_details.dart';

class SteamApiService {
  String get _steamApiKey => dotenv.env['STEAM_API_KEY'] ?? '';
  String get _rawgApiKey => dotenv.env['RAWG_API_KEY'] ?? '';

  Future<String> _getSteamIdForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Utilizador não autenticado.');

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final steamId = userDoc.data()?['steamId'];

    if (steamId == null || steamId.isEmpty)
      throw Exception('Steam ID não vinculado.');
    return steamId;
  }

  final Set<String> _tagsToIgnore = {
    'Singleplayer',
    'Multiplayer',
    'Steam Achievements',
    'Full controller support',
    'Steam Cloud',
    'steam-trading-cards',
    'Co-op',
    'Online Co-Op',
    'Family Sharing',
    'controller support',
    'overlay',
    'Online multiplayer',
    'In-App Purchases',
    'Stats',
    'Family Friendly',
    'Replay Value'
  };

  // NOVA FUNÇÃO PÚBLICA para buscar detalhes da RAWG de forma organizada
  Future<GameDetails> fetchGameDetailsFromRawg(String gameName) async {
    final rawgData = await _fetchGameDetailsFromRawgByName(gameName);
    if (rawgData.isEmpty) {
      throw Exception('Não foi possível encontrar detalhes do jogo na RAWG.');
    }
    return GameDetails.fromRawgJson(rawgData);
  }

  // TORNAMOS ESTA FUNÇÃO PÚBLICA para podermos usá-la na tela de detalhes
  Future<int> getTotalAchievementsForGame(int appId) async {
    final url = Uri.parse('https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v2/?key=$_steamApiKey&appid=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('game') && data['game'].containsKey('availableGameStats') && data['game']['availableGameStats'].containsKey('achievements')) {
          return (data['game']['availableGameStats']['achievements'] as List).length;
        }
      }
    } catch (e) {
      print("Erro ao buscar o esquema de conquistas para o jogo $appId: $e");
    }
    return 0;
  }

  // A função de gerar insights agora é PÚBLICA e reestruturada
  Future<List<Insight>> generateInsights(List<GameInfo> allGames, PlayerArchetype archetype, List<dynamic> ownedGamesRaw) async {
    List<Insight> finalInsights = [];

    // Lista de geradores de "Métricas Especiais"
    final List<Future<Insight?> Function()> specialGenerators = [
      () => _generateAboveAverageInsight(allGames),
      () => _generateEliteAchievementInsight(allGames),
      () => _generateGenreKingInsight(archetype),
      () => _generateDeveloperInsight(ownedGamesRaw),
      () => _generateSpecialistInsight(archetype),
    ];

    // Lista de geradores de "Métricas de Jogo"
    final List<Future<Insight?> Function()> gameGenerators = [
      () => _generateMarathonInsight(allGames),
      () => _generateAchievementHunterInsight(allGames),
      () => _generateArchaeologistInsight(allGames),
    ];

    specialGenerators.shuffle();
    gameGenerators.shuffle();

    // Tenta gerar uma métrica especial
    for (var generator in specialGenerators) {
      final insight = await generator();
      if (insight != null) {
        finalInsights.add(insight);
        break;
      }
    }
    
    // Tenta gerar uma métrica de jogo
    for (var generator in gameGenerators) {
      final insight = await generator();
      if (insight != null) {
        finalInsights.add(insight);
        break;
      }
    }
    
    return finalInsights;
  }

  /// Insight 1: Tempo de jogo acima da média.
  Future<Insight?> _generateAboveAverageInsight(List<GameInfo> allGames) async {
    if (allGames.isEmpty) return null;
    final randomGame = allGames[Random().nextInt(min(5, allGames.length))];
    final rawgDetails = await _fetchGameDetailsFromRawgByName(randomGame.name);
    final averagePlaytime = rawgDetails['playtime'] as int? ?? 0;
    final userPlaytime = randomGame.playtimeMinutes / 60;

    if (averagePlaytime > 0 && userPlaytime > averagePlaytime * 1.2) {
      final difference = userPlaytime - averagePlaytime;
      return Insight(
        title: 'ACIMA DA MÉDIA',
        description: 'Você dedicou ${difference.toStringAsFixed(0)} horas a mais que a média da comunidade em ${randomGame.name}!',
      );
    }
    return null;
  }

  /// Insight 2: A conquista mais rara.
  Future<Insight?> _generateEliteAchievementInsight(List<GameInfo> allGames) async {
    if (allGames.isEmpty) return null;
    final gameToAnalyze = allGames.first;
    final userAchievements = await fetchAchievementsForGame(gameToAnalyze.appId);
    final globalRarities = await _fetchAchievementRarity(gameToAnalyze.appId);
    Achievement? rarestAch;
    double minRarity = 101.0;

    for (var ach in userAchievements) {
      if (globalRarities.containsKey(ach.apiName)) {
        final rarity = globalRarities[ach.apiName]!;
        if (rarity < minRarity) {
          minRarity = rarity;
          rarestAch = ach;
        }
      }
    }

    if (rarestAch != null && minRarity < 50) {
      return Insight(
        title: 'CONQUISTA DE ELITE',
        description: 'A sua conquista mais rara é "${rarestAch.displayName}" em ${gameToAnalyze.name}, desbloqueada por apenas ${minRarity.toStringAsFixed(2)}% dos jogadores no mundo!',
      );
    }
    return null;
  }
  
  /// Insight 3: O domínio do género principal.
  Future<Insight?> _generateGenreKingInsight(PlayerArchetype archetype) async {
    final topGenre = archetype.generoPrincipal;
    final topGenreHours = archetype.horasNoGeneroPrincipal;
    final totalGenreHours = archetype.totalGenrePlaytimeHours;

    if (totalGenreHours > 0) {
      final percentage = (topGenreHours / totalGenreHours) * 100;
      return Insight(
        title: 'O REI DO GÉNERO',
        description: 'Como um ${archetype.arquetipoSugerido}, não é surpresa que o género "$topGenre" domine a sua jornada, ocupando ${percentage.toStringAsFixed(0)}% do seu tempo de jogo!',
      );
    }
    return null;
  }

  /// NOVO Insight 4: Preferência de Desenvolvedor.
  Future<Insight?> _generateDeveloperInsight(List<dynamic> ownedGamesRaw) async {
    Map<String, double> developerPlaytime = {};
    
    // Pega os 20 jogos mais jogados para a análise
    final topGames = (ownedGamesRaw..sort((a, b) => (b['playtime_forever'] ?? 0).compareTo(a['playtime_forever'] ?? 0))).take(20);

    for (var game in topGames) {
      final playtime = (game['playtime_forever'] as int? ?? 0).toDouble();
      if (playtime > 0) {
        final details = await _fetchGameDetailsFromRawgByName(game['name'] ?? '');
        final List developers = details['developers'] ?? [];
        if (developers.isNotEmpty) {
          final developerName = developers.first['name'];
          developerPlaytime[developerName] = (developerPlaytime[developerName] ?? 0) + playtime;
        }
      }
    }

    if (developerPlaytime.isNotEmpty) {
      final sortedDevelopers = developerPlaytime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final topDeveloper = sortedDevelopers.first;
      final totalHours = (topDeveloper.value / 60).toStringAsFixed(0);

      return Insight(
        title: 'SEU ESTÚDIO FAVORITO',
        description: 'O estúdio que você mais apoia é a ${topDeveloper.key}, com um total de ${totalHours} horas dedicadas aos seus jogos!',
      );
    }
    return null;
  }

  /// NOVO Insight 5: Comparação com Maratonas de Filmes.
  Future<Insight?> _generateMarathonInsight(List<GameInfo> allGames) async {
    if (allGames.isEmpty) return null;
    final mostPlayedGame = allGames.first;
    final hoursPlayed = mostPlayedGame.playtimeMinutes / 60;
    
    // Duração da trilogia "O Senhor dos Anéis" (versões estendidas) em horas.
    const double lotrMarathonHours = 11.4; 

    if (hoursPlayed > lotrMarathonHours * 2) { // Só mostra se for significativo
      final timesMarathoned = (hoursPlayed / lotrMarathonHours).toStringAsFixed(1);
      return Insight(
        title: 'ÉPICO É POUCO',
        description: 'As suas ${hoursPlayed.toStringAsFixed(0)} horas em ${mostPlayedGame.name} equivalem a maratonar a trilogia completa de "O Senhor dos Anéis" ${timesMarathoned} vezes!',
      );
    }
    return null;
  }

  /// NOVO Insight 6: Caçador de Conquistas.
  Future<Insight?> _generateAchievementHunterInsight(List<GameInfo> allGames) async {
    if (allGames.length < 5) return null;

    final randomGame = allGames[Random().nextInt(5)]; // Pega um jogo aleatório do Top 5
    final userAchievements = await fetchAchievementsForGame(randomGame.appId);
    final totalAchievements = await _getTotalAchievementsForGame(randomGame.appId);

    if (totalAchievements > 0 && userAchievements.isNotEmpty) {
      return Insight(
        title: 'CAÇADOR DE CONQUISTAS',
        description: 'Em ${randomGame.name}, você já é um verdadeiro caçador, com ${userAchievements.length} de $totalAchievements conquistas desbloqueadas!',
      );
    }
    return null;
  }

  // NOVA FUNÇÃO AUXILIAR para buscar o total de conquistas
  Future<int> _getTotalAchievementsForGame(int appId) async {
    final url = Uri.parse('https://api.steampowered.com/ISteamUserStats/GetSchemaForGame/v2/?key=$_steamApiKey&appid=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.containsKey('game') && data['game'].containsKey('availableGameStats') && data['game']['availableGameStats'].containsKey('achievements')) {
          return (data['game']['availableGameStats']['achievements'] as List).length;
        }
      }
    } catch (e) {
      print("Erro ao buscar o esquema de conquistas para o jogo $appId: $e");
    }
    return 0;
  }

   /// NOVO Insight 7: Especialista em...
  Future<Insight?> _generateSpecialistInsight(PlayerArchetype archetype) async {
    if (archetype.topTag.isNotEmpty) {
      return Insight(
        title: 'ESPECIALISTA EM...',
        description: 'Você é um verdadeiro perito em jogos de "${archetype.topTag}", com mais de ${archetype.topTagHours.toStringAsFixed(0)} horas dedicadas a este estilo!',
      );
    }
    return null;
  }

  /// NOVO Insight 8: O Arqueólogo Gamer.
  Future<Insight?> _generateArchaeologistInsight(List<GameInfo> allGames) async {
    GameInfo? oldestGame;
    DateTime? oldestDate;

    // Pega os 20 jogos mais jogados para a análise
    final topGames = allGames.take(20);

    for (var game in topGames) {
      final details = await _fetchGameDetailsFromRawgByName(game.name);
      final releaseDateString = details['released'] as String?;
      
      if (releaseDateString != null) {
        final releaseDate = DateTime.tryParse(releaseDateString);
        if (releaseDate != null) {
          if (oldestDate == null || releaseDate.isBefore(oldestDate)) {
            oldestDate = releaseDate;
            oldestGame = game;
          }
        }
      }
    }

    if (oldestGame != null && oldestDate != null) {
      return Insight(
        title: 'ARQUEÓLOGO GAMER',
        description: 'Uma viagem no tempo! O jogo mais antigo da sua jornada é ${oldestGame.name}, lançado em ${oldestDate.year}.',
      );
    }
    return null;
  }

  /// NOVO Insight 9: Na Vanguarda.
  Future<Insight?> _generateOnTheForefrontInsight(List<GameInfo> allGames) async {
    if (allGames.length < 5) return null;

    final randomGame = allGames[Random().nextInt(5)];
    final userAchievements = await fetchAchievementsForGame(randomGame.appId);

    if (userAchievements.isEmpty) return null;

    // A lista de conquistas já vem ordenada da mais recente para a mais antiga.
    // A última da lista é a primeira que foi desbloqueada.
    final firstAchievement = userAchievements.last;
    final firstPlayedDate = firstAchievement.unlockTime;

    if (firstPlayedDate == null) return null;

    final details = await _fetchGameDetailsFromRawgByName(randomGame.name);
    final releaseDateString = details['released'] as String?;
    if (releaseDateString == null) return null;

    final releaseDate = DateTime.tryParse(releaseDateString);
    if (releaseDate == null) return null;

    final difference = firstPlayedDate.difference(releaseDate).inDays;

    // Só mostra o insight se o jogador começou a jogar nos primeiros 30 dias.
    if (difference >= 0 && difference <= 30) {
      return Insight(
        title: 'NA VANGUARDA',
        description: 'Sempre em cima do acontecimento! Você começou a jogar ${randomGame.name} apenas $difference dias após o seu lançamento mundial.',
      );
    }

    return null;
  }


  /// Função principal que nosso app vai chamar para buscar todos os dados do dashboard.
  Future<DashboardData> fetchDashboardData() async {
    final steamId = await _getSteamIdForCurrentUser();
    final ownedGamesRaw = await _getOwnedGames(_steamApiKey, steamId) ?? [];
    if (ownedGamesRaw.isEmpty)
      throw Exception('Não foi possível buscar a lista de jogos.');

    final allGames = ownedGamesRaw
        .map((game) => GameInfo(
              appId: game['appid'],
              name: game['name'] ?? 'Nome Indisponível',
              playtimeMinutes: game['playtime_forever'] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.playtimeMinutes.compareTo(a.playtimeMinutes));

    final recentlyPlayedGames =
        await _fetchRecentlyPlayedGames(_steamApiKey, steamId);

    double totalMasteryScore = 0;
    int gamesForMasteryCount = 0;
    final top5Games = allGames.take(5);

    for (final game in top5Games) {
      try {
        final score = await calculateMasteryIndexForGame(game);
        totalMasteryScore += score;
        gamesForMasteryCount++;
      } catch (e) {
        print(
            "Não foi possível calcular a Maestria para o jogo ${game.name}: $e");
      }
    }

    final double generalMasteryIndex = gamesForMasteryCount > 0
        ? totalMasteryScore / gamesForMasteryCount
        : 0.0;

    final Map<int, int> lastPlayedTimestampMap = {
      for (var game in ownedGamesRaw)
        game['appid']: game['rtime_last_played'] ?? 0
    };

    final results = await Future.wait([
      _calculateArchetype(ownedGamesRaw, steamId),
      _fetchRecentAchievements(recentlyPlayedGames, _steamApiKey, steamId),
    ]);

    final archetype = results[0] as PlayerArchetype;
    final recentAchievements = results[1] as List<ActivityEvent>;

    final insights = await generateInsights(allGames, archetype, ownedGamesRaw);

    final playedEvents = recentlyPlayedGames.map((game) {
      final hours = (game.playtime2WeeksMinutes / 60).toStringAsFixed(1);
      final lastPlayedTimestamp = lastPlayedTimestampMap[game.appId] ?? 0;
      return ActivityEvent(
        title: game.name,
        description: 'Jogou por ${hours}h',
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(lastPlayedTimestamp * 1000),
        type: ActivityEventType.played,
        appId: game.appId,
      );
    }).toList();

    final allActivities = [...recentAchievements, ...playedEvents]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return DashboardData(
      archetype: archetype,
      allGames: allGames,
      ownedGamesRaw: ownedGamesRaw, // Adiciona os dados brutos ao pacote
      recentActivity: allActivities,
      generalMasteryIndex: generalMasteryIndex,
      insights: insights,
    );
  }

  /// Calcula o Índice de Maestria para um único jogo sob demanda.
  Future<double> calculateMasteryIndexForGame(GameInfo game) async {
    final steamId = await _getSteamIdForCurrentUser();
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
    final steamId = await _getSteamIdForCurrentUser();
    final url = Uri.parse(
        'https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=$appId&key=$_steamApiKey&steamid=$steamId&l=brazilian');
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
                unlockTime: DateTime.fromMillisecondsSinceEpoch(
                    ach['unlocktime'] * 1000),
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
  Future<List<ActivityEvent>> _fetchRecentAchievements(
      List<RecentlyPlayedGame> recentGames,
      String apiKey,
      String steamId) async {
    List<ActivityEvent> achievements = [];
    final twoWeeksAgo = DateTime.now().subtract(const Duration(days: 14));

    for (final game in recentGames) {
      final url = Uri.parse(
          'https://api.steampowered.com/ISteamUserStats/GetPlayerAchievements/v0001/?appid=${game.appId}&key=$apiKey&steamid=$steamId');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body)['playerstats'];
          if (data.containsKey('achievements') && data['success'] == true) {
            final List gameAchievements = data['achievements'];
            for (final ach in gameAchievements) {
              if (ach['achieved'] == 1) {
                final unlockTime = DateTime.fromMillisecondsSinceEpoch(
                    ach['unlocktime'] * 1000);
                if (unlockTime.isAfter(twoWeeksAgo)) {
                  achievements.add(ActivityEvent(
                    title: game.name,
                    description:
                        ach['name'] ?? ach['apiname'] ?? 'Conquista Secreta',
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
  Future<List<RecentlyPlayedGame>> _fetchRecentlyPlayedGames(
      String apiKey, String steamId) async {
    final url = Uri.parse(
        'https://api.steampowered.com/IPlayerService/GetRecentlyPlayedGames/v0001/?key=$apiKey&steamid=$steamId&format=json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['response'];
        if (data.containsKey('total_count') && data['total_count'] > 0) {
          final List games = data['games'];
          return games
              .map((game) => RecentlyPlayedGame(
                    appId: game['appid'],
                    name: game['name'],
                    playtime2WeeksMinutes: game['playtime_2weeks'],
                    playtimeForeverMinutes: game['playtime_forever'],
                  ))
              .toList();
        }
      }
    } catch (e) {
      print("Erro ao buscar jogos recentes: $e");
    }
    return [];
  }

  /// Busca a lista completa de jogos do usuário.
  Future<List<dynamic>?> _getOwnedGames(String apiKey, String steamId) async {
    final url = Uri.parse(
        'https://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?key=$apiKey&steamid=$steamId&format=json&include_appinfo=1&include_played_free_games=1');
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
    final url = Uri.parse(
        'https://store.steampowered.com/api/appdetails?appids=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body) as Map<String, dynamic>;
        final appData = decodedData[appId.toString()] as Map<String, dynamic>?;
        if (appData != null && appData['success'] == true) {
          final gameData = appData['data'] as Map<String, dynamic>? ?? {};
          List<String> genres = [];
          if (gameData.containsKey('genres')) {
            genres = (gameData['genres'] as List)
                .map((g) => g['description'].toString())
                .toList();
          }
          List<String> tags = [];
          if (gameData.containsKey('categories')) {
            tags = (gameData['categories'] as List)
                .map((c) => c['description'].toString())
                .toList();
          }
          return {'genres': genres, 'tags': tags};
        }
      }
    } catch (e) {/* Silencia erros */}
    return {'genres': [], 'tags': []};
  }

  Future<Map<String, dynamic>> _fetchGameDetailsFromRawgByName(String gameName) async {
    if (gameName.isEmpty) return {};
    
    // 1ª Chamada: Busca para encontrar o 'slug' do jogo
    final searchUrl = Uri.parse('https://api.rawg.io/api/games?key=$_rawgApiKey&search=${Uri.encodeComponent(gameName)}');
    try {
      final searchResponse = await http.get(searchUrl);
      if (searchResponse.statusCode == 200) {
        final searchData = json.decode(searchResponse.body);
        if (searchData['results'] != null && (searchData['results'] as List).isNotEmpty) {
          final gameSlug = searchData['results'][0]['slug'] as String;

          // 2ª Chamada: Usa o 'slug' para obter os detalhes completos (mais fiável)
          final detailsUrl = Uri.parse('https://api.rawg.io/api/games/$gameSlug?key=$_rawgApiKey');
          final detailsResponse = await http.get(detailsUrl);
          if (detailsResponse.statusCode == 200) {
            return json.decode(detailsResponse.body) as Map<String, dynamic>;
          }
        }
      }
    } catch (e) {
      print("Erro ao buscar detalhes do jogo '$gameName' na RAWG: $e");
    }
    return {};
  }

  /// Busca a raridade global das conquistas de um jogo.
  Future<Map<String, double>> _fetchAchievementRarity(int appId) async {
    final url = Uri.parse(
        'https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=$appId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body)['achievementpercentages']
            ['achievements'] as List;
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

  /// Calcula o arquétipo (VERSÃO 2.1) guardando também a tag principal.
  Future<PlayerArchetype> _calculateArchetype(List<dynamic> games, String steamId) async {
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
        _fetchGameDetailsFromRawgByName(gameName),
      ]);

      final genres = (detailsResults[0] as Map<String, List<String>>)['genres']!;
      final rawgData = detailsResults[1] as Map<String, dynamic>;
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
      throw Exception('Nenhum dado de género encontrado após analisar os jogos.');
    }
    
    final double totalGenrePlaytimeMinutes = genrePlaytime.values.fold(0.0, (sum, item) => sum + item);
    final double totalGenrePlaytimeHours = totalGenrePlaytimeMinutes / 60;

    final sortedGenres = genrePlaytime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagPlaytime.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final topGenre = sortedGenres.first.key;
    final topTagEntry = sortedTags.isNotEmpty ? sortedTags.first : null;
    final topTag = topTagEntry?.key ?? '';
    final topTagHours = (topTagEntry?.value ?? 0) / 60;

    String archetype = "Jogador Versátil";

    // ... (lógica de classificação do arquétipo não muda)
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
      usuarioId: steamId,
      arquetipoSugerido: archetype,
      generoPrincipal: topGenre,
      horasNoGeneroPrincipal: (sortedGenres.first.value / 60),
      topGenres: top5Genres,
      totalGames: totalGames,
      totalPlaytimeHours: totalPlaytimeHours,
      totalGenrePlaytimeHours: totalGenrePlaytimeHours,
      topTag: topTag, // Guarda a tag principal
      topTagHours: topTagHours, // Guarda as horas da tag principal
    );
  }
}
