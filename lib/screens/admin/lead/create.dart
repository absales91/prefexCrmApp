import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CreateLeadScreen extends StatefulWidget {
  const CreateLeadScreen({Key? key}) : super(key: key);

  @override
  State<CreateLeadScreen> createState() => _CreateLeadScreenState();
}

class _CreateLeadScreenState extends State<CreateLeadScreen> {
  final _formKey = GlobalKey<FormState>();

  // API Base URL
  final String baseUrl = "https://crm.msmesoftwares.com/perfex_mobile_app_api";

  // Dynamic data
  List<dynamic> leadStatus = [];
  List<dynamic> leadSources = [];
  List<dynamic> countries = [];
  List<dynamic> assignees = [];
  List<dynamic> customFields = [];

  // Selected values
  String? selectedSource;
  String? selectedStatus;
  String? selectedAssignee;
  String? selectedCountry;

  bool loading = true;

  // Text controllers
  final nameCtrl = TextEditingController();
  final leadValueCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final companyCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadInitialData();
  }

  // -------------------------------------------------
  // 🔥 FETCH INITIAL FORM DATA
  // -------------------------------------------------
  Future<void> loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    try {
      final url = Uri.parse("$baseUrl/get_initial_lead_form");
      final response =
      await http.post(url, body: {"authentication_token": token});

      print("Lead Form => ${response.body}");

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        setState(() {
          leadStatus = json["leadStatus"] ?? [];
          leadSources = json["source"] ?? [];
          countries = json["countries"] ?? [];
          assignees = json["assignees"] ?? [];
          customFields = json["customFields"] ?? [];

          // Default values
          selectedSource = json["defaultSelectedFields"]["leads_default_source"]?.toString();
          selectedStatus = json["defaultSelectedFields"]["leads_default_status"]?.toString();
          selectedCountry = json["defaultSelectedFields"]["leads_default_country"]?.toString();

          loading = false;
        });
      }
    } catch (e) {
      print("Error loading lead form: $e");
      setState(() => loading = false);
    }
  }

  Future<void> submitLead() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token") ?? "";

    // Convert selected dropdown IDs back to Text (required by API)
    final src = leadSources.firstWhere(
          (e) => e["id"].toString() == selectedSource,
      orElse: () => {},
    );
    String sourceName = src.isNotEmpty ? src["name"] : "";

    final st = leadStatus.firstWhere(
          (e) => e["id"].toString() == selectedStatus,
      orElse: () => {},
    );
    String statusName = st.isNotEmpty ? st["name"] : "";

    final ass = assignees.firstWhere(
          (e) => e["staffid"].toString() == selectedAssignee,
      orElse: () => {},
    );
    String assignedName = ass.isNotEmpty
        ? "${ass['firstname']} ${ass['lastname']}"
        : "";

    final c = countries.firstWhere(
          (e) => e["country_id"].toString() == selectedCountry,
      orElse: () => {},
    );
    String countryName = c.isNotEmpty ? c["long_name"] : "";

    // BODY DATA TO SEND
    final body = {
      "authentication_token": token,
      "status": statusName,
      "source": sourceName,
      "name": nameCtrl.text.trim(),
      "email": emailCtrl.text.trim(),
      "phonenumber": phoneCtrl.text.trim(),
      "company": companyCtrl.text.trim(),
      "address": addressCtrl.text.trim(),
      "assigned": assignedName,
      "country": countryName,
      "is_public": "false",
      "custom_fields": jsonEncode({}),
    };

    print("Sending Lead => $body");

    final url = Uri.parse("$baseUrl/add_lead");
    final response = await http.post(url, body: body);

    print("Add Lead Response => ${response.body}");

    final json = jsonDecode(response.body);

    if (json["status"] == 1) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Success"),
          content: const Text("Lead created successfully!"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(json["message"] ?? "Failed to create lead")),
      );
    }
  }



  // -------------------------------------------------
  // 🔥 UI
  // -------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create New Lead")),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _dropdown(
                label: "Lead Source",
                value: selectedSource,
                items: leadSources,
                getLabel: (item) => item["name"],
                getValue: (item) => item["id"].toString(),
                onChanged: (v) => setState(() => selectedSource = v),
              ),

              _dropdown(
                label: "Lead Status",
                value: selectedStatus,
                items: leadStatus,
                getLabel: (item) => item["name"],
                getValue: (item) => item["id"].toString(),
                onChanged: (v) => setState(() => selectedStatus = v),
              ),

              _dropdown(
                label: "Assign Staff",
                value: selectedAssignee,
                items: assignees,
                getLabel: (item) =>
                "${item["firstname"]} ${item["lastname"]}",
                getValue: (item) => item["staffid"].toString(),
                onChanged: (v) => setState(() => selectedAssignee = v),
              ),

              _textField("Lead Name", nameCtrl),
              _textField("Lead Value", leadValueCtrl),
              _textField("Email", emailCtrl),
              _textField("Phone", phoneCtrl),
              _textField("Company", companyCtrl),
              _textField("Address", addressCtrl, maxLines: 3),

              const SizedBox(height: 20),

              // CUSTOM FIELDS FROM API
              ...customFields.map((field) {
                return _textField(
                  field["name"],
                  TextEditingController(),
                  isRequired: field["required"] == "1",
                );
              }),

              const SizedBox(height: 20),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------
  // 🔥 COMPONENTS
  // -------------------------------------------------

  Widget _dropdown({
    required String label,
    required String? value,
    required List items,
    required String Function(dynamic) getLabel,
    required String Function(dynamic) getValue,
    required Function(String?) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        // color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(labelText: label, border: InputBorder.none),
        items: items
            .map((item) => DropdownMenuItem(
          value: getValue(item),
          child: Text(getLabel(item)),
        ))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? "Please select $label" : null,
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller,
      {int maxLines = 1, bool isRequired = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: isRequired
            ? (value) =>
        value == null || value.isEmpty ? "Please enter $label" : null
            : null,
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: submitLead,
        style: ElevatedButton.styleFrom(
          // backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          "Create Lead",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
