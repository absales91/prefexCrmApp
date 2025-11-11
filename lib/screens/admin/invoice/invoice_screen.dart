import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/invoice/create.dart';
import 'package:techon_crm/screens/admin/invoice/view.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({super.key});

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api";

  bool isLoading = true;
  List<dynamic> invoices = [];
  List<dynamic> invoiceSummary = [];
  int totalInvoices = 0;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  Future<void> fetchInvoices() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please log in again")),
      );
      setState(() => isLoading = false);
      return;
    }

    final url = Uri.parse('$baseUrl/get_invoices');

    try {
      final response = await http.post(url, body: {
        "authentication_token": token,
        "start_from": "0",
        "end_to": "50",
      });

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (mounted) {
          setState(() {
            invoices = decoded['invoices'] ?? [];
            invoiceSummary = decoded['summary'] ?? [];
            totalInvoices = invoiceSummary.fold<int>(
              0,
                  (sum, item) => sum + (int.tryParse(item['count'].toString()) ?? 0),
            );
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching invoices: $e')),
      );
    }
  }

  // Widget for each summary box
  Widget _summaryCard(String title, String count, Color color) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(count,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  // Status color mapping
  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.red;
      case 'overdue':
        return Colors.orange;
      case 'partially paid':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoices"),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: fetchInvoices),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchInvoices,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Invoice Summary",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          // color: Colors.black87
                      )
                  ),
                  const SizedBox(height: 12),

                  // Summary Row
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: invoiceSummary.length,
                      itemBuilder: (context, index) {
                        final item = invoiceSummary[index];
                        final name = item['name'] ?? '';
                        final count = item['count'].toString();
                        final color = _statusColor(name);
                        return _summaryCard(name, count, color);
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Invoices ($totalInvoices)",
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        // color: Colors.black87
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Invoice List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: invoices.length,
                    itemBuilder: (context, index) {
                      print(invoices[index]);
                      final inv = invoices[index];
                      final status = inv['status_name'] ?? '';
                      final color = _statusColor(status);
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: (){
                            Navigator.of(context).push(
                              new MaterialPageRoute(builder: (context) => InvoiceDetailScreen(
                                invoiceId: inv['id'].toString(),
                              ))
                            );
                          },
                          contentPadding: const EdgeInsets.all(12),
                          leading: Container(
                            width: 5,
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(
                            inv['formatted_number'] ?? 'INV-XXX',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                // color: Colors.black87
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(status,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.w500)),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_today,
                                      size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(inv['duedate'] ?? '-',
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                          trailing: Text(
                            "${inv['fancyTotal'] ?? '0'}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                // color: Colors.black87
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ]),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(new MaterialPageRoute(builder: (context)=>CreateInvoiceScreen()));
          // Future: Create new invoice
        },
      ),
    );
  }
}
