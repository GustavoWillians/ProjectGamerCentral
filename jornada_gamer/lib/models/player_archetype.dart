// lib/models/player_archetype.dart

class PlayerArchetype {
  final String usuarioId;
  final String arquetipoSugerido;
  final String generoPrincipal;
  final double horasNoGeneroPrincipal;
  final Map<String, double> topGenres; // RENOMEADO de top3Generos
  final int totalGames;
  final int totalPlaytimeHours;
  final double totalGenrePlaytimeHours;

  PlayerArchetype({
    required this.usuarioId,
    required this.arquetipoSugerido,
    required this.generoPrincipal,
    required this.horasNoGeneroPrincipal,
    required this.topGenres, // RENOMEADO de top3Generos
    required this.totalGames,
    required this.totalPlaytimeHours,
    required this.totalGenrePlaytimeHours,
  });
}