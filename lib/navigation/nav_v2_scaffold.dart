// lib/navigation/nav_v2_scaffold.dart
import 'package:flutter/material.dart';

class NavV2Scaffold extends StatefulWidget {
  const NavV2Scaffold({super.key});

  static const route = '/_dev/navV2';

  @override
  State<NavV2Scaffold> createState() => _NavV2ScaffoldState();
}

class _NavV2ScaffoldState extends State<NavV2Scaffold> {
  int _index = 0;

  static const _tabs = <Widget>[
    Center(child: Text('Home')),
    Center(child: Text('Shorts')),
    Center(child: Text('Explore')),
    Center(child: Text('Messages')),
    Center(child: Text('Profile')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.play_arrow), label: 'Shorts'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Explore'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
