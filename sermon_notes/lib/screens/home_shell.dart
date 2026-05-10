import 'package:flutter/material.dart';

import '../services/bible_service.dart';
import 'bible_reader_screen.dart';
import 'sermon_notes_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final BibleService _bible = BibleService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _index == 0
            ? SermonNotesScreen(
                key: const ValueKey('sermon'),
                bible: _bible,
              )
            : BibleReaderScreen(
                key: const ValueKey('bible'),
                bible: _bible,
              ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Sermon',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book),
            label: 'Bible',
          ),
        ],
      ),
    );
  }
}
