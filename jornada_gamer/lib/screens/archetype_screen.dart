// lib/screens/archetype_screen.dart

import 'package:flutter/material.dart';
import '../models/player_archetype.dart';
import '../widgets/genre_stat_bar.dart';

class ArchetypeScreen extends StatelessWidget {
  final PlayerArchetype playerData;

  const ArchetypeScreen({super.key, required this.playerData});

  static const Map<String, String> archetypeDescriptions = {
    'Aventureiro Indie': 'Você busca experiências únicas e inovadoras, apoiando criadores independentes e explorando narrativas que fogem do comum.',
    'Explorador de Mundos': 'Sua paixão é se perder em universos vastos e ricos em detalhes. Cada canto do mapa é um convite para uma nova descoberta.',
    'Mestre Estrategista': 'A vitória para você é um plano bem executado. Você prospera em desafios que exigem raciocínio, planejamento e uma visão de longo prazo.',
    'Competidor Nato': 'A adrenalina da competição é o que te move. Você busca a maestria, o topo dos placares e a emoção de superar adversários habilidosos.',
    'Jogador Versátil': 'Você não se prende a um único estilo. Sua biblioteca é um mosaico de gêneros, refletindo uma curiosidade que abrange todo o universo gamer.',
  };

  @override
  Widget build(BuildContext context) {
    final description = archetypeDescriptions[playerData.arquetipoSugerido] ?? 'Sua jornada é única.';
    // AQUI ESTÁ A MUDANÇA: Lendo do campo renomeado
    final topGenres = playerData.topGenres;
    final double totalHoursForPercentage = playerData.totalGenrePlaytimeHours;

    return Scaffold(
      appBar: AppBar(
        title: Text(playerData.arquetipoSugerido),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            description,
            style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 32),
          const Text(
            'Fundamentos do Arquétipo',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          // A lógica aqui já é dinâmica, então não precisa de mais mudanças
          ...topGenres.entries.map((entry) {
            return GenreStatBar(
              genre: entry.key,
              hours: entry.value,
              totalHours: totalHoursForPercentage,
            );
          }).toList(),
        ],
      ),
    );
  }
}