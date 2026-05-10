import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/bible_service.dart';
import '../services/sermon_cloud_sync.dart';
import '../widgets/account_sheet.dart';
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
  final SermonCloudSync _cloudSync = SermonCloudSync();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _cloudSync.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final cloudReady = _cloudSync.isFirebaseReady;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sermon Notes'),
            actions: [
              if (cloudReady)
                IconButton(
                  tooltip: user == null ? 'Sign in' : 'Account',
                  onPressed: () => showAccountSheet(
                    context,
                    cloud: _cloudSync,
                  ),
                  icon: Icon(
                    user == null ? Icons.person_outline : Icons.person,
                  ),
                ),
            ],
          ),
          body: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            child: _index == 0
                ? SermonNotesScreen(
                    key: const ValueKey('sermon'),
                    bible: _bible,
                    cloudSync: _cloudSync,
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
      },
    );
  }
}
