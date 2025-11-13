import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/project/edit.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  bool isLoading = true;
  Map<String, dynamic>? project;
  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api";
  // var tasks;

  @override
  void initState() {
    super.initState();
    fetchProjectDetails();
  }

  Future<void> fetchProjectDetails() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final url = Uri.parse('$baseUrl/get_project_details');
      final response = await http.post(url, body: {
        'authentication_token': token,
        'project_id': widget.projectId.toString(),
      });

      // print("🔵 Project Detail Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          setState(() {
            project = data['project'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "Failed to load project")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
    setState(() => isLoading = false);
  }

  double _parseProgress(dynamic raw) {
    if (raw == null) return 0.0;
    if (raw is num) {
      final v = raw.toDouble();
      return v <= 1.0 ? v : v / 100.0;
    }
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed == null) return 0.0;
      return parsed <= 1.0 ? parsed : parsed / 100.0;
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final p = project ?? {};
    print(p['progress_from_tasks']);

    final name = p['name'] ?? '';
    final status = p['status_name'] ?? 'Unknown';
    final client = p['client_name'] ?? 'N/A';
    final billingType = p['billing_type_name'] ?? 'N/A';
    final startDate = p['start_date'] ?? '-';
    final deadline = p['deadline'] ?? '-';
    final totalRate = p['calculated_amount'] ?? '0.00';
    final logged = p['logged_time'] ?? '00:00';
    final description =
    (p['description'] ?? '').replaceAll(RegExp(r'<[^>]*>'), '');
    final progress = _parseProgress(p['progress_percent']);
    final colorHex = p['status_color'] ?? '#9E9E9E';

    Color color;
    try {
      color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
    } catch (_) {
      color = Colors.blueGrey;
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Project Details"),
          backgroundColor: const Color(0xFF162232),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                Navigator.of(context).push( MaterialPageRoute(builder: (context)=>EditProjectScreen(projectData: project!)));
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () {},
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.cyan,
            tabs: [
              Tab(icon: Icon(Icons.dashboard), text: "Overview"),
              Tab(icon: Icon(Icons.task_alt), text: "Tasks"),
              Tab(icon: Icon(Icons.receipt_long), text: "Invoices"),
            ],
          ),
        ),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
          children: [
            _overviewTab(
              name: name,
              status: status,
              client: client,
              billingType: billingType,
              startDate: startDate,
              deadline: deadline,
              totalRate: totalRate.toString(),
              logged: logged,
              description: description,
              progress: progress,
              color: color,
            ),
            _taskTab(
              project!['tasks']
             ),
            const Center(child: Text("Invoices Tab (Coming Soon)")),
          ],
        ),
      ),
    );
  }

  Widget _taskTab(List<dynamic> tasks) {
    if (tasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "No tasks found for this project.",
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Project Tasks",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];

                final colorHex = task['status_color'] ?? '#9E9E9E';
                Color color;
                try {
                  color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
                } catch (_) {
                  color = Colors.grey;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12.withOpacity(0.08),
                        offset: const Offset(0, 2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Task name and status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              task['name'] ?? 'Unnamed Task',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              border: Border.all(color: color),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              task['status_name'] ?? 'Pending',
                              style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Description
                      if (task['description'] != null &&
                          task['description'].toString().isNotEmpty)
                        Text(
                          task['description']
                              .toString()
                              .replaceAll(RegExp(r'<[^>]*>'), '')
                              .trim(),
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),

                      const SizedBox(height: 10),

                      // Progress bar


                      const SizedBox(height: 10),

                      // Dates
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  color: Colors.grey, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                task['start_date'] ?? '',
                                style: const TextStyle(
                                    color: Colors.black54, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            task['due_date'] ?? '',
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _overviewTab({
    required String name,
    required String status,
    required String client,
    required String billingType,
    required String startDate,
    required String deadline,
    required String totalRate,
    required String logged,
    required String description,
    required double progress,
    required Color color,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style:
            const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(status,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(height: 10),

          // Main Info Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow("Customer", client, "Billing Type", billingType),
                  const Divider(),
                  _infoRow("Start Date", startDate, "Deadline", deadline),
                  const Divider(),
                  _infoRow("Total Rate", "$totalRate", "Logged", logged),
                  const Divider(),
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Text("Description: $description")),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text("Project Progress",
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              color: Colors.cyan,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 6),
          Text("${(progress * 100).toStringAsFixed(0)}%",
              style: const TextStyle(fontSize: 13)),

          const SizedBox(height: 20),

          // Expenses Summary
          const Text("Expenses",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 10),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _expenseCard("Total Expenses", "₹${project!['expenses_summary']['total_expenses'] ?? '0.00'}", Colors.black87),
              _expenseCard("Billable Expenses", "₹${project!['expenses_summary']['billable_expenses'] ?? '0.00'}", Colors.orange),
              _expenseCard("Billed Expenses", "₹${project!['expenses_summary']['billed_expenses'] ?? '0.00'}", Colors.green),
              _expenseCard("Unbilled Expenses", "₹${project!['expenses_summary']['unbilled_expenses'] ?? '0.00'}", Colors.red),
            ],
          )

        ],
      ),
    );
  }

  Widget _infoRow(
      String leftTitle, String leftValue, String rightTitle, String rightValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _infoColumn(leftTitle, leftValue),
        _infoColumn(rightTitle, rightValue),
      ],
    );
  }

  Widget _infoColumn(String title, String value) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 13)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _expenseCard(String title, String amount, Color color) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(amount,
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 6),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
