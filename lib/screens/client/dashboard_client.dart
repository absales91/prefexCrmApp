import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class DashboardClient extends StatelessWidget {
  const DashboardClient({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Dashboard"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.logout();
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                const Icon(Icons.account_circle,
                    size: 100, color: Colors.indigo),
                const SizedBox(height: 10),
                Text(
                  "Welcome, ${auth.name ?? 'Client'}",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Role: ${auth.role ?? 'customer'}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.indigo),
              title: const Text("My Invoices"),
              subtitle: const Text("View your billing and payments"),
              onTap: () {},
            ),
          ),
          Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.support_agent, color: Colors.indigo),
              title: const Text("Support Tickets"),
              subtitle: const Text("View or raise new support tickets"),
              onTap: () {},
            ),
          ),
          Card(
            elevation: 3,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: const Icon(Icons.task_alt, color: Colors.indigo),
              title: const Text("My Projects"),
              subtitle: const Text("Track your project progress"),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
