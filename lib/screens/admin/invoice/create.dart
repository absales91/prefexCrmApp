import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';
import 'package:techon_crm/screens/admin/invoice/invoice_screen.dart';
import 'package:techon_crm/screens/admin/invoice/view.dart';

class CreateInvoiceScreen extends StatefulWidget {
  const CreateInvoiceScreen({super.key});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  // 🔹 Controllers
  final TextEditingController invoiceNumber = TextEditingController();
  final TextEditingController billingStreet = TextEditingController();
  final TextEditingController clientNote = TextEditingController();
  final TextEditingController terms = TextEditingController();

  DateTime invoiceDate = DateTime.now();
  DateTime dueDate = DateTime.now().add(const Duration(days: 7));

  String? selectedClient;
  String? selectedCurrency;
  List<String> selectedPaymentModes = [];

  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> currencies = [];
  List<Map<String, dynamic>> paymentModes = [];
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> items = [];

  String prefix = '';
  String number_format = '';
  String formatted_number = '';
  String next_number = '';

  @override
  void initState() {
    super.initState();
    fetchDropdownData();
  }

  Future<void> fetchDropdownData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Session expired, please log in again")),
      );
      return;
    }

    try {
      final url = Uri.parse("${AppConstants.apiBase}/get_invoices_initial_data");
      final response = await http.post(url, body: {"authentication_token": token});

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          setState(() {
            // 🟩 Pre-fill next invoice number if provided
            invoiceNumber.text =
                (data['next_invoice_number'] ?? 'INV-${DateTime.now().millisecondsSinceEpoch}')
                    .toString();
            prefix = data['prefix'].toString();
            number_format = data['number_format'].toString();
            next_number = data['next_number'].toString();
            clientNote.text = data['default_clientnote'];
            terms.text = data['default_terms'];


            allItems = List<Map<String, dynamic>>.from(
              (data['item_data']['items'] ?? []).map((c) => {
                'id': c['id'].toString(),
                'description': c['description'] ?? '',
                'long_description': c['long_description'] ?? '',
                'rate': double.tryParse(c['rate']?.toString() ?? '0') ?? 0.0,
                'unit': c['unit'] ?? 'Piece',
                'taxes': c['taxes'] ?? [],
              }),
            );

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }

  List<Map<String, dynamic>> _prepareNewItems() {
    return items.map((item) {
      List<Map<String, dynamic>> formattedTaxes = [];
      if (item['taxes'] != null && item['taxes'] is List) {
        for (var tax in item['taxes']) {
          formattedTaxes.add({
            "name": tax['name'] ?? "Tax ${tax['taxrate']}",
            "taxrate": tax['taxrate'].toString(),
          });
        }
      }

      return {
        "description": item['description'] ?? "",
        "long_description": item['long_description'] ?? "",
        "qty": item['qty'] ?? "1",
        "unit": item['unit'] ?? "",
        "rate": item['rate'] ?? "0",
        "taxes": formattedTaxes,
      };
    }).toList();
  }

  Future<void> createInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please add at least one item")),
      );
      return;
    }

    setState(() => isSubmitting = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final subtotal = _calculateSubtotal();
    final total = _calculateTotal();
    final newItems = _prepareNewItems();

    try {
      final url = Uri.parse("${AppConstants.apiBase}/add_invoice");
      final body = {
        "authentication_token": token,
        "cancel_merged_invoices": "false",
        "clientid": selectedClient ?? "",
        "currency": selectedCurrency ?? "",
        "recurring": "0",
        "show_quantity_as": "qty",
        "quantity": items.length.toString(),
        "subtotal": subtotal.toStringAsFixed(2),
        "discount_percent": "0",
        "discount_total": "0",
        "adjustment": "0",
        "total": total.toStringAsFixed(2),
        "billing_street": billingStreet.text.toString(),
        "newitems": jsonEncode(newItems),
        "date": DateFormat('yyyy-MM-dd').format(invoiceDate),
        "duedate": DateFormat('yyyy-MM-dd').format(dueDate),
        "clientnote": clientNote.text,
        "terms": terms.text,
        "prefix": prefix.toString(),
        "formatted_number": invoiceNumber.text.toString(),
        'number_format': number_format.toString(),
        "number": next_number.toString()
      };


      for (int i = 0; i < selectedPaymentModes.length; i++) {
        body["allowed_payment_modes[$i]"] = selectedPaymentModes[i];
      }

      print("🟦 Sending create_invoice body: ${jsonEncode(body)}");

      final response = await http.post(url, body: body);
      print("🟩 Response: ${response.statusCode} ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("✅ ${data['message']}")),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => InvoicesScreen(),
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
        SnackBar(content: Text("❌ Exception: $e")),
      );
    }

    setState(() => isSubmitting = false);
  }

  double _calculateSubtotal() {
    return items.fold<double>(0, (sum, item) {
      final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
      return sum + (qty * rate);
    });
  }

  double _calculateTotal() {
    double subtotal = 0.0;
    double totalTax = 0.0;

    for (var item in items) {
      final qty = double.tryParse(item['qty']?.toString() ?? '1') ?? 1;
      final rate = double.tryParse(item['rate']?.toString() ?? '0') ?? 0;
      final base = qty * rate;
      subtotal += base;

      if (item['taxes'] != null && item['taxes'] is List) {
        for (var tax in item['taxes']) {
          double taxRate = double.tryParse(tax['taxrate'].toString()) ?? 0.0;
          totalTax += (base * taxRate / 100);
        }
      }
    }

    return subtotal + totalTax;
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
    setState(() {
      items.removeAt(index);
    });
  }

  Widget _multiSelectDropdownField({
    required String label,
    required List<Map<String, dynamic>> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          List<String> tempSelected = List.from(selectedValues);

          final result = await showDialog<List<String>>(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: Text(label),
                content: StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView(
                        children: options.map((option) {
                          final id = option['id'].toString();
                          final name = option['name'] ?? 'Unnamed';
                          final isSelected = tempSelected.contains(id);
                          return CheckboxListTile(
                            title: Text(name),
                            value: isSelected,
                            onChanged: (bool? selected) {
                              setStateDialog(() {
                                if (selected == true) {
                                  tempSelected.add(id);
                                } else {
                                  tempSelected.remove(id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, tempSelected),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyan,
                    ),
                    child: const Text("Done", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );

          if (result != null) {
            onChanged(result);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            selectedValues.isEmpty
                ? "Select payment modes"
                : options
                .where((e) => selectedValues.contains(e['id'].toString()))
                .map((e) => e['name'])
                .join(', '),
            style: TextStyle(
              color: selectedValues.isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
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
              _buildTextField("Invoice Number", invoiceNumber, readOnly: true),
              _searchableClientDropdown(
                label: "Search Client",
                selectedClient: selectedClient,
                clients: clients,
                onChanged: (v) => setState(() => selectedClient = v),
              ),
              _buildDateRow(),
              _buildTextField("Billing Street", billingStreet, isRequired: false),
              _dropdownField("Currency", selectedCurrency, currencies,
                      (v) => setState(() => selectedCurrency = v)),
              _multiSelectDropdownField(
                label: "Select Payment Modes",
                options: paymentModes,
                selectedValues: selectedPaymentModes,
                onChanged: (List<String> selected) {
                  setState(() {
                    selectedPaymentModes = selected;
                  });
                },
              ),

              const SizedBox(height: 15),
              const Text("Items",
                  style: TextStyle(
                      color: Colors.cyan, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration.collapsed(hintText: "Add Item"),
                        items: allItems.map((i) {
                          return DropdownMenuItem<String>(
                            value: i['id'].toString(),
                            child: Text(i['description'] ?? 'Unnamed'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          final selected = allItems.firstWhere(
                                  (e) => e['id'].toString() == value,
                              orElse: () => {});
                          final description = selected['description'] ?? '';
                          final longDescription = selected['long_description'] ?? '';
                          final rate = double.tryParse(selected['rate']?.toString() ?? '0') ?? 0.0;
                          final unit = selected['unit'] ?? 'Piece';
                          final taxes = selected['taxes'] ?? [];
                          setState(() {
                            items.add({
                              'description': description,
                              'long_description': longDescription,
                              'qty': 1,
                              'unit': unit,
                              'rate': rate,
                              'taxes': taxes,
                            });
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("✅ '$description' added")),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _addNewItem,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              ...items.asMap().entries.map((e) => _buildItemCard(e.value, e.key)).toList(),
              _buildTextField("Client Note", clientNote),
              _buildTextField("Terms & Conditions", terms),
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

  // ✅ Helper widgets (same as before)
  Widget _buildTextField(String label, TextEditingController controller,
      {bool isRequired = true, bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
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

  Widget _buildItemCard(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: item['description'] ?? '',
              decoration: const InputDecoration(labelText: "Item Name"),
              onChanged: (v) => item['description'] = v,
            ),
            TextFormField(
              initialValue: item['long_description'] ?? '',
              decoration: const InputDecoration(labelText: "Description"),
              onChanged: (v) => item['long_description'] = v,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: item['qty']?.toString() ?? '1',
                    decoration: const InputDecoration(labelText: "Qty"),
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (v) => item['qty'] = double.tryParse(v) ?? 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: item['rate']?.toString() ?? '0',
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

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(child: _dateField("Date", invoiceDate, (d) => setState(() => invoiceDate = d))),
        const SizedBox(width: 10),
        Expanded(child: _dateField("Due Date", dueDate, (d) => setState(() => dueDate = d))),
      ],
    );
  }

  Widget _dateField(String label, DateTime date, Function(DateTime) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
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
          child: Text(DateFormat.yMMMMd().format(date)),
        ),
      ),
    );
  }

  Widget _dropdownField(String label, String? selected,
      List<Map<String, dynamic>> list, Function(dynamic) onChanged,
      {bool isMultiSelect = false,
        List<String>? selectedValues,
        bool isRequired = true}) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text("Loading..."),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: selected,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: list.map((e) {
          return DropdownMenuItem<String>(
            value: e['id'].toString(),
            child: Text(e['name'] ?? e['code'] ?? ''),
          );
        }).toList(),
        onChanged: (v) => onChanged(v),
        validator: isRequired
            ? (v) => v == null ? "Select $label" : null
            : null,
      ),
    );
  }

  Widget _searchableClientDropdown({
    required String label,
    required String? selectedClient,
    required List<Map<String, dynamic>> clients,
    required Function(String?) onChanged,
  }) {
    final selectedName = clients.firstWhere(
          (c) => c['id'].toString() == selectedClient,
      orElse: () => {'name': 'Select Client'},
    )['name'];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          String searchQuery = '';
          List<Map<String, dynamic>> filtered = clients;

          final result = await showDialog<String>(
            context: context,
            barrierDismissible: true,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setDialogState) {
                  return Dialog(
                    insetPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints:
                          const BoxConstraints(maxHeight: 500),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.all(12),
                                child: Text(
                                  "Select Client",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText: "Search client...",
                                    border: OutlineInputBorder(),
                                  ),
                                  onChanged: (query) {
                                    setDialogState(() {
                                      searchQuery = query.toLowerCase();
                                      filtered = clients
                                          .where((c) => c['name']
                                          .toString()
                                          .toLowerCase()
                                          .contains(searchQuery))
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final client = filtered[index];
                                    return ListTile(
                                      title: Text(client['name'] ?? 'Unnamed'),
                                      onTap: () =>
                                          Navigator.pop(context, client['id'].toString()),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("Cancel"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );

          if (result != null) {
            onChanged(result);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: Text(
            selectedName ?? 'Select Client',
            style: TextStyle(
              color: selectedClient != null ? Colors.black : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}
