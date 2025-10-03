// lib/widgets/recent_activity_item.dart
import 'package:flutter/material.dart';

class RecentActivityItem extends StatelessWidget {
  final String gameTitle;
  final String description;
  final String timeAgo;
  final IconData icon;
  final int appId; // <-- NOVO PARÂMETRO

  const RecentActivityItem({
    super.key,
    required this.gameTitle,
    required this.description,
    required this.timeAgo,
    required this.icon,
    required this.appId, // <-- NOVO PARÂMETRO
  });

  @override
  Widget build(BuildContext context) {
    // Constrói a URL da imagem do cabeçalho do jogo
    final imageUrl = 'https://cdn.akamai.steamstatic.com/steam/apps/$appId/header.jpg';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              // Adicionamos um Container com fundo preto
              child: Container(
                color: Colors.black,
                child: Image.network(
                  imageUrl,
                  // AQUI ESTÁ A MUDANÇA: de BoxFit.cover para BoxFit.contain
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF181818),
                      child: Icon(icon, color: Theme.of(context).primaryColor),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameTitle,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14, color: Color(0xFFA0A0A0)),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            timeAgo,
            style: const TextStyle(fontSize: 12, color: Color(0xFFA0A0A0)),
          ),
        ],
      ),
    );
  }
}