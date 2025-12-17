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
            _buildHeader(),
            _buildStatsRow(),
            _buildFilters(),
            Expanded(child: _buildComplaintsList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 24,
            ),
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

  Widget _buildStatsRow() {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: const Row(
        children: [
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

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Status Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', _filterStatus, (value) {
                  setState(() => _filterStatus = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Open', _filterStatus, (value) {
                  setState(() => _filterStatus = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('In Progress', _filterStatus, (value) {
                  setState(() => _filterStatus = value);
                }),
                const SizedBox(width: 8),
                _buildFilterChip('Resolved', _filterStatus, (value) {
                  setState(() => _filterStatus = value);
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Priority Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  'Priority: ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                _buildFilterChip('All', _filterPriority, (value) {
                  setState(() => _filterPriority = value);
                }, isSmall: true),
                const SizedBox(width: 6),
                _buildFilterChip('High', _filterPriority, (value) {
                  setState(() => _filterPriority = value);
                }, isSmall: true),
                const SizedBox(width: 6),
                _buildFilterChip('Medium', _filterPriority, (value) {
                  setState(() => _filterPriority = value);
                }, isSmall: true),
                const SizedBox(width: 6),
                _buildFilterChip('Low', _filterPriority, (value) {
                  setState(() => _filterPriority = value);
                }, isSmall: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String filter,
    String currentFilter,
    Function(String) onTap, {
    bool isSmall = false,
  }) {
    final isSelected = currentFilter == filter;
    return GestureDetector(
      onTap: () => onTap(filter),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 16,
          vertical: isSmall ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF781C2E) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF781C2E) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          filter,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: isSmall ? 10 : 12,
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintsList() {
    final complaints = _generateDummyComplaints();

    final filteredComplaints = complaints.where((complaint) {
      bool statusMatch =
          _filterStatus == 'All' || complaint['status'] == _filterStatus;
      bool priorityMatch =
          _filterPriority == 'All' || complaint['priority'] == _filterPriority;
      return statusMatch && priorityMatch;
    }).toList();

    if (filteredComplaints.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.sentiment_satisfied_rounded,
          title: 'No complaints',
          subtitle: 'No complaints match your current filters',
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: filteredComplaints.length,
      itemBuilder: (context, index) {
        final complaint = filteredComplaints[index];
        return _buildComplaintCard(complaint);
      },
    );
  }

  Widget _buildComplaintCard(Map<String, dynamic> complaint) {
    return AdminCard(
      onTap: () => _showComplaintDetails(complaint),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getPriorityColor(complaint['priority']),
                      _getPriorityColor(complaint['priority']).withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getComplaintIcon(complaint['type']),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          complaint['id'],
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        StatusChip(
                          text: complaint['priority'],
                          color: _getPriorityColor(complaint['priority']),
                          isSmall: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      complaint['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'By ${complaint['customerName']} • ${complaint['timeAgo']}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            complaint['description'],
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.4,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              StatusChip(
                text: complaint['status'],
                color: _getStatusColor(complaint['status']),
                icon: _getStatusIcon(complaint['status']),
                isSmall: true,
              ),
              const SizedBox(width: 8),
              if (complaint['orderReference'] != null)
                StatusChip(
                  text: complaint['orderReference'],
                  color: Colors.blue,
                  icon: Icons.link_rounded,
                  isSmall: true,
                ),
              const Spacer(),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showComplaintDetails(Map<String, dynamic> complaint) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: _buildComplaintDetailsContent(complaint),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildComplaintDetailsContent(Map<String, dynamic> complaint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Complaint Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            StatusChip(
              text: complaint['status'],
              color: _getStatusColor(complaint['status']),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Complaint Info
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StatusChip(
                    text: complaint['priority'],
                    color: _getPriorityColor(complaint['priority']),
                  ),
                  const SizedBox(width: 8),
                  StatusChip(text: complaint['type'], color: Colors.purple),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                complaint['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                complaint['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('Complaint ID', complaint['id']),
              const SizedBox(height: 12),
              _buildDetailRow('Customer', complaint['customerName']),
              const SizedBox(height: 12),
              _buildDetailRow('Email', complaint['customerEmail']),
              const SizedBox(height: 12),
              _buildDetailRow('Phone', complaint['customerPhone']),
              const SizedBox(height: 12),
              _buildDetailRow('Submitted', complaint['timeAgo']),
              if (complaint['orderReference'] != null) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Related Order', complaint['orderReference']),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Admin Response Section
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Response',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F6EE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: TextField(
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Type your response here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.transparent,
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: AdminButton(
                      text: 'Send Response',
                      icon: Icons.send_rounded,
                      onPressed: () => _sendResponse(complaint),
                    ),
                  ),
                  const SizedBox(width: 12),
                  AdminButton(
                    text: 'Template',
                    isOutlined: true,
                    icon: Icons.library_books_rounded,
                    onPressed: _showResponseTemplates,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Status Actions
        if (complaint['status'] != 'Resolved') ...[
          Row(
            children: [
              Expanded(
                child: AdminButton(
                  text: complaint['status'] == 'Open'
                      ? 'Mark In Progress'
                      : 'Mark Resolved',
                  color: complaint['status'] == 'Open'
                      ? Colors.orange
                      : Colors.green,
                  icon: complaint['status'] == 'Open'
                      ? Icons.play_arrow_rounded
                      : Icons.check_rounded,
                  onPressed: () => _updateComplaintStatus(complaint),
                ),
              ),
              const SizedBox(width: 12),
              AdminButton(
                text: 'Escalate',
                isOutlined: true,
                color: Colors.red,
                icon: Icons.priority_high_rounded,
                onPressed: () => _escalateComplaint(complaint),
              ),
            ],
          ),
        ] else ...[
          SizedBox(
            width: double.infinity,
            child: AdminButton(
              text: 'Reopen Complaint',
              color: Colors.orange,
              icon: Icons.replay_rounded,
              onPressed: () => _reopenComplaint(complaint),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1E293B),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  void _sendResponse(Map<String, dynamic> complaint) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Response sent to customer'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showResponseTemplates() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Response Templates',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 16),
            _buildTemplateOption(
              'Acknowledgment',
              'Thank you for reaching out...',
            ),
            _buildTemplateOption(
              'Investigation',
              'We are currently investigating...',
            ),
            _buildTemplateOption(
              'Resolution',
              'We have resolved your issue...',
            ),
            _buildTemplateOption('Apology', 'We sincerely apologize for...'),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption(String title, String preview) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Color(0xFF1E293B),
        ),
      ),
      subtitle: Text(preview),
      onTap: () {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title template applied'),
            backgroundColor: const Color(0xFF781C2E),
          ),
        );
      },
    );
  }

  void _updateComplaintStatus(Map<String, dynamic> complaint) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint status updated'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _escalateComplaint(Map<String, dynamic> complaint) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint escalated to senior management'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _reopenComplaint(Map<String, dynamic> complaint) {
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Complaint reopened'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  List<Map<String, dynamic>> _generateDummyComplaints() {
    return [
      {
        'id': '#CMP-2024-001',
        'title': 'Item delivered damaged',
        'description':
            'The camera I rented arrived with a cracked lens. This has affected my photography session and caused significant inconvenience.',
        'customerName': 'John Doe',
        'customerEmail': 'john.doe@email.com',
        'customerPhone': '+1234567890',
        'type': 'Product Quality',
        'status': 'Open',
        'priority': 'High',
        'timeAgo': '2 hours ago',
        'orderReference': '#ORD-2024-001',
      },
      {
        'id': '#CMP-2024-002',
        'title': 'Late delivery',
        'description':
            'My rental items were delivered 3 hours later than the scheduled time, causing delays in my event setup.',
        'customerName': 'Sarah Smith',
        'customerEmail': 'sarah.smith@email.com',
        'customerPhone': '+1234567891',
        'type': 'Delivery Issue',
        'status': 'In Progress',
        'priority': 'Medium',
        'timeAgo': '1 day ago',
        'orderReference': '#ORD-2024-002',
      },
      {
        'id': '#CMP-2024-003',
        'title': 'Overcharged on return',
        'description':
            'I was charged extra fees that were not mentioned in the original rental agreement. Please review my billing.',
        'customerName': 'Mike Johnson',
        'customerEmail': 'mike.johnson@email.com',
        'customerPhone': '+1234567892',
        'type': 'Billing Issue',
        'status': 'Resolved',
        'priority': 'High',
        'timeAgo': '2 days ago',
        'orderReference': '#ORD-2024-003',
      },
      {
        'id': '#CMP-2024-004',
        'title': 'Poor customer service',
        'description':
            'The support team was unhelpful when I called about setup instructions for the equipment.',
        'customerName': 'Emily Davis',
        'customerEmail': 'emily.davis@email.com',
        'customerPhone': '+1234567893',
        'type': 'Service Quality',
        'status': 'Open',
        'priority': 'Low',
        'timeAgo': '3 days ago',
        'orderReference': null,
      },
      {
        'id': '#CMP-2024-005',
        'title': 'Missing accessories',
        'description':
            'The power tools rental was missing essential accessories that were listed in the package description.',
        'customerName': 'Alex Wilson',
        'customerEmail': 'alex.wilson@email.com',
        'customerPhone': '+1234567894',
        'type': 'Missing Items',
        'status': 'In Progress',
        'priority': 'Medium',
        'timeAgo': '4 days ago',
        'orderReference': '#ORD-2024-004',
      },
      {
        'id': '#CMP-2024-006',
        'title': 'Difficulty with pickup',
        'description':
            'The pickup location was different from what was communicated, causing confusion and delays.',
        'customerName': 'Lisa Brown',
        'customerEmail': 'lisa.brown@email.com',
        'customerPhone': '+1234567895',
        'type': 'Logistics Issue',
        'status': 'Resolved',
        'priority': 'Low',
        'timeAgo': '5 days ago',
        'orderReference': '#ORD-2024-005',
      },
    ];
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return const Color(0xFF781C2E);
      case 'in progress':
        return const Color(0xFF8B2635);
      case 'resolved':
        return const Color(0xFF9E2F3C);
      default:
        return const Color(0xFF781C2E);
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFF781C2E);
      case 'medium':
        return const Color(0xFF8B2635);
      case 'low':
        return const Color(0xFF9E2F3C);
      default:
        return const Color(0xFFB13843);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Icons.error_outline_rounded;
      case 'in progress':
        return Icons.sync_rounded;
      case 'resolved':
        return Icons.check_circle_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  IconData _getComplaintIcon(String type) {
    switch (type.toLowerCase()) {
      case 'product quality':
        return Icons.inventory_2_rounded;
      case 'delivery issue':
        return Icons.local_shipping_rounded;
      case 'billing issue':
        return Icons.receipt_rounded;
      case 'service quality':
        return Icons.support_agent_rounded;
      case 'missing items':
        return Icons.search_off_rounded;
      case 'logistics issue':
        return Icons.route_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }
}
