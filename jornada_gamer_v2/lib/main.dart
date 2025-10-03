import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

import 'screens/auth_gate.dart';
import 'models/activity_event.dart';
import 'models/dashboard_data.dart';
import 'models/insight.dart';
import 'screens/all_games_screen.dart';
import 'screens/archetype_screen.dart';
import 'screens/mastery_explanation_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'services/steam_api_service.dart';
import 'widgets/dna_radar_chart.dart';
import 'widgets/insight_card.dart';
import 'widgets/kpi_card.dart';
import 'widgets/recent_activity_item.dart';
import 'screens/shell_screen.dart';
import 'screens/timeline_screen.dart';
import 'screens/mural_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await initializeDateFormatting('pt_BR', null);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const JornadaGamerApp());
}

class JornadaGamerApp extends StatelessWidget {
  const JornadaGamerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jornada Gamer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF101010),
        primaryColor: const Color(0xFFBEF264),
        fontFamily: 'Inter',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF181818),
          elevation: 0,
          titleTextStyle: TextStyle(
            fontFamily: 'Mona Sans',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFF5F5F5),
          ),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  final DashboardData dashboardData;
  const DashboardScreen({super.key, required this.dashboardData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SteamApiService steamApiService = SteamApiService();
  List<Insight> _currentInsights = [];
  bool _isLoadingInsights = true;
  String _username = 'Carregando...';
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshInsights());
  }

  Future<void> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (mounted) {
        setState(() {
          _username = userDoc.data()?['username'] ?? user.displayName ?? user.email?.split('@').first ?? 'Jogador';
          _avatarBase64 = userDoc.data()?['avatarBase64'];
        });
      }
    }
  }

  Future<void> _refreshInsights() async {
    if (mounted) setState(() => _isLoadingInsights = true);
    final newInsights = await steamApiService.generateInsights(
      widget.dashboardData.allGames,
      widget.dashboardData.archetype,
      widget.dashboardData.ownedGamesRaw,
    );
    if (mounted) {
      setState(() {
        _currentInsights = newInsights;
        _isLoadingInsights = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? avatarBytes;
    if (_avatarBase64 != null) {
      try {
        avatarBytes = base64Decode(_avatarBase64!);
      } catch(e) {
        print("Erro ao decodificar avatar no dashboard: $e");
      }
    }

    final archetypeData = widget.dashboardData.archetype;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(dashboardData: widget.dashboardData)));
            _loadUserProfile();
          },
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: Colors.white12,
                backgroundImage: avatarBytes != null ? MemoryImage(avatarBytes) : null,
                child: avatarBytes == null ? const Icon(Icons.person_outline, size: 18, color: Colors.white70) : null,
              ),
              const SizedBox(width: 12),
              Text(_username, style: const TextStyle(fontSize: 20)),
            ],
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'profile') {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen(dashboardData: widget.dashboardData)));
                _loadUserProfile();
              } else if (value == 'settings') {
                await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
              } else if (value == 'sair') {
                await FirebaseAuth.instance.signOut();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(children: [Icon(Icons.person_outline, color: Colors.white), SizedBox(width: 12), Text('Meu Perfil')]),
              ),
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(children: [Icon(Icons.settings_outlined, color: Colors.white), SizedBox(width: 12), Text('Configurações')]),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: 'sair',
                child: Row(children: [Icon(Icons.logout, color: Colors.white), SizedBox(width: 12), Text('Sair')]),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(height: 16),
            Text(archetypeData.arquetipoSugerido, textAlign: TextAlign.center, style: TextStyle(fontFamily: 'Mona Sans', fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllGamesScreen(allGames: widget.dashboardData.allGames))), child: KpiCard(value: '${archetypeData.totalPlaytimeHours}h', label: 'Horas Totais'))),
                  const SizedBox(width: 12),
                  Expanded(child: GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllGamesScreen(allGames: widget.dashboardData.allGames))), child: KpiCard(value: archetypeData.totalGames.toString(), label: 'Total de Jogos'))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const MasteryExplanationScreen()));
                      },
                      child: KpiCard(
                        value: widget.dashboardData.generalMasteryIndex.toStringAsFixed(1),
                        label: 'Maestria',
                        isHighlighted: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArchetypeScreen(playerData: archetypeData))),
              child: Container(
                height: 300, padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(color: const Color(0xFF181818), borderRadius: BorderRadius.circular(12)),
                child: DnaRadarChart(chartData: archetypeData.topGenres),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Insights Rápidos', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            _isLoadingInsights
                ? const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: CircularProgressIndicator()))
                : Column(children: _currentInsights.map((insight) => InsightCard(insight: insight)).toList()),
            const SizedBox(height: 24),
            const Text('Atividade Recente', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            if (widget.dashboardData.recentActivity.isEmpty)
              const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Center(child: Text('Nenhuma atividade nas últimas 2 semanas.', style: TextStyle(color: Color(0xFFA0A0A0)))))
            else
              ...widget.dashboardData.recentActivity.take(5).map((event) {
                return RecentActivityItem(gameTitle: event.title, description: event.description, timeAgo: formatTimeAgo(event.timestamp), icon: event.type == ActivityEventType.achievement ? Icons.military_tech : Icons.timer_outlined, appId: event.appId);
              }).toList(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

String formatTimeAgo(DateTime timestamp) {
  if (timestamp.year < 1980) return '';
  final difference = DateTime.now().difference(timestamp);
  if (difference.inDays > 1) return '${difference.inDays}d';
  if (difference.inDays == 1) return '1d';
  if (difference.inHours > 0) return '${difference.inHours}h';
  if (difference.inMinutes > 0) return '${difference.inMinutes}m';
  return 'Agora';
}