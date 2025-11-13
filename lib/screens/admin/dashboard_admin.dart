import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/customer/customer_screen.dart';
import 'package:techon_crm/screens/admin/invoice/invoice_screen.dart';
import 'package:techon_crm/screens/admin/lead/lead_screen.dart';
import 'package:techon_crm/screens/admin/project/project_screen.dart';
import 'package:techon_crm/screens/admin/setting_screen.dart';
import 'package:techon_crm/services/auth_service.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({Key? key}) : super(key: key);

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  bool isLoading = true;
  Map<String, dynamic> d = {};

  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api";
  final prefs =  SharedPreferences.getInstance();
  String? name;
  String? email;

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  // -----------------------------------------
  // 🔥 Load Dashboard Data
  // -----------------------------------------
  Future<void> loadDashboard() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    final staffId = prefs.getString('staffid') ?? "";
    name = await prefs.getString('name');
    email = await prefs.getString('email');

    try {
      final url = Uri.parse("$baseUrl/dashboard_data");
      final res = await http.post(url, body: {
        "authentication_token": token,
        "staffid": staffId
      });

      print("Dashboard Response → ${res.body}");

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);

        if (json['status'] == 1) {
          setState(() {
            d = json;
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error loading dashboard → $e");
    }
  }

  // -----------------------------------------
  // 🔥 MAIN UI
  // -----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text("Dashboard", style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      drawer: _buildDrawer(context, AuthService()),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dashboardUI(),
    );
  }

  // -----------------------------------------
  // 🔥 Dashboard Full UI
  // -----------------------------------------
  Widget _dashboardUI() {


    final user = d['currentUser'] ?? {};

    final customers = d['customerData'] ?? {};
    final tasks = d['tasksData'] ?? {};
    final leads = d['leadsData'] ?? {};
    final tickets = d['ticketsData'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const SizedBox(height: 10),

          _userHeader(
            name ?? "",
            email ?? "",
          ),

          const SizedBox(height: 20),
          const Text("Overview",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          // ---------- GRID ----------
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            children: [
              _statCard(Icons.group, "Active Customers",
                  "${customers['activeCustomers'] ?? 0} of ${customers['totalCustomers'] ?? 0}", Colors.blue),

              _statCard(Icons.check_circle, "Converted Leads",
                  "${leads['convertedLeads'] ?? 0} of ${leads['totalLeads'] ?? 0}", Colors.green),

              _statCard(Icons.task, "Pending Tasks",
                  "${tasks['tasksNotFinished'] ?? 0} of ${tasks['totalTasks'] ?? 0}", Colors.orange),

              _statCard(Icons.support_agent, "Tickets",
                  "${tickets['openTickets'] ?? 0} of ${tickets['totalTickets'] ?? 0}",
                  Colors.purple),
            ],
          ),

          const SizedBox(height: 25),

          const Text("Tasks Status",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),

          _progressRow("Open Tickets", Colors.red,
              tickets['openTickets'] ?? 0, tickets['totalTickets'] ?? 0),

          _progressRow("Low Priority", Colors.green,
              tickets['lowPriorityTickets'] ?? 0, tickets['totalTickets'] ?? 0),

          _progressRow("Medium Priority", Colors.orange,
              leads['convertedLeads'] ?? 0, leads['totalLeads'] ?? 0),

          _progressRow("High Priority", Colors.red.shade900,
              tickets['highPriorityTickets'] ?? 0, tickets['totalTickets'] ?? 0),
        ],
      ),
    );
  }

  // -----------------------------------------
  // 🔥 UI COMPONENTS
  // -----------------------------------------

  Widget _userHeader(String name, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ]),
      child: Row(
        children: [
          const CircleAvatar(
              radius: 28,
              backgroundColor: Colors.black12,
              child: Icon(Icons.person, size: 32, color: Colors.grey)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome $name",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text(email,
                  style:
                  const TextStyle(fontSize: 13, color: Colors.black54)),
            ],
          )
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value, Color color) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3))
          ]),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(value,
              style:
              TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 4),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _progressRow(String label, Color color, int value, int total) {
    double percent = total == 0 ? 0 : value / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(label)),
          Expanded(
            flex: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                color: color,
                backgroundColor: Colors.grey.shade200,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text("${(percent * 100).round()}%"),
        ],
      ),
    );
  }
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