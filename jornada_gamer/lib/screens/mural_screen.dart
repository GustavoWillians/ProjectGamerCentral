// lib/screens/mural_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../state/mural_state.dart'; // <<< IMPORT CORRIGIDO

class MuralScreen extends StatefulWidget {
  const MuralScreen({super.key});

  @override
  State<MuralScreen> createState() => _MuralScreenState();
}

class _MuralScreenState extends State<MuralScreen> {
  @override
  Widget build(BuildContext context) {
    // Agora o 'MuralState' é reconhecido
    final pinnedMilestones = MuralState.pinnedMilestones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural da Jornada'),
      ),
      body: pinnedMilestones.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Seus marcos e conquistas mais orgulhosas aparecerão aqui depois de fixados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
                ),
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1,
              ),
              itemCount: pinnedMilestones.length,
              itemBuilder: (context, index) {
                final milestone = pinnedMilestones[index];
                return Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181818),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.military_tech, color: Theme.of(context).primaryColor, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        milestone.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        milestone.gameName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      if (milestone.timestamp != null)
                        Text(
                          DateFormat('dd/MM/yyyy').format(milestone.timestamp!),
                          style: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 11),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}