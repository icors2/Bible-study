import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (_firebaseSupportedPlatform) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, st) {
      debugPrint('Firebase.initializeApp failed: $e\n$st');
    }
  } else {
    debugPrint(
      'Firebase skipped on ${defaultTargetPlatform.name} (e.g. Linux tests).',
    );
  }

  runApp(const SermonNotesApp());
}

bool get _firebaseSupportedPlatform {
  if (kIsWeb) return true;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return true;
    default:
      return false;
  }
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
