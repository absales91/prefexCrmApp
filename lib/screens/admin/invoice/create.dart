import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';
import 'package:techon_crm/screens/admin/invoice/view.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  final TextEditingController billingStreet = TextEditingController();
  final TextEditingController clientNote = TextEditingController();
  final TextEditingController terms = TextEditingController();

  DateTime? invoiceDate = DateTime.now();
  DateTime? dueDate = DateTime.now().add(const Duration(days: 7));

  String? selectedClient;
  String? selectedCurrency;
  List<String> selectedPaymentModes = [];

  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> currencies = [];
  List<Map<String, dynamic>> paymentModes = [];

  List<Map<String, dynamic>> items = [];

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
    _addNewItem(); // Add one default item row
  }

  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    try {
      final url = Uri.parse("${AppConstants.apiBase}/get_invoices_initial_data");
      final response = await http.post(url, body: {
        "authentication_token": token,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("customers");
        print(data['customers']);

        if (data['status'] == 1) {
          clientNote.text = (data['default_clientnote'] ?? '').toString();
          terms.text = (data['default_terms'] ?? '').toString();
          setState(() {
            clients = List<Map<String, dynamic>>.from(
              (data['customers'] ?? []).map((c) => {
                'id': c['userid'].toString(),
                'name': c['company'] ?? 'Unnamed',
              }),
            );

            currencies = List<Map<String, dynamic>>.from(
              (data['currencies'] ?? []).map((cur) => {
                'id': cur['id'].toString(),
                'code': cur['symbol'] != null
                    ? "${cur['name']} (${cur['symbol']})"
                    : cur['name'] ?? '',
              }),
            );

            paymentModes = List<Map<String, dynamic>>.from(
              (data['payment_modes'] ?? []).map((pm) => {
                'id': pm['id'].toString(),
                'name': pm['name'] ?? '',
              }),
            );
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching dropdown data: $e");
    }
  }

  Future<void> createInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final subtotal = _calculateSubtotal();
    final total = subtotal;

    final formattedItems = items.map((item) {
      return {
        "description": item['description'] ?? "",
        "long_description": item['long_description'] ?? "",
        "qty": item['qty'] ?? "1",
        "unit": item['unit'] ?? "",
        "rate": item['rate'] ?? "0",
        "taxes": item['taxes'] ?? [],
      };
    }).toList();

    final body = {
      "authentication_token": token,
      "clientid": selectedClient ?? "",
      "currency": selectedCurrency ?? "",
      "billing_street": billingStreet.text,
      "date": DateFormat("yyyy-MM-dd").format(invoiceDate!),
      "duedate": DateFormat("yyyy-MM-dd").format(dueDate!),
      "subtotal": subtotal.toStringAsFixed(2),
      "total": total.toStringAsFixed(2),
      "show_quantity_as": "qty",
      "clientnote": clientNote.text,
      "terms": terms.text,
      "newitems": jsonEncode(formattedItems),
    };

    for (int i = 0; i < selectedPaymentModes.length; i++) {
      body["allowed_payment_modes[$i]"] = selectedPaymentModes[i];
    }

    try {
      final url = Uri.parse("${AppConstants.apiBase}/add_invoice");
      final response = await http.post(url, body: body);

      debugPrint("🟦 CREATE INVOICE BODY: ${jsonEncode(body)}");
      debugPrint("🟩 RESPONSE: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ ${data['message']}")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InvoiceDetailScreen(
                invoiceId: data['invoice_id'].toString(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("⚠️ ${data['message']}")));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Server error: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }

    setState(() => isSubmitting = false);
  }

  double _calculateSubtotal() {
    return items.fold<double>(
      0,
          (sum, item) =>
      sum + ((double.tryParse(item['rate'].toString()) ?? 0.0) *
          (double.tryParse(item['qty'].toString()) ?? 1.0)),
    );
  }

  void _addNewItem() {
    setState(() {
      items.add({
        'description': '',
        'long_description': '',
        'qty': 1,
        'unit': 'Piece',
        'rate': 0.0,
        'taxes': [],
      });
    });
  }

  void _removeItem(int index) {
    setState(() => items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Invoice"),
        backgroundColor: const Color(0xFF162232),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dropdownField("Select Client", selectedClient, clients,
                      (v) => setState(() => selectedClient = v)),
              SizedBox(height: 10,),
              _buildDateRow(),
              _buildTextField("Billing Street", billingStreet),
              _dropdownField("Currency", selectedCurrency, currencies,
                      (v) => setState(() => selectedCurrency = v)),
              SizedBox(height: 10,),
              _dropdownField(
                "Select Payment Modes",
                null,
                paymentModes,
                    (v) =>
                    setState(() => selectedPaymentModes = List<String>.from(v)),
                isMultiSelect: true,
                isRequired: false,
                selectedValues: selectedPaymentModes,
              ),
              const Divider(),
              const Text("Items",
                  style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 6),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Item"),
                onPressed: _addNewItem,
              ),
              const SizedBox(height: 10),
              ...items.asMap().entries.map((entry) {
                int i = entry.key;
                var item = entry.value;
                return _buildItemCard(item, i);
              }).toList(),
              const Divider(),
              _buildTextField("Client Note", clientNote, isRequired: false),
              _buildTextField("Terms & Conditions", terms, isRequired: false),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isSubmitting ? null : createInvoice,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.cyan),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Create Invoice"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================== REUSABLE WIDGETS ========================= //

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: _dateField("Date", invoiceDate, (d) {
            setState(() => invoiceDate = d);
          }),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _dateField("Due Date", dueDate, (d) {
            setState(() => dueDate = d);
          }),
        ),
      ],
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
              date != null ? DateFormat.yMMMMd().format(date) : 'Select Date'),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      {TextInputType type = TextInputType.text,
        bool readOnly = false,
        bool isRequired = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: isRequired ? "$label *" : "$label (optional)",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: isRequired
            ? (v) => v == null || v.isEmpty ? "Please enter $label" : null
            : null,
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: item['description'],
              decoration: const InputDecoration(labelText: "Item Name"),
              onChanged: (v) => item['description'] = v,
            ),
            TextFormField(
              initialValue: item['long_description'],
              decoration: const InputDecoration(labelText: "Description"),
              onChanged: (v) => item['long_description'] = v,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['qty'].toString(),
                    decoration: const InputDecoration(labelText: "Qty"),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) =>
                    item['qty'] = double.tryParse(v) ?? 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: item['unit'],
                    decoration: const InputDecoration(labelText: "Unit"),
                    onChanged: (v) => item['unit'] = v,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['rate'].toString(),
                    decoration: const InputDecoration(labelText: "Rate"),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) =>
                    item['rate'] = double.tryParse(v) ?? 0.0,
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () => _removeItem(index),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  icon: const Icon(Icons.close, color: Colors.white),
                  label: const Text("Remove",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(
      String label,
      String? selected,
      List<Map<String, dynamic>> list,
      Function(dynamic) onChanged,
      {bool isRequired = true,
        bool isMultiSelect = false,
        List<String>? selectedValues}) {
    if (isMultiSelect) {
      return InkWell(
        onTap: () async {
          final result = await showDialog<List<String>>(
            context: context,
            builder: (context) {
              final tempSelected = List<String>.from(selectedValues ?? []);
              return StatefulBuilder(builder: (context, setStateDialog) {
                return AlertDialog(
                  title: Text(label),
                  content: SingleChildScrollView(
                    child: Column(
                      children: list.map((e) {
                        final id = e['id'].toString();
                        final name = e['name'] ?? e['code'] ?? 'Unknown';
                        final isSelected = tempSelected.contains(id);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(name),
                          onChanged: (checked) {
                            setStateDialog(() {
                              if (checked == true) {
                                tempSelected.add(id);
                              } else {
                                tempSelected.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context, tempSelected),
                      child: const Text("OK"),
                    ),
                  ],
                );
              });
            },
          );

          if (result != null) onChanged(result);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            (selectedValues != null && selectedValues!.isNotEmpty)
                ? list
                .where((e) => selectedValues!.contains(e['id'].toString()))
                .map((e) => e['name'] ?? e['code'])
                .join(', ')
                : 'Select $label',
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      isExpanded: true,
      value: selected,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      items: list
          .map((e) => DropdownMenuItem(
        value: e['id'].toString(),
        child: Text(e['name'] ?? e['code'] ?? 'Unknown'),
      ))
          .toList(),
      onChanged: (v) => onChanged(v),
      validator:
      isRequired ? (v) => v == null ? "Select $label" : null : null,
    );
  }
}
