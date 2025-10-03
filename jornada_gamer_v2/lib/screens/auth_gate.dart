// lib/screens/auth_gate.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:jornada_gamer/screens/link_steam_screen.dart';
import 'package:jornada_gamer/screens/login_screen.dart';
import 'package:jornada_gamer/screens/shell_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (authSnapshot.hasData) {
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance.collection('users').doc(authSnapshot.data!.uid).snapshots(),
            builder: (context, docSnapshot) {
              if (docSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (docSnapshot.hasData && docSnapshot.data!.exists && (docSnapshot.data!.data() as Map).containsKey('steamId')) {
                return const ShellScreen();
              } else {
                return const LinkSteamScreen();
              }
            },
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}