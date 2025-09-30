// lib/screens/timeline_screen.dart

import 'package:flutter/material.dart';
import 'package:timeline_tile/timeline_tile.dart';
import '../models/game_info.dart';
import '../widgets/game_timeline_card.dart'; // <<< A CORREÇÃO ESTÁ AQUI

class TimelineScreen extends StatelessWidget {
  final List<GameInfo> allGames;

  const TimelineScreen({super.key, required this.allGames});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Linha do Tempo de Dedicação'),
      ),
      body: ListView.builder(
        itemCount: allGames.length,
        itemBuilder: (context, index) {
          final game = allGames[index];
          
          return TimelineTile(
            alignment: TimelineAlign.manual,
            lineXY: 0.1,
            isFirst: index == 0,
            isLast: index == allGames.length - 1,
            indicatorStyle: IndicatorStyle(
              width: 20,
              color: Theme.of(context).primaryColor,
              padding: const EdgeInsets.all(6),
            ),
            beforeLineStyle: LineStyle(color: Theme.of(context).primaryColor.withOpacity(0.5), thickness: 2),
            afterLineStyle: LineStyle(color: Theme.of(context).primaryColor.withOpacity(0.5), thickness: 2),
            
            // Agora o Flutter sabe o que é GameTimelineCard
            endChild: GameTimelineCard(
              game: game,
              rank: index + 1,
            ),
          );
        },
      ),
    );
  }
}