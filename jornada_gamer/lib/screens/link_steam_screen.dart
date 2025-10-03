// lib/screens/link_steam_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:jornada_gamer/main.dart';

class LinkSteamScreen extends StatefulWidget {
  const LinkSteamScreen({super.key});

  @override
  State<LinkSteamScreen> createState() => _LinkSteamScreenState();
}

class _LinkSteamScreenState extends State<LinkSteamScreen> {
  bool _isLoading = false;

  Future<void> _linkSteamAccount() async {
    setState(() => _isLoading = true);

    const steamOpenIdUrl = 'https://steamcommunity.com/openid/login'
        '?openid.ns=http://specs.openid.net/auth/2.0'
        '&openid.mode=checkid_setup'
        '&openid.return_to=jornadagamer://auth' // Nosso esquema customizado
        '&openid.realm=jornadagamer://auth'
        '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
        '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select';

    try {
      // 1. Inicia a autenticação web
      final result = await FlutterWebAuth2.authenticate(
        url: steamOpenIdUrl,
        callbackUrlScheme: "jornadagamer",
      );

      // 2. Extrai o Steam ID da URL de retorno
      final steamId = Uri.parse(result).queryParameters['openid.claimed_id']
          ?.split('/')
          .last;
      
      if (steamId == null || steamId.isEmpty) {
        throw Exception('Não foi possível obter o Steam ID.');
      }

      // 3. Salva o Steam ID no Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'steamId': steamId,
        });

        // 4. Navega para o Dashboard
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
            (route) => false,
          );
        }
      }
    } catch (e) {
      print("Erro ao vincular conta Steam: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao vincular a conta Steam.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.link, size: 80, color: primaryColor),
                const SizedBox(height: 24),
                const Text(
                  'Vincule sua Conta Steam',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontFamily: 'Mona Sans', fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Para analisar sua jornada, precisamos de acesso seguro ao seu perfil público da Steam.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _linkSteamAccount,
                    child: const Text('Vincular com a Steam', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}