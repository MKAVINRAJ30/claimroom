import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client.dart';
import 'screens/home_screen.dart';

// Set for Serverpod Cloud: flutter run --dart-define=SERVER_URL=https://api.your-domain.serverpod.cloud
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  runApp(const ClaimRoomApp());
}

/// Builds a theme for the given [brightness].
ThemeData _buildTheme(Brightness brightness) {
  final baseScheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF6366F1),
    brightness: brightness,
    primary: const Color(0xFF6366F1),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: baseScheme,
    textTheme: GoogleFonts.interTextTheme(
      brightness == Brightness.dark
          ? ThemeData.dark().textTheme
          : ThemeData.light().textTheme,
    ),
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      backgroundColor: baseScheme.surface,
      foregroundColor: baseScheme.onSurface,
    ),
  );
}

class ClaimRoomApp extends StatelessWidget {
  const ClaimRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ClaimRoom - Live First-to-Claim Sales',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
