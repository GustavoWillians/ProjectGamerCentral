// lib/widgets/kpi_card.dart

import 'package:flutter/material.dart';

class KpiCard extends StatelessWidget {
  final String value;
  final String label;
  final bool isHighlighted;

  const KpiCard({
    super.key,
    required this.value,
    required this.label,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF181818),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Mona Sans',
              fontWeight: FontWeight.bold,
              fontSize: 28,
              color: isHighlighted ? primaryColor : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFFA0A0A0),
            ),
          ),
        ],
      ),
    );
  }
}