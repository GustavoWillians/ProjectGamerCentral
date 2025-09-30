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

          return ListTile(
            title: Text(game.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${hoursPlayed}h jogadas',
              style: const TextStyle(color: Color(0xFFA0A0A0)),
            ),
            // Ícone de placeholder para a imagem do jogo
            leading: Icon(Icons.videogame_asset_outlined, color: Theme.of(context).primaryColor),
          );
        },
      ),
    );
  }
}