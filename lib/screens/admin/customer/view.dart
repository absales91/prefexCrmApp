import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';
import 'package:techon_crm/screens/admin/customer/edit.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final int userId;

  const CustomerDetailsScreen({super.key, required this.userId});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  bool isLoading = false;
  Map<String, dynamic>? customerData;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchCustomerDetails();
    // initData();
  }



  Future<void> fetchCustomerDetails() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please login again")),
      );
      setState(() => isLoading = false);
      return;
    }

    try {
      final url = Uri.parse("${AppConstants.apiBase}/get_customer");
      final response = await http.post(url, body: {
        "authentication_token": token,
        "userId": widget.userId.toString(),
        "group": "admin",
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          setState(() => customerData = data['data']);
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("⚠️ ${data['message']}")));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => isLoading = false);
  }

  Widget buildInfoRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54)),
          Flexible(
            child: Text(
              value.isNotEmpty ? value : "-",
              style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCard(List<Widget> children) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = customerData?['client'];
    final contacts = customerData?['contacts'] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
        title: const Text("Customer Details", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(onPressed: () {

            Navigator.of(context).push(new MaterialPageRoute(builder: (context)=>
            EditCustomerScreen(
              customer: client,
                // customerData: client
            )));
          }, icon: const Icon(Icons.edit_outlined)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.delete_outline)),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "Profile"),
            Tab(text: "Billing & Shipping"),
            Tab(text: "Contacts"),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : customerData == null
          ? const Center(child: Text("No customer found"))
          : TabBarView(
        controller: _tabController,
        children: [
          // ---------------- PROFILE TAB ----------------
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildCard([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: buildInfoRow("Company", client?['company'] ?? '',
                            bold: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: buildInfoRow(
                            "VAT Number", client?['vat'].toString() ?? '', bold: true),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: buildInfoRow(
                            "Phone", client?['phonenumber'].toString() ?? '', bold: true),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: buildInfoRow(
                            "Website", client?['website'] ?? '', bold: true),
                      ),
                    ],
                  ),
                ]),

                buildCard([
                  buildInfoRow(
                      "Address", client?['address'] ?? '', bold: true),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                          child: buildInfoRow(
                              "City", client?['city'] ?? '', bold: true)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: buildInfoRow(
                              "State", client?['state'] ?? '', bold: true)),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                          child: buildInfoRow(
                              "Zip Code", client?['zip'].toString() ?? '', bold: true)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: buildInfoRow(
                              "Country", client?['country']?.toString() ?? '',
                              bold: true)),
                    ],
                  ),
                ]),
              ],
            ),
          ),

          // ---------------- BILLING TAB ----------------
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                buildCard([
                  buildInfoRow(
                      "Billing Street", client?['billing_street'] ?? '',
                      bold: true),
                  buildInfoRow(
                      "Billing City", client?['billing_city'] ?? '',
                      bold: true),
                  buildInfoRow(
                      "Billing State", client?['billing_state'] ?? '',
                      bold: true),
                  buildInfoRow(
                      "Billing Zip", client?['billing_zip'].toString() ?? '',
                      bold: true),
                ]),
                buildCard([
                  buildInfoRow(
                      "Shipping Street", client?['shipping_street'] ?? '',
                      bold: true),
                  buildInfoRow(
                      "Shipping City", client?['shipping_city'] ?? '',
                      bold: true),
                  buildInfoRow(
                      "Shipping State", client?['shipping_state'] ?? '',
                      bold: true),
                  buildInfoRow(
                      "Shipping Zip", client?['shipping_zip'].toString() ?? '',
                      bold: true),
                ]),
              ],
            ),
          ),

          // ---------------- CONTACTS TAB ----------------
          contacts.isEmpty
              ? const Center(child: Text("No contacts found"))
              : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final c = contacts[index];
              return buildCard([
                buildInfoRow("Name",
                    "${c['firstname'] ?? ''} ${c['lastname'] ?? ''}",
                    bold: true),
                buildInfoRow("Email", c['email'] ?? ''),
                buildInfoRow("Phone", c['phonenumber'].toString() ?? ''),
                buildInfoRow("Position", c['title'] ?? ''),
              ]);
            },
          ),
        ],
      ),
    );
  }
}
