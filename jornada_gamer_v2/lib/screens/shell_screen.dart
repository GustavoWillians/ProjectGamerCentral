// lib/screens/shell_screen.dart
import 'package:flutter/material.dart';
import 'package:jornada_gamer/main.dart';
import 'package:jornada_gamer/models/dashboard_data.dart';
import 'package:jornada_gamer/screens/mural_screen.dart';
import 'package:jornada_gamer/screens/timeline_screen.dart';
import 'package:jornada_gamer/services/steam_api_service.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  final SteamApiService _steamApiService = SteamApiService();
  late Future<DashboardData> _futureDashboardData;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _futureDashboardData = _steamApiService.fetchDashboardData();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DashboardData>(
      future: _futureDashboardData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.hasError) {
          return Scaffold(appBar: AppBar(title: const Text('Erro')), body: Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Erro ao carregar dados: ${snapshot.error}'))));
        }

        if (snapshot.hasData) {
          final dashboardData = snapshot.data!;

          final List<Widget> screens = [
            DashboardScreen(dashboardData: dashboardData),
            TimelineScreen(allGames: dashboardData.allGames),
            const MuralScreen(),
          ];

          return Scaffold(
            body: IndexedStack(
              index: _selectedIndex,
              children: screens,
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Início'),
                BottomNavigationBarItem(icon: Icon(Icons.timeline), activeIcon: Icon(Icons.timeline), label: 'Linha do Tempo'),
                BottomNavigationBarItem(icon: Icon(Icons.star_border), activeIcon: Icon(Icons.star), label: 'Mural'),
              ],
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              backgroundColor: const Color(0xFF181818),
              selectedItemColor: Theme.of(context).primaryColor,
              unselectedItemColor: Colors.white54,
              showUnselectedLabels: true,
              showSelectedLabels: true,
              type: BottomNavigationBarType.fixed,
            ),
          );
        }

        return const Scaffold(body: Center(child: Text('Algo correu mal.')));
      },
    );
  }
}