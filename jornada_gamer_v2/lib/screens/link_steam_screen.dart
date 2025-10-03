// lib/screens/link_steam_screen.dart

import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkSteamScreen extends StatefulWidget {
  const LinkSteamScreen({super.key});

  @override
  State<LinkSteamScreen> createState() => _LinkSteamScreenState();
}

class _LinkSteamScreenState extends State<LinkSteamScreen> {
  bool _isLoading = false;
  HttpServer? _server;

  Future<void> _linkSteamAccount() async {
    setState(() => _isLoading = true);

    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      _server = server;
      final completer = Completer<String>();

      server.listen((HttpRequest request) async {
        final steamId = request.uri.queryParameters['openid.claimed_id']?.split('/').last;
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write('<html><body onload="window.close();"><h3>Sucesso!</h3><p>Pode fechar esta janela.</p></body></html>');
        await request.response.close();
        await server.close();
        if (steamId != null) {
          completer.complete(steamId);
        } else {
          completer.completeError('Não foi possível extrair o Steam ID da resposta.');
        }
      });

      final port = server.port;
      final realmUrl = 'http://localhost:$port';
      final returnToUrl = 'http://localhost:$port/auth';

      final steamOpenIdUrl = 'https://steamcommunity.com/openid/login'
          '?openid.ns=http://specs.openid.net/auth/2.0'
          '&openid.mode=checkid_setup'
          '&openid.return_to=$returnToUrl'
          '&openid.realm=$realmUrl'
          '&openid.identity=http://specs.openid.net/auth/2.0/identifier_select'
          '&openid.claimed_id=http://specs.openid.net/auth/2.0/identifier_select'
          '&l=brazilian';

      final uri = Uri.parse(steamOpenIdUrl);

      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.inAppWebView);
      } else {
        throw Exception('Não foi possível abrir a URL de autenticação.');
      }

      final steamId = await completer.future.timeout(const Duration(minutes: 5));
      await closeInAppWebView();

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'steamId': steamId,
        }, SetOptions(merge: true));

        // CORREÇÃO: Não navegamos para o Dashboard. Apenas paramos o loading.
        // O AuthGate irá detetar a mudança no Firestore e fazer a navegação.
        if (mounted) {
          // Apenas garantimos que o estado de loading é atualizado.
        }
      }
    } catch (e) {
      print("Erro ao vincular conta Steam: $e");
      await closeInAppWebView();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao vincular a conta Steam. Tente novamente.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      await _server?.close();
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
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                  },
                  child: const Text(
                    'Sair e sincronizar mais tarde',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}