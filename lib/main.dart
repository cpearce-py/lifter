import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lifter/ble/ble_service.dart';

import 'pages/main_shell.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const FitApp());
}

class FitApp extends StatefulWidget {
  const FitApp({super.key});

  @override
  State<FitApp> createState() => _FitAppState();
}

class _FitAppState extends State<FitApp> {
  // Created once here so every screen in the app shares the same instance.
  final _bleService = BleService();

  @override
  void dispose() {
    _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'lifter',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE8FF47),
          surface: Color(0xFF0A0A0F),
        ),
      ),
      home: MainShell(bleService: _bleService),
    );
  }
}


