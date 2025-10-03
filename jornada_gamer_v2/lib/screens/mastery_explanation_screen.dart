// lib/screens/mastery_explanation_screen.dart

import 'package:flutter/material.dart';

class MasteryExplanationScreen extends StatelessWidget {
  const MasteryExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Índice de Maestria'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'O que é o Índice de Maestria?',
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'É uma pontuação de 0 a 100 que mede o quão profundamente você dominou um jogo, baseada em sua habilidade e no seu esforço.',
            style: TextStyle(color: Colors.white70, fontSize: 16, height: 1.5),
          ),
          const Divider(height: 48, color: Colors.white12),

          // Componente 1: Dificuldade
          _buildExplanationCard(
            context: context,
            icon: Icons.diamond_outlined,
            title: 'Pontuação de Dificuldade',
            description: 'Calculada com base na raridade média das conquistas que você desbloqueou, em comparação com todos os outros jogadores da Steam. Conquistas mais raras resultam numa pontuação mais alta.',
          ),
          const SizedBox(height: 16),

          // Componente 2: Empenho
          _buildExplanationCard(
            context: context,
            icon: Icons.timer_outlined,
            title: 'Pontuação de Empenho',
            description: 'Compara o seu tempo de jogo com o tempo médio que a comunidade leva para terminar o mesmo título. Dedicar mais tempo que a média demonstra um maior empenho e aumenta a sua pontuação.',
          ),
          const Divider(height: 48, color: Colors.white12),
          
          // A Fórmula
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A Fórmula Final',
                  style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Maestria = (Dificuldade + Empenho) / 2',
                  style: TextStyle(fontFamily: 'Mona Sans', color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nota: Para jogos sem conquistas, o índice é baseado apenas na sua Pontuação de Empenho.',
                  style: TextStyle(color: Colors.white54, fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget auxiliar para os cartões de explicação
  Widget _buildExplanationCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor, size: 32),
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text(description, style: const TextStyle(color: Colors.white70)),
      ),
      contentPadding: EdgeInsets.zero,
    );
  }
}