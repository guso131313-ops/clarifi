import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';

import 'views/auth_gate.dart';

// Firebase Web Options
const FirebaseOptions _webOptions = FirebaseOptions(
  apiKey: "AIzaSyDdgupx6yq_tY6JiE42Ujy6yx3XPb0KeOk",
  authDomain: "clarifi-89c1c.firebaseapp.com",
  projectId: "clarifi-89c1c",
  storageBucket: "clarifi-89c1c.firebasestorage.app",
  messagingSenderId: "473455065533",
  appId: "1:473455065533:web:3fac5b2cbac273ccbdfad4",
  measurementId: "G-L9Q5WMM18X",
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(options: _webOptions);
  } else {
    await Firebase.initializeApp();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Clarifi',
      theme: ThemeData(useMaterial3: true),
      home: const AuthGate(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('es')],
    );
  }
}
