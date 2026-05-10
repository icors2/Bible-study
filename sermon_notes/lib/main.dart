import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const SermonNotesApp());
}

class SermonNotesApp extends StatelessWidget {
  const SermonNotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sermon Notes',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F5F45)),
        useMaterial3: true,
      ),
      home: const HomeShell(),
    );
  }
}
