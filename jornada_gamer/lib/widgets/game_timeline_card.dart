// lib/widgets/game_timeline_card.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Importa a nova biblioteca
import '../models/achievement.dart';
import '../models/game_info.dart';
import '../services/steam_api_service.dart';

class GameTimelineCard extends StatefulWidget {
  final GameInfo game;
  final int rank;

  const GameTimelineCard({super.key, required this.game, required this.rank});

  @override
  State<GameTimelineCard> createState() => _GameTimelineCardState();
}

class _GameTimelineCardState extends State<GameTimelineCard> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _showAllAchievements = false; // Novo estado para controlar a lista
  List<Achievement> _achievements = [];

  Future<void> _fetchAchievements() async {
    if (_achievements.isNotEmpty) return;
    setState(() => _isLoading = true);
    final apiService = SteamApiService();
    final achievements = await apiService.fetchAchievementsForGame(widget.game.appId);
    if (mounted) {
      setState(() {
        _achievements = achievements;
        _isLoading = false;
      });
    }
  }

  // Função para mostrar a descrição em um diálogo
  void _showAchievementDescription(BuildContext context, Achievement ach) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF181818),
        title: Text(ach.displayName, style: const TextStyle(color: Colors.white)),
        content: Text(ach.description, style: const TextStyle(color: Color(0xFFA0A0A0))),
        actions: [
          TextButton(
            child: Text('Fechar', style: TextStyle(color: Theme.of(context).primaryColor)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryTextColor = const Color(0xFFA0A0A0);
    final hoursPlayed = (widget.game.playtimeMinutes / 60).toStringAsFixed(1);
    final achievementsToShow = _showAllAchievements ? _achievements : _achievements.take(5).toList();

    return InkWell(
      onTap: () {
        setState(() => _isExpanded = !_isExpanded);
        if (_isExpanded) _fetchAchievements();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: const Color(0xFF181818),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informações principais do jogo
            Text('#${widget.rank} Mais Jogado', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(widget.game.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('$hoursPlayed horas de dedicação', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
            
            // Seção expansível de conquistas
            if (_isExpanded)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: _isLoading
                    ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                    : _achievements.isEmpty
                        ? Text('Nenhuma conquista desbloqueada encontrada.', style: TextStyle(color: secondaryTextColor))
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Lista de conquistas
                              ...achievementsToShow.map((ach) {
                                return ListTile(
                                  leading: Icon(Icons.military_tech, size: 20, color: primaryColor),
                                  title: Text(ach.displayName, style: const TextStyle(color: Colors.white)),
                                  subtitle: Text(
                                    // Formata a data e hora
                                    DateFormat('dd/MM/yyyy HH:mm').format(ach.unlockTime!),
                                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                  ),
                                  onTap: () => _showAchievementDescription(context, ach),
                                  contentPadding: EdgeInsets.zero,
                                );
                              }).toList(),

                              // Botão "Ver mais" / "Ver menos"
                              if (_achievements.length > 5)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: TextButton(
                                    child: Text(
                                      _showAllAchievements ? 'Ver menos...' : 'Ver mais...',
                                      style: TextStyle(color: primaryColor),
                                    ),
                                    onPressed: () => setState(() => _showAllAchievements = !_showAllAchievements),
                                  ),
                                ),
                            ],
                          ),
              ),
          ],
        ),
      ),
    );
  }
}