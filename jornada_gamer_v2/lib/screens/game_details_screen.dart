// lib/screens/game_details_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/achievement.dart';
import '../models/game_details.dart';
import '../models/game_info.dart';
import '../services/steam_api_service.dart';

class GameDetailsScreen extends StatefulWidget {
  final GameInfo game;

  const GameDetailsScreen({super.key, required this.game});

  @override
  State<GameDetailsScreen> createState() => _GameDetailsScreenState();
}

class _GameDetailsScreenState extends State<GameDetailsScreen> {
  final _apiService = SteamApiService();
  bool _isLoading = true;

  // Variáveis de estado para guardar os dados buscados
  GameDetails? _details;
  List<Achievement> _userAchievements = [];
  int _totalAchievements = 0;
  double? _masteryIndex;

  @override
  void initState() {
    super.initState();
    _loadGameData();
  }

  Future<void> _loadGameData() async {
    try {
      // Busca todos os dados em paralelo
      final results = await Future.wait([
        _apiService.fetchGameDetailsFromRawg(widget.game.name),
        _apiService.fetchAchievementsForGame(widget.game.appId),
        _apiService.getTotalAchievementsForGame(widget.game.appId),
      ]);

      if (mounted) {
        setState(() {
          _details = results[0] as GameDetails;
          _userAchievements = results[1] as List<Achievement>;
          _totalAchievements = results[2] as int;
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Erro ao carregar dados do jogo: $e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao carregar os detalhes do jogo.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _calculateMastery() async {
    setState(() => _isLoading = true); // Reutiliza o loading principal
    final score = await _apiService.calculateMasteryIndexForGame(widget.game);
    if (mounted) {
      setState(() {
        _masteryIndex = score;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroImageUrl = 'https://cdn.akamai.steamstatic.com/steam/apps/${widget.game.appId}/library_hero.jpg';
    final hoursPlayed = (widget.game.playtimeMinutes / 60).toStringAsFixed(1);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.game.name),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com a imagem do jogo
                  Image.network(
                    heroImageUrl,
                    width: double.infinity,
                    height: 240,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(height: 240, color: Colors.black26, child: const Center(child: Icon(Icons.hide_image, color: Colors.white24, size: 50))),
                  ),
                  
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Secção de Métricas Pessoais
                        _buildMetricsSection(hoursPlayed),
                        const Divider(height: 32, color: Colors.white12),

                        // Secção de Informações Gerais
                        const Text('Sobre o Jogo', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 16),
                        _buildInfoTile('Desenvolvedor', _details?.developer ?? '...'),
                        _buildInfoTile('Data de Lançamento', _details != null ? DateFormat('dd/MM/yyyy').format(DateTime.parse(_details!.releaseDate)) : '...'),
                        _buildInfoTile('Nota (Metacritic)', _details?.metacriticScore.toString() ?? '...'),
                        if (_details?.tags.isNotEmpty ?? false)
                           _buildInfoTile('Tags', _details!.tags.join(', ')),

                        const Divider(height: 32, color: Colors.white12),
                        const Text('Plataforma', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        const SizedBox(height: 8),
                        const Chip(label: Text('Steam'), backgroundColor: Colors.black26, avatar: Icon(Icons.cloud, size: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Widget auxiliar para os cards de métricas
  Widget _buildMetricsSection(String hoursPlayed) {
    double progress = _totalAchievements > 0 ? _userAchievements.length / _totalAchievements : 0.0;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem('Tempo de Jogo', hoursPlayed, 'horas'),
            _buildMetricItem('Conquistas', '${_userAchievements.length}/${_totalAchievements}', ''),
          ],
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white12,
          color: Theme.of(context).primaryColor,
          minHeight: 6,
        ),
        const SizedBox(height: 24),
        if (_masteryIndex == null)
          Center(
            child: TextButton(
              onPressed: _calculateMastery,
              child: Text('Calcular Índice de Maestria', style: TextStyle(color: Theme.of(context).primaryColor)),
            ),
          )
        else
          _buildMetricItem('Índice de Maestria', _masteryIndex!.toStringAsFixed(1), 'pts'),
      ],
    );
  }

  // Widgets auxiliares para manter o código limpo
  Widget _buildMetricItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(value, style: const TextStyle(fontFamily: 'Mona Sans', color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            if(unit.isNotEmpty) const SizedBox(width: 4),
            if(unit.isNotEmpty) Text(unit, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoTile(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }
}