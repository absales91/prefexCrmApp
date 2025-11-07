import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/theme_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/admin/dashboard_admin.dart';
import 'screens/client/dashboard_client.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ThemeProvider(isDark: isDark)),
      ],
      child: const PerfexApp(),
    ),
  );
}

class PerfexApp extends StatelessWidget {
  const PerfexApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Techon CRM Connect',
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.themeMode,

      // 🌞 LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: true,
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        tabBarTheme: TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.black87
        ),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.indigo),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.indigo),
          trackColor: WidgetStateProperty.all(Colors.indigo.shade200),
        ),
      ),

      // 🌙 DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D),
        primaryColor: Colors.indigoAccent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardColor: const Color(0xFF1E1E1E),
        drawerTheme: const DrawerThemeData(
          backgroundColor: Color(0xFF121212),
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white70),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
        iconTheme: const IconThemeData(color: Colors.indigoAccent),
        dividerColor: Colors.grey.shade800,
        colorScheme: const ColorScheme.dark(
          primary: Colors.indigoAccent,
          secondary: Colors.indigo,
          surface: Color(0xFF1E1E1E),
          background: Color(0xFF121212),
          onPrimary: Colors.white,
          onSurface: Colors.white70,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.all(Colors.indigoAccent),
          trackColor: WidgetStateProperty.all(Colors.indigo.withOpacity(0.4)),
        ),
      ),

      home: const SplashScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/admin': (context) => const DashboardAdmin(),
        '/client': (context) => const DashboardClient(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final role = prefs.getString('role');

    if (token == null || token.isEmpty) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      if (role == 'admin' || role == 'staff') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardAdmin()),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/client');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FlutterLogo(size: 100),
            const SizedBox(height: 16),
            Text(
              'Techon CRM Connect',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
