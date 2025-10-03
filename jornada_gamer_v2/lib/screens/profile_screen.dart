import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/dashboard_data.dart';
import 'edit_profile_screen.dart';
import 'game_details_screen.dart';

class ProfileScreen extends StatefulWidget {
  final DashboardData dashboardData;
  const ProfileScreen({super.key, required this.dashboardData});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (mounted) {
      setState(() {
        _user = user;
        _userData = userDoc.data();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final creationDate = _user?.metadata.creationTime;
    final archetypeData = widget.dashboardData.archetype;
    final top3Games = widget.dashboardData.allGames.take(3).toList();
    
    final username = _userData?['username'] ?? _user?.displayName ?? _user?.email?.split('@').first ?? 'Jogador';
    final avatarBase64 = _userData?['avatarBase64'] as String?;
    Uint8List? avatarBytes;
    if (avatarBase64 != null) {
      try {
        avatarBytes = base64Decode(avatarBase64);
      } catch (e) {
        print("Erro ao decodificar avatar: $e");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
              _loadUserData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.white12,
                          backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                          child: avatarBytes == null 
                              ? Icon(Icons.person_outline, size: 50, color: primaryColor)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          username,
                          style: const TextStyle(fontFamily: 'Mona Sans', fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(_user?.email ?? '', style: const TextStyle(color: Colors.white54, fontSize: 16)),
                        const SizedBox(height: 8),
                        if (creationDate != null)
                          Text('Membro desde ${DateFormat('MMMM yyyy', 'pt_BR').format(creationDate)}', style: const TextStyle(color: Colors.white38, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Divider(height: 48, color: Colors.white12),
                  const Text('Métricas de Destaque', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: Icon(Icons.psychology_outlined, color: primaryColor),
                    title: const Text('Arquétipo de Jogador', style: TextStyle(color: Colors.white70)),
                    subtitle: Text(archetypeData.arquetipoSugerido, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ListTile(
                    leading: Icon(Icons.military_tech_outlined, color: primaryColor),
                    title: const Text('Índice de Maestria Geral', style: TextStyle(color: Colors.white70)),
                    subtitle: Text(widget.dashboardData.generalMasteryIndex.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  const Divider(height: 48, color: Colors.white12),
                  const Text('Jogos Mais Jogados', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 180,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: top3Games.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final game = top3Games[index];
                        final imageUrl = 'https://cdn.akamai.steamstatic.com/steam/apps/${game.appId}/library_600x900.jpg';
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => GameDetailsScreen(game: game)));
                          },
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              imageUrl,
                              width: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(width: 120, color: Colors.white12, child: const Icon(Icons.image_not_supported)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}