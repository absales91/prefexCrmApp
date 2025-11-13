import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/invoice/edit.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isLoading = true;

  Map<String, dynamic>? invoice;
  List<dynamic> payments = [];
  Map<String, dynamic>? companyInfo;
  String? totalPaid;
  String? amountDue;

  final String baseUrl =
      "https://crm.msmesoftwares.com/perfex_mobile_app_api";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchInvoice();
  }

  // 🔹 Fetch Invoice Data
  Future<void> fetchInvoice() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Session expired")));
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/view_invoice");
      final response = await http.post(url, body: {
        "authentication_token": token,
        "invoiceId": widget.invoiceId,
      });
      print(widget.invoiceId);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final d = data['data'];
          print(d['companyInformation']);
          setState(() {
            invoice = d['invoice'];
            payments = d['payments'] ?? [];
            companyInfo = d['companyInformation'];
            totalPaid = d['total_paid']?.toString();
            amountDue = d['amount_due']?.toString();
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);

          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(data['message'])));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Server Error: ${response.statusCode}")),
        );

      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // 🔹 UI BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Invoice Details"),
        // backgroundColor: const Color(0xFF162232),
        actions:  [
          IconButton(onPressed: ()=>{
            Navigator.of(context).push(new MaterialPageRoute(builder: (context) => EditInvoiceScreen(invoiceData: invoice)))
          }, icon: Icon(Icons.edit_outlined, color: Colors.white)),

          SizedBox(width: 16),
          Icon(Icons.delete_outline, color: Colors.white),
          SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Invoice"),
            Tab(text: "Payments"),
          ],
          indicatorColor: Colors.cyanAccent,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildInvoiceTab(),
          _buildPaymentsTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF162232),
        onPressed: () {},
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Payment", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // 🔹 Invoice Tab
  Widget _buildInvoiceTab() {
    if (invoice == null) return const Center(child: Text("No data"));

    final status = invoice?['status'] ?? 'Unknown';
    final invoiceNo = invoice?['formatted_number'] ?? 'INV-XXX';
    final client = companyInfo?['invoice_company_name'] ?? '-';
    final date = invoice?['date'] ?? '-';
    final dueDate = invoice?['duedate'] ?? '-';
    final currency = invoice?['currency_name'] ?? '€';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(invoiceNo,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(status.toString(),
                          style: TextStyle(
                              color: status.toString().toLowerCase().contains("paid")
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _infoRow("Company", client),
                  _infoRow("Invoice Date", date),
                  _infoRow("Due Date", dueDate),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text("Items",
              style: TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),

          const SizedBox(height: 10),

          if (invoice?['items'] != null)

            for (var item in invoice!['items'])

              _itemCard(
                item['description'] ?? '',
                "$currency${item['rate']} x ${item['qty']}",
                "$currency${item['rate']}",
              ),

          const Divider(height: 30),
          _summaryRow("Subtotal", "$currency${invoice?['subtotal'] ?? '0.00'}"),
          _summaryRow("Tax", "$currency${invoice?['total_tax'] ?? '0.00'}"),
          _summaryRow("Discount", "$currency${invoice?['discount_total'] ?? '0.00'}"),
          _summaryRow("Total Paid", totalPaid ?? '-'),
          _summaryRow("Amount Due", amountDue ?? '-',
              color: Colors.red, bold: true),

          const SizedBox(height: 20),
          const Text("Client Note",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(invoice?['clientnote'] ?? 'No notes'),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String title, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style:
            const TextStyle(fontSize: 14, color: Colors.black54)),
        Text(value,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    ),
  );

  Widget _itemCard(String title, String desc, String price) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0.5,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 13)),
              ]),
          Text(price,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    ),
  );

  Widget _summaryRow(String label, String value,
      {Color color = Colors.black54, bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w500)),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600)),
        ],
      ),
    );
  }

  // 🔹 Payments Tab
  Widget _buildPaymentsTab() {
    if (payments.isEmpty) {
      return const Center(child: Text("No payments found"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final p = payments[index];
        return Card(
          elevation: 1,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Payment #${p['id'] ?? ''}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(p['amount'].toString() ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.account_balance_wallet_outlined,
                      color: Colors.cyan, size: 18),
                  const SizedBox(width: 4),
                  Text(p['paymentmode'].toString() ?? 'Bank',
                      style: const TextStyle(color: Colors.black54)),
                  const Spacer(),
                  const Icon(Icons.calendar_today_outlined,
                      color: Colors.cyan, size: 16),
                  const SizedBox(width: 4),
                  Text(p['date'] ?? '',
                      style: const TextStyle(color: Colors.black54)),
                ])
              ],
            ),
          ),
        );
      },
    );
  }
}
