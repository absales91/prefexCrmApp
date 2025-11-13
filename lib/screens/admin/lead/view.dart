import 'package:flutter/material.dart';

class LeadDetailScreen extends StatefulWidget {
  final Map<String, dynamic> lead;

  const LeadDetailScreen({super.key, required this.lead});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final lead = widget.lead;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lead Details"),
        actions: [
          IconButton(
              onPressed: () {
                // TODO: edit action
              },
              icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: () {
                // TODO: delete action
              },
              icon: const Icon(Icons.delete_outline)),
        ],
      ),

      body: Column(
        children: [
          _buildTabs(),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _profileTab(lead),
                _attachmentsTab(),
                _reminderTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 TOP TABS
  // ---------------------------------------------------------
  Widget _buildTabs() {
    return Container(
      // color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.blue,
        indicatorWeight: 3,
        labelColor: Colors.blue,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.person_outline), text: "Profile"),
          Tab(icon: Icon(Icons.attach_file), text: "Attachments"),
          Tab(icon: Icon(Icons.notifications_outlined), text: "Reminder"),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 PROFILE TAB (MAIN)
  // ---------------------------------------------------------
  Widget _profileTab(Map lead) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ---------- TOP CARD ----------
          _topProfileCard(lead),

          const SizedBox(height: 16),

          // ---------- COMPANY CARD ----------
          _companyCard(lead),

          const SizedBox(height: 16),

          // ---------- ADDRESS CARD ----------
          _addressCard(lead),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 TOP LEAD PROFILE CARD
  // ---------------------------------------------------------
  Widget _topProfileCard(Map lead) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // NAME + PRICE + SOURCE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead["name"] ?? "",
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          // color: Colors.black87
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lead["position"] ?? "N/A",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    (lead["lead_value"] ?? "0").toString(),
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  Text(
                    lead["source"] ?? "",
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(),

          // STATUS + DATE
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status
              Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    lead["status"] ?? "Status",
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              // Date
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    lead["dateadded"] ?? "",
                    style: const TextStyle(
                        fontSize: 12, color: Colors.black54),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 COMPANY CARD
  // ---------------------------------------------------------
  Widget _companyCard(Map lead) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Company"),
          _value(lead["company"] ?? "—"),

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Phone"),
                    _value(lead["phonenumber"] ?? "—"),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Website"),
                    _value(lead["website"] ?? "—"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 ADDRESS CARD
  // ---------------------------------------------------------
  Widget _addressCard(Map lead) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label("Address"),
          _value(lead["address"] ?? "—"),

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("City"),
                    _value(lead["city"] ?? "—"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("State"),
                    _value(lead["state"] ?? "—"),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Zip Code"),
                    _value(lead["zip"] ?? "—"),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label("Country"),
                    _value(lead["country"]?.toString() ?? "—"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 ATTACHMENTS TAB
  // ---------------------------------------------------------
  Widget _attachmentsTab() {
    return const Center(
      child: Text(
        "No attachments found",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 REMINDER TAB
  // ---------------------------------------------------------
  Widget _reminderTab() {
    return const Center(
      child: Text(
        "No reminders yet",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  // ---------------------------------------------------------
  // 🔹 HELPERS
  // ---------------------------------------------------------
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      // color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black38.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 2),
        )
      ],
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        // color: Colors.black54,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _value(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        // color: Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
