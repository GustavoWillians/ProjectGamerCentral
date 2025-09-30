// lib/main.dart

import 'package:flutter/material.dart';
import 'models/activity_event.dart';
import 'models/dashboard_data.dart';
import 'screens/all_games_screen.dart';
import 'screens/archetype_screen.dart';
import 'screens/mural_screen.dart';
import 'screens/timeline_screen.dart';
import 'services/steam_api_service.dart';
import 'widgets/dna_radar_chart.dart';
import 'widgets/kpi_card.dart';
import 'widgets/recent_activity_item.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
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
      home: const DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SteamApiService steamApiService = SteamApiService();
  late Future<DashboardData> futureDashboardData;
  DashboardData? _dashboardData;

  @override
  void initState() {
    super.initState();
    futureDashboardData = steamApiService.fetchDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jornada Gamer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MuralScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.timeline),
            onPressed: _dashboardData == null ? null : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TimelineScreen(allGames: _dashboardData!.allGames),
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<DashboardData>(
        future: futureDashboardData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Erro ao buscar dados: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            );
          }
          if (snapshot.hasData) {
            final dashboardData = snapshot.data!;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _dashboardData = dashboardData);
            });

            final archetypeData = dashboardData.archetype;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  const SizedBox(height: 16),
                  Text(
                    archetypeData.arquetipoSugerido,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Mona Sans',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllGamesScreen(allGames: dashboardData.allGames))),
                            child: KpiCard(value: '${archetypeData.totalPlaytimeHours}h', label: 'Horas Totais'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AllGamesScreen(allGames: dashboardData.allGames))),
                            child: KpiCard(value: archetypeData.totalGames.toString(), label: 'Total de Jogos'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: KpiCard(
                            value: dashboardData.generalMasteryIndex.toStringAsFixed(1),
                            label: 'Maestria',
                            isHighlighted: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ArchetypeScreen(playerData: archetypeData))),
                    child: Container(
                      height: 300,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DnaRadarChart(chartData: archetypeData.topGenres),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text('Atividade Recente', style: TextStyle(fontFamily: 'Mona Sans', fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  if (dashboardData.recentActivity.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text('Nenhuma atividade nas últimas 2 semanas.', style: TextStyle(color: Color(0xFFA0A0A0)))),
                    )
                  else
                    ...dashboardData.recentActivity.take(5).map((event) {
                      final icon = event.type == ActivityEventType.achievement
                          ? Icons.military_tech
                          : Icons.timer_outlined;
                      
                      final timeAgo = formatTimeAgo(event.timestamp);

                      return RecentActivityItem(
                        gameTitle: event.title,
                        description: event.description,
                        timeAgo: timeAgo,
                        icon: icon,
                        appId: event.appId, // <-- PASSANDO O App ID NECESSÁRIO
                      );
                    }).toList(),
                  
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
          return const Center(child: Text('Algo deu errado.'));
        },
      ),
    );
  }
}

String formatTimeAgo(DateTime timestamp) {
  if (timestamp.year < 1980) return ''; 

  final difference = DateTime.now().difference(timestamp);
  if (difference.inDays > 1) {
    return '${difference.inDays}d';
  } else if (difference.inDays == 1) {
    return '1d';
  } else if (difference.inHours > 0) {
    return '${difference.inHours}h';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes}m';
  } else {
    return 'Agora';
  }
}