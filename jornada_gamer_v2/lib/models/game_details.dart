// lib/models/game_details.dart

class GameDetails {
  final String description;
  final String developer;
  final String releaseDate;
  final int metacriticScore;
  final int averagePlaytime;
  final List<String> tags;

  GameDetails({
    required this.description,
    required this.developer,
    required this.releaseDate,
    required this.metacriticScore,
    required this.averagePlaytime,
    required this.tags,
  });

  // Lista de tags genéricas que queremos ignorar
  static const Set<String> _tagsToIgnore = {
    'Singleplayer', 'Multiplayer', 'Steam Achievements', 'Full controller support',
    'Steam Cloud', 'steam-trading-cards', 'Co-op', 'Online Co-Op', 'Family Sharing',
    'controller support', 'overlay', 'Online multiplayer', 'In-App Purchases', 'Stats',
    'Family Friendly', 'Replay Value', 'Partial Controller Support', 'Remote Play on Phone',
    'Remote Play on Tablet', 'Remote Play on TV', 'LAN Co-op', 'LAN PvP', 'Online PvP', 'PvP'
  };

  factory GameDetails.fromRawgJson(Map<String, dynamic> json) {
    // Lógica aprimorada para extrair o nome dos desenvolvedores
    String developerName = 'Não disponível';
    if (json['developers'] != null && (json['developers'] as List).isNotEmpty) {
      developerName = (json['developers'] as List).first['name'];
    }
    
    // CORREÇÃO: Filtra as tags para remover as genéricas
    List<String> tagNames = [];
    if (json['tags'] != null) {
      tagNames = (json['tags'] as List)
          .map((tag) => tag['name'] as String)
          .where((tagName) => !_tagsToIgnore.contains(tagName)) // Aplica o filtro
          .take(5) // Pega as 5 tags principais
          .toList();
    }

    return GameDetails(
      description: json['description_raw'] ?? 'Sem descrição disponível.',
      developer: developerName,
      releaseDate: json['released'] ?? 'Data desconhecida',
      metacriticScore: json['metacritic'] ?? 0,
      averagePlaytime: json['playtime'] ?? 0,
      tags: tagNames,
    );
  }
}