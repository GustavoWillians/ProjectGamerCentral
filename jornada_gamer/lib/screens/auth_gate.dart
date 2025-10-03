// lib/screens/auth_gate.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jornada_gamer/main.dart';
import 'package:jornada_gamer/screens/link_steam_screen.dart'; // Importa a nova tela
import 'package:jornada_gamer/screens/login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        // Se há um utilizador logado no Firebase...
        if (snapshot.hasData) {
          // ...verificamos se ele tem um Steam ID guardado no Firestore.
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(snapshot.data!.uid).get(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              // Se o documento existe e tem um steamId...
              if (docSnapshot.hasData && docSnapshot.data!.exists && (docSnapshot.data!.data() as Map).containsKey('steamId')) {
                // ...vai para o Dashboard.
                return const DashboardScreen();
              } else {
                // ...senão, vai para a tela de vincular a conta Steam.
                return const LinkSteamScreen();
              }
            },
          );
        } else {
          // Se não há utilizador logado, vai para a tela de Login.
          return const LoginScreen();
        }
      },
    );
  }
}