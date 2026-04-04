import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifter/core/providers/shared_preferences_provider.dart';
import 'package:lifter/core/providers/user_provider.dart';
import 'package:lifter/core/ui/screens/username_screen.dart';
import 'package:lifter/core/ui/main_shell.dart';
import 'package:lifter/core/ui/themes/app_theme.dart';
import 'package:lifter/features/user/providers/user_settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs)
    ],
    child: const FitApp()));
}

class FitApp extends ConsumerStatefulWidget {
  const FitApp({super.key});

  @override
  ConsumerState<FitApp> createState() => _FitAppState();
}

class _FitAppState extends ConsumerState<FitApp> {

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);
    final themeMode = ref.watch(userSettingsProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: 'Lifter',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: userProfile.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => const Scaffold(
          body: Center(child: Text('Something went wrong')),
        ),
        data: (profile) {
          final needsOnboarding = profile == null || profile.username.isEmpty;
          return needsOnboarding 
              ? const UsernameScreen() 
              : const MainShell();
        }
      ),
    );
  }
}
