// lib/widgets/recent_activity_item.dart

import 'package:flutter/material.dart';

class RecentActivityItem extends StatelessWidget {
  final String gameTitle;
  final String description; // O nome correto do parâmetro é 'description'
  final String timeAgo;
  final IconData icon;

  const RecentActivityItem({
    super.key,
    required this.gameTitle,
    required this.description, // Parâmetro 'description' definido aqui
    required this.timeAgo,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF181818),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  gameTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Text(
                  description, // Usando 'description' aqui
                  style: const TextStyle(fontSize: 14, color: Color(0xFFA0A0A0)),
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