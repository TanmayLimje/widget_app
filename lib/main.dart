import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';
import 'user_home_page.dart';
import 'services/supabase_service.dart'; // Supabase sync - see docs/SUPABASE.md

// Global theme mode notifier
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
  ThemeMode.system,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (see docs/SUPABASE.md for removal)
  await SupabaseService.initialize();

  // Load saved theme preference
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme_mode') ?? 'system';
  themeModeNotifier.value = _themeModeFromString(savedTheme);

  runApp(const AanTanApp());
}

ThemeMode _themeModeFromString(String value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'dark':
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
}

String themeModeToString(ThemeMode mode) {
  switch (mode) {
    case ThemeMode.light:
      return 'light';
    case ThemeMode.dark:
      return 'dark';
    case ThemeMode.system:
      return 'system';
  }
}

// Available color themes
class UserTheme {
  final String name;
  final Color color;
  final String hexCode;

  const UserTheme(this.name, this.color, this.hexCode);
}

final List<UserTheme> availableThemes = [
  const UserTheme('Purple', Color(0xFF6366F1), 'FF6366F1'),
  const UserTheme('Blue', Color(0xFF3B82F6), 'FF3B82F6'),
  const UserTheme('Green', Color(0xFF10B981), 'FF10B981'),
  const UserTheme('Orange', Color(0xFFF97316), 'FFF97316'),
  const UserTheme('Pink', Color(0xFFEC4899), 'FFEC4899'),
  const UserTheme('Red', Color(0xFFEF4444), 'FFEF4444'),
  const UserTheme('Teal', Color(0xFF14B8A6), 'FF14B8A6'),
  const UserTheme('Yellow', Color(0xFFEAB308), 'FFEAB308'),
];

class AanTanApp extends StatelessWidget {
  const AanTanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'AanTan',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          themeMode: themeMode,
          initialRoute: '/login',
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case '/login':
                return MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                );
              case '/home':
                final userNumber = settings.arguments as int? ?? 1;
                return MaterialPageRoute(
                  builder: (context) => UserHomePage(userNumber: userNumber),
                );
              default:
                return MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                );
            }
          },
        );
      },
    );
  }
}
