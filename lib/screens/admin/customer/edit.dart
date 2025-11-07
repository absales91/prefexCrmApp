import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';
import 'package:techon_crm/screens/admin/customer/view.dart';

class EditCustomerScreen extends StatefulWidget {
  final dynamic customer;
  const EditCustomerScreen({super.key, required this.customer});

  @override
  State<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends State<EditCustomerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController companyName = TextEditingController();
  final TextEditingController vatNumber = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController website = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController city = TextEditingController();
  final TextEditingController state = TextEditingController();
  final TextEditingController zip = TextEditingController();

  // Billing
  final TextEditingController billingStreet = TextEditingController();
  final TextEditingController billingCity = TextEditingController();
  final TextEditingController billingState = TextEditingController();
  final TextEditingController billingZip = TextEditingController();

  // Shipping
  final TextEditingController shippingStreet = TextEditingController();
  final TextEditingController shippingCity = TextEditingController();
  final TextEditingController shippingState = TextEditingController();
  final TextEditingController shippingZip = TextEditingController();

  // Contact
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();

  // Dropdown selections
  String? selectedCountry;
  String? selectedBillingCountry;
  String? selectedShippingCountry;
  String? selectedCurrencyId;

  List<Map<String, dynamic>> countryList = [];
  bool isSubmitting = false;

  List<Map<String, String>> currencyList = [
    {"id": "1", "code": "INR"},
    {"id": "2", "code": "USD"},
    {"id": "3", "code": "EUR"},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCountries();
    _loadCustomerData();
  }

  // Prefill data
  void _loadCustomerData() {
    final c = widget.customer;
    companyName.text = c['company'] ?? '';
    firstName.text = c['firstname'] ?? '';
    lastName.text = c['lastname'] ?? '';
    email.text = c['email'] ?? '';
    vatNumber.text = c['vat']?.toString() ?? '';
    phone.text = c['phonenumber']?.toString() ?? '';
    website.text = c['website'] ?? '';
    address.text = c['address'] ?? '';
    city.text = c['city'] ?? '';
    state.text = c['state'] ?? '';
    zip.text = c['zip']?.toString() ?? '';

    selectedCurrencyId = c['default_currency']?.toString();
    selectedCountry = c['country']?.toString();
    selectedBillingCountry = c['billing_country']?.toString();
    selectedShippingCountry = c['shipping_country']?.toString();

    billingStreet.text = c['billing_street'] ?? '';
    billingCity.text = c['billing_city'] ?? '';
    billingState.text = c['billing_state'] ?? '';
    billingZip.text = c['billing_zip']?.toString() ?? '';

    shippingStreet.text = c['shipping_street'] ?? '';
    shippingCity.text = c['shipping_city'] ?? '';
    shippingState.text = c['shipping_state'] ?? '';
    shippingZip.text = c['shipping_zip']?.toString() ?? '';
  }

