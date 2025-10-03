// lib/models/player_archetype.dart

class PlayerArchetype {
  final String usuarioId;
  final String arquetipoSugerido;
  final String generoPrincipal;
  final double horasNoGeneroPrincipal;
  final Map<String, double> topGenres;
  final int totalGames;
  final int totalPlaytimeHours;
  final double totalGenrePlaytimeHours;
  final String topTag; // <-- NOVA PROPRIEDADE
  final double topTagHours; // <-- NOVA PROPRIEDADE

  PlayerArchetype({
    required this.usuarioId,
    required this.arquetipoSugerido,
    required this.generoPrincipal,
    required this.horasNoGeneroPrincipal,
    required this.topGenres,
    required this.totalGames,
    required this.totalPlaytimeHours,
    required this.totalGenrePlaytimeHours,
    required this.topTag, // <-- NOVA PROPRIEDADE
    required this.topTagHours, // <-- NOVA PROPRIEDADE
  });
}