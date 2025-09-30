// lib/widgets/genre_stat_bar.dart

import 'package:flutter/material.dart';

class GenreStatBar extends StatelessWidget {
  final String genre;
  final double hours;
  final double totalHours; // totalHours aqui é o valor do gênero mais jogado

  const GenreStatBar({
    super.key,
    required this.genre,
    required this.hours,
    required this.totalHours,
  });

  @override
  Widget build(BuildContext context) {
    // Calcula a proporção e a porcentagem
    final double ratio = totalHours > 0 ? (hours / totalHours).clamp(0, 1) : 0.0;
    final int percentage = (ratio * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Texto com Nome do Gênero e a NOVA Porcentagem
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(genre, style: const TextStyle(color: Colors.white, fontSize: 16)),
              // AQUI ESTÁ A MUDANÇA: Exibindo a porcentagem
              Text(
                '$percentage%',
                style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // A Barra de Progresso visual continua a mesma
          Container(
            height: 8,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}