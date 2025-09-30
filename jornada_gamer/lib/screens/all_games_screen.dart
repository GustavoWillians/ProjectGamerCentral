// lib/screens/all_games_screen.dart
import 'package:flutter/material.dart';
import '../models/game_info.dart';

class AllGamesScreen extends StatelessWidget {
  final List<GameInfo> allGames;

  const AllGamesScreen({super.key, required this.allGames});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Biblioteca de Jogos (${allGames.length})'),
      ),
      body: ListView.builder(
        itemCount: allGames.length,
        itemBuilder: (context, index) {
          final game = allGames[index];
          final hoursPlayed = (game.playtimeMinutes / 60).toStringAsFixed(1);
          final imageUrl = 'https://cdn.akamai.steamstatic.com/steam/apps/${game.appId}/header.jpg';

          return ListTile(
            leading: SizedBox(
              width: 120,
              child: Image.network(
                imageUrl,
                // AQUI ESTÁ A MUDANÇA: de BoxFit.cover para BoxFit.contain
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(child: CircularProgressIndicator(strokeWidth: 2.0));
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.image_not_supported, color: Colors.white54);
                },
              ),
            ),
            title: Text(game.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${hoursPlayed}h jogadas',
              style: const TextStyle(color: Color(0xFFA0A0A0)),
            ),
          );
        },
      ),
    );
  }
}