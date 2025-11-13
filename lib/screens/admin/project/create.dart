import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/screens/admin/project/project_screen.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({super.key});

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  String? selectedClient;
  String? selectedBillingType;
  String? selectedStatus;

  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> billingTypes = [];
  List<Map<String, dynamic>> statuses = [];

  final String baseUrl =
      "https://crm.msmesoftwares.com/perfex_mobile_app_api";

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Session expired!")));
      return;
    }

    try {
      final url = Uri.parse("$baseUrl/get_project_initial_data");
      final response =
      await http.post(url, body: {"authentication_token": token});
      final data = jsonDecode(response.body);

      if (data['status'] == 1) {
        print('customers');
        print(data['customers']);
        setState(() {
          clients = List<Map<String, dynamic>>.from(
            (data['customers'] ?? []).map((c) => {
              'id': c['userid'].toString(),
              'name': c['company'] ?? 'Unnamed',
            }),
          );

          billingTypes = List<Map<String, dynamic>>.from(
            (data['billing_types'] ?? []).map((b) => {
              'id': b['id'].toString(),
              'name': b['name'] ?? '',
            }),
          );

          statuses = List<Map<String, dynamic>>.from(
            (data['project_statuses'] ?? []).map((s) => {
              'id': s['id'].toString(),
              'name': s['name'] ?? '',
            }),
          );
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(data['message'] ?? "Error")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }
  }

  Future<void> addProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    try {
      final url = Uri.parse("$baseUrl/add_project");

      final body = {
        "authentication_token": token,
        "name": nameController.text.trim(),
        "clientid": selectedClient ?? "",
        "billing_type": selectedBillingType ?? "",
        "status": selectedStatus ?? "",
        "start_date":
        DateFormat('yyyy-MM-dd').format(startDate ?? DateTime.now()),
        "deadline": DateFormat('yyyy-MM-dd').format(endDate ?? DateTime.now()),
        "description": descriptionController.text.trim(),
      };

      // Add conditional values
      if (selectedBillingType == "1") {
        body["project_cost"] = rateController.text.trim();
      } else if (selectedBillingType == "2") {
        body["estimated_hours"] = hoursController.text.trim();
      }

      final response = await http.post(url, body: body);
      final data = jsonDecode(response.body);

      if (data['status'] == 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("✅ ${data['message']}")),
        );
        Navigator.pushReplacement(context, new MaterialPageRoute(builder: (context)=>ProjectsScreen()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ ${data['message']}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("❌ Error: $e")));
    }

    setState(() => isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Project"),
        backgroundColor: const Color(0xFF162232),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField("Project Name", nameController),
              _buildDropdown("Select Client", selectedClient, clients,
                      (v) => setState(() => selectedClient = v)),
              _buildDropdown("Select Billing Type", selectedBillingType,
                  billingTypes, (v) => setState(() => selectedBillingType = v)),
              if (selectedBillingType == "1")
                _buildTextField("Fixed Rate Amount (₹)", rateController),
              if (selectedBillingType == "2")
                _buildTextField("Total Project Hours", hoursController),
              _buildDropdown("Select Status", selectedStatus, statuses,
                      (v) => setState(() => selectedStatus = v)),
              _dateField("Start Date", startDate,
                      (d) => setState(() => startDate = d)),
              _dateField(
                  "End Date", endDate, (d) => setState(() => endDate = d)),
              _buildTextField("Description", descriptionController,
                  maxLines: 3, isRequired: false),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: isSubmitting ? null : addProject,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.cyan,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit",
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🔹 Helper Widgets
  Widget _buildTextField(String label, TextEditingController controller,
      {int maxLines = 1, bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: isRequired
            ? (v) => v == null || v.isEmpty ? "Please enter $label" : null
            : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String? selected,
      List<Map<String, dynamic>> list, Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: list.map((e) {
          return DropdownMenuItem<String>(
            value: e['id'].toString(),
            child: Text(e['name']),
          );
        }).toList(),
        onChanged: (v) => onChanged(v),
        validator: (v) => v == null ? "Select $label" : null,
      ),
    );
  }

  Widget _dateField(String label, DateTime? date, Function(DateTime) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) onPick(picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            date != null
                ? DateFormat.yMMMMd().format(date)
                : "Select $label",
            style: TextStyle(
              color: date != null ? Colors.black87 : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
