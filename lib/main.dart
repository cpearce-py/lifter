import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:lifter/features/bluetooth/ble_service.dart';
import 'package:lifter/core/providers/user_provider.dart';
import 'package:lifter/core/ui/screens/username_screen.dart';
import 'package:lifter/core/ui/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const ProviderScope(child: FitApp()));
}

class FitApp extends ConsumerStatefulWidget {
  const FitApp({super.key});

  @override
  ConsumerState<FitApp> createState() => _FitAppState();
}

class _FitAppState extends ConsumerState<FitApp> {
  // final _bleService = BleService();

  @override
  void dispose() {
    // _bleService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usernameAsync = ref.watch(usernameProvider);

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
      home: usernameAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const Scaffold(
          body: Center(child: Text('Something went wrong')),
        ),
        data: (username) => username == null
            ? const UsernameScreen()
            : MainShell(),
      ),
    );
  }
}
