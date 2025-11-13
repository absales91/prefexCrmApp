import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:techon_crm/screens/admin/lead/create.dart';
import 'package:techon_crm/screens/admin/lead/view.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api";
  bool isLoading = true;
  bool isMoreLoading = false;
  bool hasMore = true;

  int startFrom = 0;
  final int limit = 20;

  List<dynamic> leads = [];
  List<dynamic> leadSummary = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchLeads();

    // Infinite scroll listener
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200 &&
          !isMoreLoading &&
          hasMore) {
        fetchLeads(loadMore: true);
      }
    });
  }

  Future<void> fetchLeads({bool loadMore = false}) async {
    if (loadMore) {
      setState(() => isMoreLoading = true);
    } else {
      setState(() {
        isLoading = true;
        startFrom = 0;
        hasMore = true;
      });
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please log in again")),
      );
      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
      return;
    }

    try {
      final url = Uri.parse('$baseUrl/get_my_leads');
      final Map<String, String> requestBody = {
        'authentication_token': token,
        'end_to': limit.toString(),
        'start_from': startFrom.toString(),
      };

      final response = await http.post(
        url,
        headers: {'Accept': 'application/json'},
        body: requestBody,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1 || data['success'] == 1) {
          final newLeads = List<Map<String, dynamic>>.from(data['leads'] ?? []);

          setState(() {
            if (loadMore) {
              leads.addAll(newLeads);
            } else {
              leads = newLeads;
              leadSummary = data['summary'] ?? [];
            }

            startFrom += limit;
            hasMore = newLeads.length == limit;
          });
        } else {
          hasMore = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? "No leads found")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      print("❌ Error fetching leads: $e");
    } finally {
      setState(() {
        isLoading = false;
        isMoreLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ... same build() code below, but wrap the leads list with the scroll controller
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: const Color(0xFFF5F6FA),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Create Lead',
        onPressed: (){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateLeadScreen()));
        },
      child: Icon(Icons.add),),
      appBar: AppBar(
        // backgroundColor: Colors.white,
        title: const Text('Leads',

        ),
        centerTitle: true,
        elevation: 0,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Lead Summary",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    // color: Colors.black87
                )),
            const SizedBox(height: 12),
            if (leadSummary.isNotEmpty)
              SizedBox(
                height: 100,
                width: double.infinity,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: leadSummary.length,
                  itemBuilder: (context, index) {
                    final item = leadSummary[index];
                    final name = item['name']?.toString() ?? '';
                    final count = item['count']?.toString() ?? '0';
                    final colorHex = item['color']?.toString() ?? '#2196F3';
                    Color color;
                    try {
                      color =
                          Color(int.parse(colorHex.replaceFirst('#', '0xff')));
                    } catch (e) {
                      color = Colors.blue;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: _summaryCard(name, count, color),
                    );
                  },
                ),
              ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text("Leads",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        // color: Colors.black87
                    )),
                Icon(Icons.filter_alt_outlined, color: Colors.blue),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                controller: _scrollController,
                itemCount: leads.length + 1,
                itemBuilder: (context, index) {
                  if (index < leads.length) {
                    final lead = leads[index];
                    print(lead);
                    return _leadCard(
                      lead,
                      lead['name'] ?? lead['lead_name'] ?? 'No Name',
                      lead['company'] ?? lead['organization'] ?? '',
                      lead['status'] ?? 'Unknown',
                      double.tryParse(
                          lead['lead_value']?.toString() ?? '0') ??
                          0,
                      lead['source'] ?? 'N/A',
                      lead['dateadded'] ?? '',
                      Colors.blueAccent,
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Center(
                        child: hasMore
                            ? const CircularProgressIndicator()
                            : const Text(
                          "No more leads",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _leadCard(
      lead,
      String name,
      String company,
      String status,
      double amount,
      String platform,
      String date,
      Color color,
      ) {
    return InkWell(
      onTap: () {
        // TODO: Navigate to lead details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeadDetailScreen(lead: lead),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------
            // 🔹 NAME + STATUS BADGE
            // ----------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            // ----------------------------------------------------
            // 🏢 COMPANY
            // ----------------------------------------------------
            Row(
              children: [
                const Icon(Icons.business_outlined,
                    color: Colors.grey, size: 15),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    company.isNotEmpty ? company : "No Company",
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),

            const SizedBox(height: 14),

            // ----------------------------------------------------
            // 🔸 INFO ROWS (Value, Source, Date)
            // ----------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _infoBox(Icons.currency_rupee, "Value",
                    "₹${amount.toStringAsFixed(0)}"),

                _infoBox(Icons.campaign_outlined, "Source",
                    platform),

                _infoBox(Icons.calendar_today_outlined, "Date",
                    date),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Widget _summaryCard(String title, String count, Color color) {
  return Container(
    width: 120, // fixed width for horizontal scroll
    margin: const EdgeInsets.symmetric(horizontal: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2))
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(count,
            style: TextStyle(
                color: color, fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 4),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    ),
  );
}


Widget _infoBox(IconData icon, String label, String value) {
  return Flexible(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    ),
  );
}

