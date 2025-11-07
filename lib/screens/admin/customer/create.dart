import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';

class AddCustomerScreen extends StatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  State<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends State<AddCustomerScreen>
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

  // contact
  // Contact
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController email = TextEditingController();


  String? selectedCurrency;
  String? selectedCountry;
  String? selectedBillingCountry;
  String? selectedShippingCountry;

  List<Map<String, String>> currencyList = [
    {"id": "1", "code": "INR"},
    {"id": "2", "code": "USD"},
    {"id": "3", "code": "EUR"},
  ];
  String? selectedCurrencyId;

  List<String> countries = [];
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchCountries();
  }

  // 🔹 Fetch Country List from Perfex CRM API
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
      final response = await http.post(url, body: {'authentication_token': token});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1 && data['countries'] != null) {
          final countryList = List<Map<String, dynamic>>.from(data['countries']);
          setState(() {
            countries = countryList
                .map((e) => "${e['country_id']}|${e['short_name']}")
                .toList();
          });
        }
      } else {
        countries = ["101|India", "231|United States"];
      }
    } catch (e) {
      countries = ["101|India", "231|United States"];
    }
  }


  // 🔹 Add Customer to Perfex CRM
  Future<void> createCustomer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please log in again")),
      );
      setState(() => isSubmitting = false);
      return;
    }

    try {
      final url = Uri.parse("${AppConstants.apiBase}/addCustomer");

      // ⚠️ Do NOT use JSON encoding here
      final response = await http.post(
        url,
        // no headers — defaults to x-www-form-urlencoded
        body: {
          "authentication_token": token,
          "company": companyName.text.trim(),
          "firstname": firstName.text.trim(),
          "lastname": lastName.text.trim(),
          "email": email.text.trim(),
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

      print("Raw Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ ${data['message']}")),
          );
          Navigator.pop(context);
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


  // 🔹 Common UI Elements
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

  Widget buildDropdown(String label, String? selected, List<String> items,
      void Function(String?) onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: DropdownButtonFormField<String>(
        value: selected,
        isExpanded: true,
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
        items: items
            .map((e) => DropdownMenuItem<String>(
          value: e,
          child: Text(e),
        ))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? 'Please select $label' : null,
      ),
    );
  }

  // 🔹 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Customer"),
        backgroundColor: const Color(0xFF162232),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Profile"),
            Tab(text: "Billing & Shipping"),
          ],
        ),
      ),
      body: Form(
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
                  buildTextField("First Name", firstName),
                  buildTextField("Last Name", lastName),
                  buildTextField("Email", email, type: TextInputType.emailAddress),

                  buildTextField("VAT Number", vatNumber),
                  buildTextField("Phone", phone, type: TextInputType.phone),
                  buildTextField("Website", website),
                  buildTextField("Address", address),
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
                      items: currencyList.map((currency) {
                        return DropdownMenuItem<String>(
                          value: currency['id'],           // store the numeric ID
                          child: Text(currency['code']!),  // display name (INR, USD, etc.)
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => selectedCurrencyId = v),
                      validator: (value) =>
                      value == null ? 'Please select a currency' : null,
                    ),
                  ),

                  buildTextField("City", city),
                  buildTextField("State", state),
                  buildTextField("Zip Code", zip),
                  buildDropdown("Select Country", selectedCountry, countries,
                          (v) => setState(() => selectedCountry = v)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: isSubmitting ? null : createCustomer,
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit"),
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
                  buildDropdown("Select Billing Country", selectedBillingCountry,
                      countries, (v) => setState(() => selectedBillingCountry = v)),
                  buildTextField("Shipping Street", shippingStreet),
                  buildTextField("Shipping City", shippingCity),
                  buildTextField("Shipping State", shippingState),
                  buildTextField("Shipping Zip", shippingZip),
                  buildDropdown("Select Shipping Country",
                      selectedShippingCountry, countries,
                          (v) => setState(() => selectedShippingCountry = v)),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.cyan,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed: isSubmitting ? null : createCustomer,
                    child: isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Submit"),
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