  // Fetch countries
  Future<void> fetchCountries() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please log in again")),
      );
      return;
    }

    try {
      final url = Uri.parse("${AppConstants.apiBase}/get_countries");
      final response =
      await http.post(url, body: {'authentication_token': token});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['countries'] != null) {
          setState(() {
            countryList = List<Map<String, dynamic>>.from(data['countries']);
          });
        }
      } else {
        countryList = [
          {"country_id": "101", "short_name": "India"},
          {"country_id": "231", "short_name": "United States"},
        ];
      }
    } catch (e) {
      countryList = [
        {"country_id": "101", "short_name": "India"},
        {"country_id": "231", "short_name": "United States"},
      ];
    }
  }

  // Update customer
  Future<void> updateCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";
    final clientId = widget.customer['userid'].toString();
    print(clientId);
    print(selectedCountry);

    try {
      final url = Uri.parse("${AppConstants.apiBase}/updateCustomer");

      final response = await http.post(
        url,
        body: {
          "authentication_token": token,
          "clientId": clientId, // ✅ REQUIRED FIELD (not customer_id)
          "company": companyName.text.trim(),
          // "firstname": firstName.text.trim(),
          // "lastname": lastName.text.trim(),
          // "email": email.text.trim(),
          "vat": vatNumber.text.trim(),
          "phonenumber": phone.text.trim(),
          "default_currency": selectedCurrencyId ?? "",
          "website": website.text.trim(),
          "address": address.text.trim(),
          "city": city.text.trim(),
          "state": state.text.trim(),
          "zip": zip.text.trim(),
          "country": selectedCountry ?? "",
          "billing_street": billingStreet.text.trim(),
          "billing_city": billingCity.text.trim(),
          "billing_state": billingState.text.trim(),
          "billing_zip": billingZip.text.trim(),
          "billing_country": selectedBillingCountry ?? "",
          "shipping_street": shippingStreet.text.trim(),
          "shipping_city": shippingCity.text.trim(),
          "shipping_state": shippingState.text.trim(),
          "shipping_zip": shippingZip.text.trim(),
          "shipping_country": selectedShippingCountry ?? "",
        },
      );

      print("Update Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ ${data['message']}")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => CustomerDetailsScreen(userId: widget.customer['userid']),
            ),
          );

        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("⚠️ ${data['message']}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server Error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }

    setState(() => isSubmitting = false);
  }


  // Common input field
  Widget buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.grey),
          ),
        ),
        validator: (value) =>
        value == null || value.isEmpty ? 'Required field' : null,
      ),
    );
  }

  // Dropdown for countries
  Widget buildCountryDropdown(String label, String? selectedId,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: countryList.any((c) => c['country_id'].toString() == selectedId)
            ? selectedId
            : null, // prevents assertion error
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        items: countryList
            .map((c) => DropdownMenuItem<String>(
          value: c['country_id'].toString(),
          child: Text(c['short_name']),
        ))
            .toList(),
        onChanged: onChanged,
        validator: (value) =>
        value == null ? 'Please select $label' : null,
      ),
    );
  }

  // Build UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Customer"),
        backgroundColor: const Color(0xFF162232),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Profile"),
            Tab(text: "Billing & Shipping"),
          ],
        ),
      ),
      body: countryList.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Profile Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildTextField("Company Name", companyName),
                  // buildTextField("First Name", firstName),
                  // buildTextField("Last Name", lastName),
                  // buildTextField("Email", email,
                  //     type: TextInputType.emailAddress),
                  buildTextField("VAT Number", vatNumber),
                  buildTextField("Phone", phone,
                      type: TextInputType.phone),
                  buildTextField("Website", website),
                  buildTextField("Address", address),
                  buildTextField("City", city),
                  buildTextField("State", state),
                  buildTextField("Zip Code", zip),
                  buildCountryDropdown("Select Country", selectedCountry,
                          (v) => setState(() => selectedCountry = v)),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: DropdownButtonFormField<String>(
                      value: selectedCurrencyId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: "Select Currency",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      items: currencyList
                          .map((currency) => DropdownMenuItem<String>(
                        value: currency['id'],
                        child: Text(currency['code']!),
                      ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedCurrencyId = v),
                      validator: (value) => value == null
                          ? 'Please select a currency'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: isSubmitting ? null : updateCustomer,
                    child: isSubmitting
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text("Update"),
                  ),
                ],
              ),
            ),

            // Billing & Shipping Tab
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  buildTextField("Billing Street", billingStreet),
                  buildTextField("Billing City", billingCity),
                  buildTextField("Billing State", billingState),
                  buildTextField("Billing Zip", billingZip),
                  buildCountryDropdown(
                      "Select Billing Country", selectedBillingCountry,
                          (v) =>
                          setState(() => selectedBillingCountry = v)),
                  buildTextField("Shipping Street", shippingStreet),
                  buildTextField("Shipping City", shippingCity),
                  buildTextField("Shipping State", shippingState),
                  buildTextField("Shipping Zip", shippingZip),
                  buildCountryDropdown(
                      "Select Shipping Country", selectedShippingCountry,
                          (v) =>
                          setState(() => selectedShippingCountry = v)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: isSubmitting ? null : updateCustomer,
                    child: isSubmitting
                        ? const CircularProgressIndicator(
                        color: Colors.white)
                        : const Text("Update"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
