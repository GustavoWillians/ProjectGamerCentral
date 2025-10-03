// lib/widgets/game_timeline_card.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/achievement.dart';
import '../models/game_info.dart';
import '../models/milestone.dart';
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
  bool _isLoadingAchievements = false;
  bool _showAllAchievements = false;
  List<Achievement> _achievements = [];
  bool _isCalculatingMastery = false;
  double? _masteryIndex;

  Future<void> _fetchAchievements() async {
    if (_achievements.isNotEmpty) return;
    if (!mounted) return;
    setState(() => _isLoadingAchievements = true);

    final apiService = SteamApiService();
    final achievements = await apiService.fetchAchievementsForGame(widget.game.appId);

    if (mounted) {
      setState(() {
        _achievements = achievements;
        _isLoadingAchievements = false;
      });
    }
  }

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

  void _pinAchievement(Achievement ach) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final newMilestone = Milestone(
      title: ach.displayName,
      subtitle: 'Conquista Desbloqueada',
      gameName: widget.game.name,
      type: MilestoneType.achievement,
      timestamp: ach.unlockTime,
    );

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('milestones')
          .add({
        'title': newMilestone.title,
        'subtitle': newMilestone.subtitle,
        'gameName': newMilestone.gameName,
        'type': newMilestone.type.toString(),
        'timestamp': newMilestone.timestamp,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${ach.displayName}" fixado no seu Mural!'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fixar o marco: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _calculateMastery() async {
    if (!mounted) return;
    setState(() => _isCalculatingMastery = true);

    final apiService = SteamApiService();
    final score = await apiService.calculateMasteryIndexForGame(widget.game);

    if (mounted) {
      setState(() {
        _masteryIndex = score;
        _isCalculatingMastery = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryTextColor = const Color(0xFFA0A0A0);
    final hoursPlayed = (widget.game.playtimeMinutes / 60).toStringAsFixed(1);
    final achievementsToShow = _showAllAchievements ? _achievements : _achievements.take(5).toList();
    final imageUrl = 'https://cdn.akamai.steamstatic.com/steam/apps/${widget.game.appId}/header.jpg';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(
              imageUrl,
              height: 150,
              width: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.black,
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white24, size: 40),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('#${widget.rank} Mais Jogado', style: TextStyle(fontSize: 12, color: primaryColor, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(widget.game.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('$hoursPlayed horas de dedicação', style: TextStyle(color: secondaryTextColor, fontSize: 14)),
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30), alignment: Alignment.centerLeft),
                    onPressed: () {
                      setState(() => _isExpanded = !_isExpanded);
                      if (_isExpanded) _fetchAchievements();
                    },
                    child: Text(
                      _isExpanded ? 'Ocultar conquistas' : 'Mostrar conquistas...',
                      style: TextStyle(color: primaryColor, fontSize: 12),
                    ),
                  ),
                  if (_isExpanded)
                    _isLoadingAchievements
                        ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                        : _achievements.isEmpty
                            ? Text('Nenhuma conquista desbloqueada encontrada.', style: TextStyle(color: secondaryTextColor))
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...achievementsToShow.map((ach) {
                                    return InkWell(
                                      onTap: () => _showAchievementDescription(context, ach),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                                        child: Row(
                                          children: [
                                            Icon(Icons.military_tech, size: 20, color: primaryColor),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(ach.displayName, style: const TextStyle(color: Colors.white)),
                                                  Text(
                                                    DateFormat('dd/MM/yyyy HH:mm').format(ach.unlockTime!),
                                                    style: TextStyle(color: secondaryTextColor, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.push_pin_outlined, color: Color(0xFFA0A0A0)),
                                              onPressed: () => _pinAchievement(ach),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  if (_achievements.length > 5)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: TextButton(
                                        child: Text(_showAllAchievements ? 'Ver menos...' : 'Ver mais...', style: TextStyle(color: primaryColor)),
                                        onPressed: () => setState(() => _showAllAchievements = !_showAllAchievements),
                                      ),
                                    ),
                                ],
                              ),
                  const Divider(height: 32, thickness: 1, color: Colors.white12),
                  _buildMasterySection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMasterySection() {
    if (_masteryIndex != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Índice de Maestria:', style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 14)),
          Text(
            _masteryIndex!.toStringAsFixed(1),
            style: TextStyle(fontFamily: 'Mona Sans', fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
          ),
        ],
      );
    } else if (_isCalculatingMastery) {
      return const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 8.0), child: CircularProgressIndicator()));
    } else {
      return Center(
        child: TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          ),
          onPressed: _calculateMastery,
          child: Text('Calcular Maestria', style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        ),
      );
    }
  }
}