import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/customer/customer_screen.dart';
import 'package:techon_crm/screens/admin/invoice_screen.dart';
import 'package:techon_crm/screens/admin/lead_screen.dart';
import 'package:techon_crm/screens/admin/project_screen.dart';
import 'package:techon_crm/screens/admin/setting_screen.dart';
import '../../services/auth_service.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  bool isLoading = true;
  int totalLeads = 0;
  int totalProjects = 0;
  List leadSummary = [];
  List projectSummary = [];

  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api";

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired! Please login again")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      final leadsRes = await http.post(
        Uri.parse('$baseUrl/get_my_leads'),
        body: {
          'authentication_token': token,
          'start_from': '0',
          'end_to': '50',
        },
      );

      final projectsRes = await http.post(
        Uri.parse('$baseUrl/get_my_projects'),
        body: {
          'authentication_token': token,
          'start_from': '0',
          'end_to': '50',
        },
      );

      if (leadsRes.statusCode == 200 && projectsRes.statusCode == 200) {
        final leadData = jsonDecode(leadsRes.body);
        final projectData = jsonDecode(projectsRes.body);

        setState(() {
          totalLeads = (leadData['leads'] as List?)?.length ?? 0;
          totalProjects = (projectData['projects'] as List?)?.length ?? 0;
          leadSummary = leadData['summary'] ?? [];
          projectSummary = projectData['summary'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Dashboard error: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, auth),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadDashboard,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _welcomeHeader(auth),
              const SizedBox(height: 20),

              // Summary cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statCard("Leads", totalLeads, Colors.blue, Icons.people),
                  _statCard("Projects", totalProjects, Colors.green, Icons.work),
                ],
              ),

              const SizedBox(height: 30),

              // Lead summary chips
              _summarySection("Lead Summary", leadSummary),

              const SizedBox(height: 24),

              // Project summary chips
              _summarySection("Project Summary", projectSummary),
            ],
          ),
        ),
      ),
    );
  }

  Drawer _buildDrawer(BuildContext context, AuthService auth) {
    return Drawer(
      child: Container(
        // color: Colors.grey.shade100,
        child: Column(
          children: [
            // 🌈 Custom Drawer Header with Row Layout
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.blueAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.indigo.shade700,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.name ?? 'Admin',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          auth.role ?? 'Staff',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: Colors.white),
                    tooltip: 'Logout',
                    onPressed: () async {
                      await auth.logout();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                  ),
                ],
              ),
            ),

            // 📋 Main menu items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerTile(
                    icon: Icons.dashboard,
                    title: 'Dashboard',
                    context: context,
                    onTap: () => Navigator.pop(context),
                  ),
                  _drawerTile(
                    icon: Icons.people,
                    title: 'Customer',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => CustomerScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: Icons.phone,
                    title: 'Contacts',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => LeadsScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: Icons.request_quote,
                    title: 'Estimate',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => LeadsScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: Icons.description,
                    title: 'Proposal',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => LeadsScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: Icons.people,
                    title: 'Leads',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => LeadsScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: Icons.work,
                    title: 'Projects',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => ProjectsScreen()));
                    },
                  ),
                  _drawerTile(
                    icon: Icons.receipt_long,
                    title: 'Invoices',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => InvoicesScreen()));
                    },
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      "SETTINGS",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  _drawerTile(
                    icon: Icons.settings,
                    title: 'App Settings',
                    context: context,
                    onTap: () {
                      Navigator.push(
                          context, MaterialPageRoute(builder: (_) => SettingsScreen()));
                    },
                  ),
                ],
              ),
            ),

            // 🚪 Bottom Logout (optional, since we have top logout)
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.exit_to_app, color: Colors.redAccent),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  await auth.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper Widget for menu items
  Widget _drawerTile({
    required IconData icon,
    required String title,
    required BuildContext context,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Card(
        // color: Colors.white,
        elevation: 0.5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: Icon(icon, color: Colors.indigo),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 15,
            ),
          ),
          onTap: onTap,
          dense: true,
          visualDensity: VisualDensity.compact,
          trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }



  Widget _welcomeHeader(AuthService auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Welcome, ${auth.name ?? 'Admin'} 👋",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          "Manage leads, projects, and clients efficiently.",
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _statCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _summarySection(String title, List summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 10),
        summary.isEmpty
            ? const Text("No data available", style: TextStyle(color: Colors.grey))
            : SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: summary.length,
            itemBuilder: (context, index) {
              final item = summary[index];
              final name = item['name'] ?? 'Unknown';
              final count = item['count'] ?? 0;
              final colorHex = item['color'] ?? '#2196F3';

              Color color;
              try {
                color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
              } catch (e) {
                color = Colors.blue;
              }

              return Container(
                width: 120,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withOpacity(0.4)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(count.toString(),
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(name,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black87)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
