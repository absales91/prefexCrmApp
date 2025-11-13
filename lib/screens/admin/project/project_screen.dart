
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/project/create.dart';
import 'package:techon_crm/screens/admin/project/view.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({Key? key}) : super(key: key);

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<dynamic> summary = [];
  List<dynamic> projects = [];
  bool isLoading = true;

  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api"; // Change this

  @override
  void initState() {
    super.initState();
    fetchProjects();
  }
  double _parseProgress(dynamic raw) {
    if (raw == null) return 0.0;

    // If it's numeric (int/double)
    if (raw is num) {
      final v = raw.toDouble();
      if (v <= 1.0) return v.clamp(0.0, 1.0); // already fraction
      return (v / 100.0).clamp(0.0, 1.0); // percent -> fraction
    }

    // If it's a string
    if (raw is String) {
      final parsed = double.tryParse(raw);
      if (parsed == null) return 0.0;
      if (parsed <= 1.0) return parsed.clamp(0.0, 1.0);
      return (parsed / 100.0).clamp(0.0, 1.0);
    }

    return 0.0;
  }


  Future<void> fetchProjects() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final url = Uri.parse('$baseUrl/get_my_projects');
      final response = await http.post(url, body: {
        'authentication_token': token,
        'end_to': '50',
        'start_from': '0',
      });

      print("Project Response: ${response.body}");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          setState(() {
            summary = data['summary'] ?? [];
            projects = data['projects'] ?? [];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "No projects found")),
          );
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error: ${response.statusCode}")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        // backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Projects',
            // style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)
        ),
        centerTitle: true,
        // iconTheme: const IconThemeData(color: Colors.black),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FloatingActionButton(onPressed: (){
          Navigator.of(context).push(new MaterialPageRoute(builder: (context)=> AddProjectScreen()));
        },
        child: Icon(Icons.add),),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Project Summary",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    // color: Colors.black87
                )
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: summary.length,
                itemBuilder: (context, index) {
                  final item = summary[index];
                  final colorHex = item['color'] ?? '#2196F3';
                  Color color;
                  try {
                    color =
                        Color(int.parse(colorHex.replaceFirst('#', '0xff')));
                  } catch (_) {
                    color = Colors.blue;
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _summaryCard(
                        item['name'] ?? '', item['count'] ?? 0, color),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            const Text("Projects",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    // color: Colors.black87
                )),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: projects.length,

                itemBuilder: (context, index) {
                  final p = projects[index];
                  final colorHex = p['status_color'] ?? '#9E9E9E';
                  Color color;
                  final raw = p['progress_percent'];

                  final progress = _parseProgress(p['progress_percent']);



                  try {
                    color = Color(int.parse(colorHex.replaceFirst('#', '0xff')));
                  } catch (_) {
                    color = Colors.grey;
                  }

                  return _projectCard(
                    p['name'] ?? '',
                    p['description'] ?? '',
                    p['status_name'] ?? '',
                    progress,
                    p['deadline'] ?? '',
                    p['client_name'] ?? '',
                    color,
                    projectId: p['id']
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Container(
      width: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              offset: const Offset(0, 2),
              blurRadius: 6)
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(count.toString(),
                style:
                TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: 13))
          ],
        ),
      ),
    );
  }

  Widget _projectCard(
      String title,
      String desc,
      String status,
      double percent,
      String date,
      String client,
      Color color, {
        int? projectId, // 🔹 Added optional projectId
      }) {
    return InkWell(
      onTap: () {
        if (projectId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProjectDetailScreen(projectId: projectId),
            ),
          );
        }
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
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
            // ✅ Title & Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title — wrapped inside Flexible
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      fontSize: 15,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
                const SizedBox(width: 8),
                // Status Badge
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    border: Border.all(color: color),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ✅ Description — clean HTML strip + wrapping
            Text(
              desc.replaceAll(RegExp(r'<[^>]*>'), '').trim(),
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),

            const SizedBox(height: 10),

            // ✅ Progress Bar + Percent Text
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text("${(percent * 100).round()}%",
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),

            const SizedBox(height: 10),

            // ✅ Date & Client Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: Colors.grey, size: 14),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        date,
                        style: const TextStyle(
                            color: Colors.black54, fontSize: 12),
                        softWrap: true,
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: Text(
                    client,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                    softWrap: true,
                    overflow: TextOverflow.visible,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


}
