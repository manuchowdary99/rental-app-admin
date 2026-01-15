import 'package:flutter/material.dart';

import '../../../core/widgets/admin_widgets.dart';

class ComplaintsManagementScreen extends StatefulWidget {
  const ComplaintsManagementScreen({super.key});

  @override
  State<ComplaintsManagementScreen> createState() =>
      _ComplaintsManagementScreenState();
}

class _ComplaintsManagementScreenState
    extends State<ComplaintsManagementScreen> {
  String _filterStatus = 'All';
  String _filterPriority = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: Column(
          children: [
            /// TOP SECTION (SCROLL SAFE)
            SingleChildScrollView(
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  _buildStatsRow(),
                  _buildFilters(),
                ],
              ),
            ),

            /// COMPLAINTS LIST
            Expanded(child: _buildComplaintsList()),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF781C2E), Color(0xFF5A1521)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF781C2E).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complaints',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Handle customer support',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STATS ROW (FIXED) ----------------
  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          Expanded(
            child: StatCard(
              title: 'Total',
              value: '24',
              icon: Icons.assignment_outlined,
              color: Color(0xFF781C2E),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Open',
              value: '7',
              icon: Icons.error_outline_rounded,
              color: Color(0xFF8B2635),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: StatCard(
              title: 'Resolved',
              value: '17',
              icon: Icons.check_circle_outline_rounded,
              color: Color(0xFF9E2F3C),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- FILTERS ----------------
  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _statusChip('All'),
                _statusChip('Open'),
                _statusChip('In Progress'),
                _statusChip('Resolved'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Priority:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                _priorityChip('All'),
                _priorityChip('High'),
                _priorityChip('Medium'),
                _priorityChip('Low'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String value) =>
      _buildFilterChip(value, _filterStatus, (v) {
        setState(() => _filterStatus = v);
      });

  Widget _priorityChip(String value) =>
      _buildFilterChip(value, _filterPriority, (v) {
        setState(() => _filterPriority = v);
      }, isSmall: true);

  Widget _buildFilterChip(
    String filter,
    String current,
    Function(String) onTap, {
    bool isSmall = false,
  }) {
    final selected = filter == current;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(filter),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 12 : 16,
            vertical: isSmall ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF781C2E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? const Color(0xFF781C2E) : Colors.grey[300]!,
            ),
          ),
          child: Text(
            filter,
            style: TextStyle(
              fontSize: isSmall ? 10 : 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- COMPLAINTS LIST ----------------
  Widget _buildComplaintsList() {
    final complaints = _generateDummyComplaints().where((c) {
      final statusOk = _filterStatus == 'All' || c['status'] == _filterStatus;
      final priorityOk =
          _filterPriority == 'All' || c['priority'] == _filterPriority;
      return statusOk && priorityOk;
    }).toList();

    if (complaints.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.sentiment_satisfied_rounded,
          title: 'No complaints',
          subtitle: 'No complaints match your filters',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: complaints.length,
      itemBuilder: (context, index) {
        return _buildComplaintCard(complaints[index]);
      },
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    return AdminCard(
      onTap: () => _showComplaintDetails(complaint),
      child: Text(
        complaint['title'],
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ---------------- HELPERS (UNCHANGED LOGIC) ----------------
  void _showComplaintDetails(Map<String, dynamic> complaint) {}
  List<Map<String, dynamic>> _generateDummyComplaints() => [
    {
      'id': '#CMP-001',
      'title': 'Item delivered damaged',
      'status': 'Open',
      'priority': 'High',
    },
    {
      'id': '#CMP-002',
      'title': 'Late delivery',
      'status': 'Resolved',
      'priority': 'Medium',
    },
  ];
}
