// lib/screens/mural_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/milestone.dart';

class MuralScreen extends StatefulWidget {
  const MuralScreen({super.key});

  @override
  State<MuralScreen> createState() => _MuralScreenState();
}

class _MuralScreenState extends State<MuralScreen> {
  Stream<QuerySnapshot>? _milestonesStream;
  final _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _milestonesStream = FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .collection('milestones')
          .orderBy('timestamp', descending: true)
          .snapshots();
    }
  }

  // NOVA FUNÇÃO: Mostra o diálogo de confirmação para apagar
  Future<void> _showDeleteConfirmationDialog(String milestoneId) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF181818),
          title: const Text('Remover Marco', style: TextStyle(color: Colors.white)),
          content: const SingleChildScrollView(
            child: Text('Tem a certeza de que deseja remover este marco do seu mural?', style: TextStyle(color: Colors.white70)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Remover', style: TextStyle(color: Colors.red)),
              onPressed: () {
                _deleteMilestone(milestoneId);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // NOVA FUNÇÃO: Apaga o marco do Firestore
  void _deleteMilestone(String milestoneId) {
    if (_currentUser == null) return;
    FirebaseFirestore.instance
        .collection('users')
        .doc(_currentUser!.uid)
        .collection('milestones')
        .doc(milestoneId)
        .delete()
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Marco removido com sucesso.'), backgroundColor: Colors.green),
          );
        }).catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao remover o marco: $error'), backgroundColor: Colors.red),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mural da Jornada'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _milestonesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erro ao carregar os marcos.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Seus marcos e conquistas mais orgulhosas aparecerão aqui depois de fixados.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 16),
                ),
              ),
            );
          }

          final milestoneDocs = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(16.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1,
            ),
            itemCount: milestoneDocs.length,
            itemBuilder: (context, index) {
              final doc = milestoneDocs[index];
              final data = doc.data() as Map<String, dynamic>;
              final milestone = Milestone(
                title: data['title'] ?? '',
                subtitle: data['subtitle'] ?? '',
                gameName: data['gameName'] ?? '',
                type: MilestoneType.achievement,
                timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
              );

              // AQUI ESTÁ A MUDANÇA: Envolvemos o card com GestureDetector
              return GestureDetector(
                onLongPress: () {
                  _showDeleteConfirmationDialog(doc.id); // Passa o ID do documento
                },
                child: Container(
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
                ),
              );
            },
          );
        },
      ),
    );
  }
}