import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';
import 'package:techon_crm/screens/admin/customer/create.dart';
import 'package:techon_crm/screens/admin/customer/view.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasMore = true;
  int startFrom = 0;
  final int limit = 50;

  List<dynamic> customers = [];
  List<Map<String, dynamic>> summary = [];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    fetchCustomers(initial: true);
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 🔹 Detect scroll end to load more
  void _scrollListener() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100 &&
        !isLoadingMore &&
        hasMore) {
      fetchCustomers(initial: false);
    }
  }

  // 🔹 Fetch customers
  Future<void> fetchCustomers({bool initial = false}) async {
    if (initial) {
      setState(() {
        customers.clear();
        startFrom = 0;
        hasMore = true;
      });
    }

    if (isLoading || isLoadingMore) return;

    if (initial) {
      setState(() => isLoading = true);
    } else {
      setState(() => isLoadingMore = true);
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please log in again")),
      );
      setState(() {
        isLoading = false;
        isLoadingMore = false;
      });
      return;
    }

    try {
      final url = Uri.parse("${AppConstants.apiBase}/get_my_customers");
      final response = await http.post(url, body: {
        "authentication_token": token,
        "start_from": startFrom.toString(),
        "end_to": (startFrom + limit).toString(),
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          final List<dynamic> newCustomers = data['customers'] ?? [];

          setState(() {
            if (newCustomers.isNotEmpty) {
              customers.addAll(newCustomers);
              startFrom += limit;
            } else {
              hasMore = false;
            }

            // Update summary only once on first load
            if (initial) {
              int total = customers.length;
              int active = customers
                  .where((c) =>
              c['tblclients_active'] == "1" ||
                  c['tblclients_active'] == 1)
                  .length;
              int inactive = total - active;

              summary = [
                {
                  'title': 'Total Customers',
                  'count': total,
                  'color': Colors.blue
                },
                {
                  'title': 'Active Customers',
                  'count': active,
                  'color': Colors.green
                },
                {
                  'title': 'Inactive Customers',
                  'count': inactive,
                  'color': Colors.red
                },
              ];
            }
          });
        } else {
          setState(() => hasMore = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("⚠️ ${data['message']}")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("❌ Server Error: ${response.statusCode}")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() {
      isLoading = false;
      isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => fetchCustomers(initial: true),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: () => fetchCustomers(initial: true),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Customer Summary',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              if (summary.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: summary.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) {
                    final item = summary[index];
                    return Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['count'].toString(),
                            style: TextStyle(
                              color: item['color'],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            item['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
              const Text(
                'Customers',
                style:
                TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: customers.isEmpty
                    ? const Center(child: Text("No customers found"))
                    : ListView.builder(
                  controller: _scrollController,
                  itemCount: customers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == customers.length) {
                      return _buildLoader();
                    }
                    final c = customers[index];
                    final bool isActive =
                        c['tblclients_active'].toString() == "1";
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  CustomerDetailsScreen(
                                      userId: int.parse(
                                          c['userid'].toString())),
                            ),
                          );

                          // ✅ Refresh if updated
                          if (updated == true) {
                            fetchCustomers(initial: true);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor:
                                Colors.blueGrey.shade700,
                                child: Text(
                                  (c['company'] ?? 'N')
                                      .toString()
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['company'] ??
                                          'Unknown Company',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.phone,
                                            size: 14,
                                            color: Colors.grey),
                                        const SizedBox(width: 4),
                                        Text(
                                          (c['phonenumber']
                                              ?.toString()
                                              .isNotEmpty ??
                                              false)
                                              ? c['phonenumber']
                                              .toString()
                                              : 'No phone',
                                          style: const TextStyle(
                                              color: Colors.black54,
                                              fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.shade50
                                      : Colors.red.shade50,
                                  borderRadius:
                                  BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isActive
                                        ? Colors.green
                                        : Colors.red,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isActive
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      size: 14,
                                      color: isActive
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      isActive
                                          ? 'Active'
                                          : 'Inactive',
                                      style: TextStyle(
                                        color: isActive
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final added = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddCustomerScreen()),
          );

          if (added == true) {
            fetchCustomers(initial: true);
          }
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  Widget _buildLoader() {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (!hasMore) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text("No more customers")),
      );
    } else {
      return const SizedBox();
    }
  }
}
