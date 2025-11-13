import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:techon_crm/constant.dart';
import 'package:techon_crm/screens/admin/invoice/view.dart';

class EditInvoiceScreen extends StatefulWidget {
  final dynamic invoiceData;
  const EditInvoiceScreen({super.key, required this.invoiceData});

  @override
  State<EditInvoiceScreen> createState() => _EditInvoiceScreenState();
}

class _EditInvoiceScreenState extends State<EditInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isSubmitting = false;

  final TextEditingController invoiceNumber = TextEditingController();
  final TextEditingController billingStreet = TextEditingController();
  final TextEditingController clientNote = TextEditingController();
  final TextEditingController terms = TextEditingController();

  DateTime? invoiceDate;
  DateTime? dueDate;

  String? selectedClient;
  String? selectedCurrency;
  List<String> selectedPaymentModes = [];

  List<Map<String, dynamic>> clients = [];
  List<Map<String, dynamic>> currencies = [];
  List<Map<String, dynamic>> paymentModes = [];

  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> allItems = [];

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
    fetchDropdownData();
  }
  List<Map<String, dynamic>> _prepareNewItems() {
    // Only include items that don't have a database ID
    return items
        .where((item) =>
    item['id'] == null || item['id'].toString().startsWith('temp_'))
        .map((item) {
      // Make sure tax format matches backend requirement
      List<Map<String, dynamic>> formattedTaxes = [];
      if (item['taxes'] != null && item['taxes'] is List) {
        for (var tax in item['taxes']) {
          if (tax is Map && tax.containsKey('taxrate')) {
            formattedTaxes.add({
              "name": tax['name'] ?? "Tax ${tax['taxrate']}",
              "taxrate": tax['taxrate'].toString(),
            });
          } else if (tax is num || tax is String) {
            formattedTaxes.add({
              "name": "Tax $tax",
              "taxrate": tax.toString(),
            });
          }
        }
      }

      return {
        "id": 0,
        "description": item['description'] ?? "",
        "long_description": item['long_description'] ?? "",
        "qty": item['qty'] ?? "1",
        "unit": item['unit'] ?? "",
        "rate": item['rate'] ?? "0",
        "taxes": formattedTaxes,
      };
    }).toList();
  }

  void _loadInvoiceData() {
    final inv = widget.invoiceData;
    invoiceNumber.text = inv['formatted_number'] ?? '';
    billingStreet.text = inv['billing_street'] ?? '';
    clientNote.text = inv['clientnote'] ?? '';
    terms.text = inv['terms'] ?? '';

    selectedClient = inv['clientid']?.toString();
    selectedCurrency = inv['currency']?.toString();
    selectedPaymentModes = [];

    final rawModes = inv['allowed_payment_modes'] ?? inv['payment_modes'];
    if (rawModes != null && rawModes is List) {
      selectedPaymentModes = rawModes.map((m) => m.toString()).toList();
    }
    print("paymentModes");
    print(inv);



    invoiceDate = DateTime.tryParse(inv['date'] ?? '') ?? DateTime.now();
    dueDate = DateTime.tryParse(inv['duedate'] ?? '') ?? DateTime.now();

    if (inv['items'] != null) {
      items = List<Map<String, dynamic>>.from(inv['items'].map((i) => {
        'id': i['id'],
        'description': i['description'],
        'long_description': i['long_description'] ?? '',
        'qty': i['qty'] ?? 1,
        'unit': i['unit'] ?? 'Piece',
        'rate': i['rate'] ?? 0.0,
        'taxes': i['taxes'] ?? [],
      }));
    }
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

      final response = await http.post(url, body: {
        "authentication_token": token,
      });

      print("🔹 Fetch Dropdown Response: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 1) {
          print('items');
          print(data['item_data']['items']);
          setState(() {

                allItems = List<Map<String, dynamic>>.from(
              (data['item_data']['items'] ?? []).map((c) => {
                'id': c['id'].toString(),
                'description': c['description'] ?? 'Unnamed',
                'long_description': c['long_description'] ?? '',
                'rate': double.tryParse(c['rate']?.toString() ?? '0') ?? 0.0,
                'unit': c['unit'] ?? 'Piece',
                'taxes': c['taxes'] ?? [],
              }),
            );

            // ✅ Clients
            clients = List<Map<String, dynamic>>.from(
              (data['customers'] ?? []).map((c) => {
                'id': c['userid'].toString(),
                'name': c['company'] ?? 'Unnamed',
              }),
            );

            // ✅ Currencies
            currencies = List<Map<String, dynamic>>.from(
              (data['currencies'] ?? []).map((cur) => {
                'id': cur['id'].toString(),
                'code': cur['symbol'] != null
                    ? "${cur['name']} (${cur['symbol']})"
                    : cur['name'] ?? '',
              }),
            );

            // ✅ Payment Modes
            paymentModes = List<Map<String, dynamic>>.from(
              (data['payment_modes'] ?? []).map((pm) => {
                'id': pm['id'].toString(),
                'name': pm['name'] ?? '',
              }),
            );
          });
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
        SnackBar(content: Text("❌ Error fetching dropdowns: $e")),
      );
    }
  }


  Future<void> updateInvoice() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? "";

    final invoiceId = widget.invoiceData['id'].toString();

    // 🧮 Calculate subtotal and total
    final subtotal = _calculateSubtotal();
    final total = _calculateTotal();

    // 🧾 Prepare new items only (for Perfex API)
    final newItems = _prepareNewItems();
    print("🟩 Prepared New Items: ${jsonEncode(newItems)}");
    // 🧾 Prepare new items only (for Perfex API)



    try {
      final url = Uri.parse("${AppConstants.apiBase}/update_invoice");

      final body = {
        "authentication_token": token,
        "invoiceId": invoiceId,
        "clientid": selectedClient ?? "",
        "currency": selectedCurrency ?? "",
        "show_quantity_as": "qty",
        "quantity": items.length.toString(),
        "subtotal": subtotal.toStringAsFixed(2),
        "discount_percent": "0",
        "discount_total": "0",
        "adjustment": "0",
        "total": total.toStringAsFixed(2),
        "billing_street": billingStreet.text.toString(),
        "newitems": jsonEncode(newItems), // ✅ send as JSON
        "removed_items": jsonEncode(removedItemIds),


      };

      // ✅ Payment Modes Array
      for (int i = 0; i < selectedPaymentModes.length; i++) {
        body["allowed_payment_modes[$i]"] = selectedPaymentModes[i];
      }

      print("🟦 Sending update_invoice body: ${jsonEncode(body)}");

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
              builder: (_) => InvoiceDetailScreen(invoiceId: invoiceId),
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

      // tax calculation
      if (item['taxes'] != null && item['taxes'] is List) {
        for (var tax in item['taxes']) {
          double taxRate = 0.0;
          if (tax is Map && tax.containsKey('taxrate')) {
            taxRate = double.tryParse(tax['taxrate'].toString()) ?? 0.0;
          } else if (tax is num || tax is String) {
            taxRate = double.tryParse(tax.toString()) ?? 0.0;
          }
          totalTax += (base * taxRate / 100);
        }
      }
    }

    return subtotal + totalTax;
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
                    insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom, // ✅ adjusts for keyboard
                      ),
                      child: SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 500), // ✅ limit dialog height
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
                                padding: const EdgeInsets.symmetric(horizontal: 12),
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
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



  void _addNewItem() {
    setState(() {
      items.add({
        'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', // temp ID
        'description': '',
        'long_description': '',
        'qty': 1,
        'unit': 'Piece',
        'rate': 0.0,
        'taxes': [],
      });
    });
  }


  List<String> removedItemIds = [];

  void _removeItem(int index) {
    final item = items[index];
    // If it's an existing DB item (not temp_), mark for removal
    if (item['id'] != null && !item['id'].toString().startsWith('temp_')) {
      removedItemIds.add(item['id'].toString());
    }
    setState(() {
      items.removeAt(index);
    });
  }


  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        TextInputType type = TextInputType.text,
        bool readOnly = false,
        bool isRequired = true, // 🔹 new flag added
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        readOnly: readOnly,
        decoration: InputDecoration(
          label: RichText(
            text: TextSpan(
              text: label,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
              children: [
                if (isRequired)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  )
                else
                  const TextSpan(
                    text: ' (optional)',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
              ],
            ),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: isRequired
            ? (v) => v == null || v.isEmpty ? "Please enter $label" : null
            : null, // 🔹 no validation if not required
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Update Invoice"),

      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("Number", invoiceNumber, readOnly: true),
              _searchableClientDropdown(
                label: "Search Client",
                selectedClient: selectedClient,
                clients: clients,
                onChanged: (v) => setState(() => selectedClient = v),
              ),


              _buildDateRow(),
              _buildTextField("Billing Street", billingStreet,isRequired: false),
              _dropdownField("Currency", selectedCurrency, currencies,
                      (v) => setState(() => selectedCurrency = v)),
              _dropdownField(
                "Select Payment Mode",
                null,
                paymentModes,
                    (v) => setState(() => selectedPaymentModes = List<String>.from(v)),
                isMultiSelect: true,
                isRequired: false,
                selectedValues: selectedPaymentModes,
              ),


              const SizedBox(height: 15),
              const Text("Items",
                  style: TextStyle(
                      color: Colors.cyan,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
              const SizedBox(height: 6),
              const SizedBox(height: 15),
              // 🧾 ITEMS SECTION
              const SizedBox(height: 15),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Items",
                      style: TextStyle(
                        color: Colors.cyan,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        "Show Quantity As: ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Icon(Icons.radio_button_checked, size: 16, color: Colors.grey),
                      const Text(" Qty"),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

// 🧩 Add Item Row (Dropdown + Plus Button)
              // 🧩 Add Item Row (Dropdown + Plus Button)
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

                          // 🟢 Find the selected item in allItems
                          final selected = allItems.firstWhere(
                                (e) => e['id'].toString() == value,
                            orElse: () => {},
                          );

                          // 🟢 Extract item details (safe defaults if missing)
                          final description = selected['description'] ?? '';
                          final longDescription = selected['long_description'] ?? '';
                          final rate = double.tryParse(selected['rate']?.toString() ?? '0') ?? 0.0;
                          final unit = selected['unit'] ?? 'Piece';
                          final taxes = selected['taxes'] ?? [];

                          // 🟢 Add it to invoice items
                          setState(() {
                            items.add({
                              // 'id': selected['id'],
                              'id': 'temp_${DateTime.now().millisecondsSinceEpoch}', // temp ID
                              'description': description,
                              'long_description': longDescription,
                              'qty': 1,
                              'unit': unit,
                              'rate': rate,
                              'taxes': taxes,
                            });
                          });

                          // Optional: show confirmation
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

// 🧮 Existing Added Items


              const SizedBox(height: 10),
              ...items.asMap().entries.map((entry) {
                int i = entry.key;
                var item = entry.value;
                return _buildItemCard(item, i);
              }).toList(),
              _buildTextField("Client Note", clientNote),
              _buildTextField("Terms & Conditions", terms),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: isSubmitting ? null : updateInvoice,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    backgroundColor: Colors.cyan),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Update"),
              ),
            ],
          ),
        ),
      ),
    );
  }

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

  Widget _dropdownField(
      String label,
      String? selected,
      List<Map<String, dynamic>> list,
      Function(dynamic) onChanged, {
        bool isRequired = true,
        bool isMultiSelect = false, // 🔹 New flag for multiple selection
        List<String>? selectedValues, // for multi-select use
      }) {
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

    // label styling
    final labelWidget = RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(color: Colors.grey, fontSize: 16),
        children: [
          if (isRequired)
            const TextSpan(
              text: ' *',
              style: TextStyle(color: Colors.red),
            )
          else
            const TextSpan(
              text: ' (optional)',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
        ],
      ),
    );

    if (isMultiSelect) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: InkWell(
          onTap: () async {
            // 🟢 ensure the list is not empty and IDs match strings
            final result = await showDialog<List<String>>(
              context: context,
              builder: (context) {
                // 🟢 copy selected values as String list
                final tempSelected = List<String>.from(selectedValues ?? []);

                return StatefulBuilder(
                  builder: (context, setStateDialog) {
                    return AlertDialog(
                      title: Text(label),
                      content: SingleChildScrollView(
                        child: Column(
                          children: list.map((e) {
                            final id = e['id'].toString();
                            final name = e['name'] ?? e['code'] ?? 'Unknown';

                            // ✅ Auto select if id already in selectedValues
                            final isSelected = tempSelected.contains(id);

                            return CheckboxListTile(
                              value: isSelected,
                              title: Text(name),
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (checked) {
                                setStateDialog(() {
                                  if (checked == true) {
                                    if (!tempSelected.contains(id)) {
                                      tempSelected.add(id);
                                    }
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
                  },
                );
              },
            );

            if (result != null) {
              // 🔥 Update the parent widget’s state with the selected values
              onChanged(result);
            }
          },
          child: InputDecorator(
            decoration: InputDecoration(
              label: labelWidget,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              (selectedValues != null && selectedValues!.isNotEmpty)
                  ? list
                  .where((e) => selectedValues!.contains(e['id'].toString()))
                  .map((e) => e['name'] ?? e['code'])
                  .join(', ')
                  : 'Select $label',
              style: TextStyle(
                color: (selectedValues != null && selectedValues!.isNotEmpty)
                    ? Colors.black
                    : Colors.grey,
              ),
            ),
          ),
        ),
      );
    }



    // 🟣 Single-select dropdown (default)
    final validSelected = list.any((e) => e['id'].toString() == selected)
        ? selected
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        value: validSelected,
        decoration: InputDecoration(
          label: labelWidget,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: list.map((e) {
          return DropdownMenuItem<String>(
            value: e['id'].toString(),
            child: Text(
              e['name'] ?? e['code'] ?? 'Unknown',
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: (v) {
          FocusScope.of(context).unfocus();
          onChanged(v);
        },
        validator: isRequired
            ? (v) => v == null ? "Select $label" : null
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
              initialValue: item['description']?.toString() ?? '',
              decoration: const InputDecoration(labelText: "Item Name"),
              onChanged: (v) => item['description'] = v,
            ),
            TextFormField(
              initialValue: item['long_description']?.toString() ?? '',
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
                    initialValue: item['unit']?.toString() ?? 'Piece',
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

}
