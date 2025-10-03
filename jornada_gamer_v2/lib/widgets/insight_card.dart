// lib/widgets/insight_card.dart

import 'package:flutter/material.dart';
import '../models/insight.dart';

class InsightCard extends StatelessWidget {
  final Insight insight;

  const InsightCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.title,
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            insight.description,
            style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}