// lib/screens/settings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _user;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    setState(() {
      _user = user;
      _userData = userDoc.data();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final creationDate = _user?.metadata.creationTime;
    final hasSteamLink = _userData != null && _userData!.containsKey('steamId');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined, color: Colors.white70),
                  title: const Text('Email da Conta'),
                  subtitle: Text(_user?.email ?? 'Não disponível', style: const TextStyle(color: Colors.white)),
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today_outlined, color: Colors.white70),
                  title: const Text('Membro desde'),
                  subtitle: Text(
                    creationDate != null ? DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(creationDate) : 'Não disponível',
                    style: const TextStyle(color: Colors.white)
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.link, color: Colors.white70),
                  title: const Text('Vinculação com a Steam'),
                  subtitle: Text(
                    hasSteamLink ? 'Conta Vinculada' : 'Não Vinculada',
                    style: TextStyle(color: hasSteamLink ? Theme.of(context).primaryColor : Colors.orange),
                  ),
                  trailing: Icon(
                    hasSteamLink ? Icons.check_circle : Icons.warning_amber_rounded,
                    color: hasSteamLink ? Theme.of(context).primaryColor : Colors.orange,
                  ),
                ),
              ],
            ),
    );
  }
}