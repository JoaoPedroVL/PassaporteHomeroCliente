import 'package:flutter/material.dart';

import '../models/user_profile.dart';
import 'badges_page.dart';
import 'home_page.dart';
import 'passport_page.dart';
import 'profile_page.dart';
import 'wall_page.dart';

/// Estrutura principal do app cliente com as cinco áreas do passaporte.
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.perfil});

  final UserProfile perfil;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _indice = 0;

  void _selecionar(int indice) {
    if (indice == _indice) return;
    setState(() => _indice = indice);
  }

  @override
  Widget build(BuildContext context) {
    final paginas = <Widget>[
      HomePage(
        perfil: widget.perfil,
        onVerPassaporte: () => _selecionar(1),
      ),
      PassportPage(perfil: widget.perfil),
      BadgesPage(perfil: widget.perfil),
      WallPage(perfil: widget.perfil),
      ProfilePage(perfil: widget.perfil),
    ];

    return Scaffold(
      body: IndexedStack(index: _indice, children: paginas),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _indice,
        onDestinationSelected: _selecionar,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Passaporte',
          ),
          NavigationDestination(
            icon: Icon(Icons.military_tech_outlined),
            selectedIcon: Icon(Icons.military_tech),
            label: 'Insígnias',
          ),
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Padlet',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
