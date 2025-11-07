import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme_provider.dart'; // adjust path if needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool notificationsEnabled = true;

  String? userName;
  String? userRole;
  String? userEmail;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'User';
      userRole = prefs.getString('role') ?? 'Client';
      userEmail = prefs.getString('email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    final bgColor = isDarkMode ? const Color(0xFF121212) : Colors.grey.shade100;
    final cardColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          'Settings',
          style: TextStyle(color: textColor),
        ),
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // PROFILE HEADER
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName?.toUpperCase() ?? 'Loading...',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        userRole ?? '',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                      if (userEmail != null && userEmail!.isNotEmpty)
                        Text(
                          userEmail!,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Text(
            'Preferences',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),

          // DARK MODE TOGGLE
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Dark Mode',
            subtitle: 'Enable dark theme throughout the app',
            trailing: Switch(
              value: isDarkMode,
              onChanged: (value) => themeProvider.toggleTheme(value),
              activeColor: Colors.indigo,
            ),
            cardColor: cardColor,
            textColor: textColor,
          ),

          // NOTIFICATIONS
          _buildSettingTile(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'Receive alerts and updates',
            trailing: Switch(
              value: notificationsEnabled,
              onChanged: (value) {
                setState(() => notificationsEnabled = value);
              },
              activeColor: Colors.indigo,
            ),
            cardColor: cardColor,
            textColor: textColor,
          ),

          // LANGUAGE
          _buildSettingTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'Select preferred language',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            cardColor: cardColor,
            textColor: textColor,
          ),

          // SECURITY
          _buildSettingTile(
            icon: Icons.security,
            title: 'Security',
            subtitle: 'Manage your password and login settings',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            cardColor: cardColor,
            textColor: textColor,
          ),

          const SizedBox(height: 20),
          Text(
            'Account',
            style: TextStyle(
              color: Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),

          // LOGOUT
          _buildSettingTile(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out from this device',
            trailing: const Icon(Icons.chevron_right, color: Colors.grey),
            cardColor: cardColor,
            textColor: Colors.redAccent,
            iconColor: Colors.redAccent,
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out successfully!')),
                );
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color cardColor,
    required Color textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: iconColor ?? Colors.indigo),
        title: Text(
          title,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: trailing,
      ),
    );
  }
}
