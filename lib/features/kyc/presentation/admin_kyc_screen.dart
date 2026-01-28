import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/kyc_request.dart';
import '../services/kyc_service.dart';

class AdminKycScreen extends StatefulWidget {
  const AdminKycScreen({super.key});

  @override
  State<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends State<AdminKycScreen> {
  final KycService _kycService = KycService();
  final TextEditingController _searchController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy • hh:mm a');

  KycStatusFilter _filter = KycStatusFilter.pending;
  String _searchTerm = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Management'),
      ),
      body: StreamBuilder<List<KycRequest>>(
        stream: _kycService.watchAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _CenterMessage(
              icon: Icons.error_outline,
              message: 'Failed to load KYC submissions',
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allRequests = snapshot.data ?? [];
          final visibleRequests = _applyFilters(allRequests);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _buildStatsRow(allRequests),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchHeaderDelegate(
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  child: _buildSearchField(),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildFilterChips(),
              ),
              if (visibleRequests.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _CenterMessage(
                    icon: Icons.verified_user_outlined,
                    message: _filter == KycStatusFilter.pending
                        ? 'No pending KYC submissions'
                        : 'No requests match the selected filters',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final request = visibleRequests[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index == visibleRequests.length - 1 ? 0 : 16,
                          ),
                          child: _KycRequestCard(
                            request: request,
                            dateFormat: _dateFormat,
                            onApprove: request.isApproved
                                ? null
                                : () => _handleApprove(request),
                            onReject: request.isRejected
                                ? null
                                : () => _handleReject(request),
                            onPreview: (url, title) =>
                                _showAttachmentPreview(url, title),
                          ),
                        );
                      },
                      childCount: visibleRequests.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsRow(List<KycRequest> requests) {
    final pending = requests.where((request) => request.isPending).length;
    final approved = requests.where((request) => request.isApproved).length;
    final rejected = requests.where((request) => request.isRejected).length;

    final cards = [
      _StatCard(label: 'Pending', value: pending, color: Colors.orange),
      const SizedBox(width: 12),
      _StatCard(label: 'Approved', value: approved, color: Colors.green),
      const SizedBox(width: 12),
      _StatCard(label: 'Rejected', value: rejected, color: Colors.red),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: cards,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchTerm = value.trim().toLowerCase());
        },
        decoration: InputDecoration(
          filled: true,
          fillColor: theme.cardColor,
          prefixIcon: const Icon(Icons.search),
          hintText: 'Search name, email, phone or document number',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: KycStatusFilter.values
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(_labelFor(filter)),
                  selected: _filter == filter,
                  onSelected: (_) => setState(() => _filter = filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  List<KycRequest> _applyFilters(List<KycRequest> requests) {
    return requests.where((request) {
      final matchesStatus = _filter == KycStatusFilter.all
          ? true
          : request.status == _filter.name;
      final matchesSearch = _searchTerm.isEmpty
          ? true
          : [
              request.fullName,
              request.email,
              request.phone,
              request.documentNumber,
            ]
              .whereType<String>()
              .map((value) => value.toLowerCase())
              .any((value) => value.contains(_searchTerm));
      return matchesStatus && matchesSearch;
    }).toList();
  }

  Future<void> _handleApprove(KycRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve KYC'),
        content: Text(
          'Approve KYC for ${request.fullName ?? request.email ?? request.userId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _kycService.approve(request);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KYC approved successfully')),
    );
  }

  Future<void> _handleReject(KycRequest request) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject KYC'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              Navigator.pop(context, text);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (reason == null) return;

    await _kycService.reject(request, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('KYC rejected')),
    );
  }

  Future<void> _showAttachmentPreview(String url, String title) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4,
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('Unable to load image'),
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _labelFor(KycStatusFilter filter) {
    switch (filter) {
      case KycStatusFilter.pending:
        return 'Pending';
      case KycStatusFilter.approved:
        return 'Approved';
      case KycStatusFilter.rejected:
        return 'Rejected';
      case KycStatusFilter.all:
        return 'All';
    }
  }
}

class _SearchHeaderDelegate extends SliverPersistentHeaderDelegate {
  _SearchHeaderDelegate({
    required this.child,
    required this.backgroundColor,
    this.height = 96,
  });

  final Widget child;
  final Color backgroundColor;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final shadow = overlapsContent
        ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ]
        : const <BoxShadow>[];

    return Container(
      color: backgroundColor,
      child: DecoratedBox(
        decoration: BoxDecoration(boxShadow: shadow),
        child: SizedBox(
          height: height,
          child: child,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchHeaderDelegate oldDelegate) {
    return oldDelegate.child != child ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.height != height;
  }
}

class _KycRequestCard extends StatelessWidget {
  const _KycRequestCard({
    required this.request,
    required this.dateFormat,
    required this.onApprove,
    required this.onReject,
    required this.onPreview,
  });

  final KycRequest request;
  final DateFormat dateFormat;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final void Function(String url, String title) onPreview;

  @override
  Widget build(BuildContext context) {
    final submitted = request.submittedAt != null
        ? dateFormat.format(request.submittedAt!.toDate())
        : 'Unknown';
    final statusColor = _statusColor(request.status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  foregroundColor: statusColor,
                  child: Text(request.initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.fullName ?? 'Name unavailable',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        request.email ?? 'Email not provided',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: statusColor.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: statusColor),
                  label: Text(request.status.toUpperCase()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.badge_outlined,
              label: 'Document',
              value:
                  '${request.documentType?.replaceAll('_', ' ').toUpperCase() ?? 'Not provided'} • ${request.documentNumber ?? '---'}',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.phone_android,
              label: 'Phone',
              value: request.phone ?? 'Not provided',
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: request.locationLabel,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.schedule_outlined,
              label: 'Submitted',
              value: submitted,
            ),
            if (request.rejectionReason != null &&
                request.rejectionReason!.isNotEmpty) ...[
              const SizedBox(height: 8),
              _InfoRow(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Last reason',
                value: request.rejectionReason!,
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (request.documentUrl != null &&
                    request.documentUrl!.isNotEmpty)
                  _AttachmentButton(
                    label: 'Aadhaar Photo',
                    icon: Icons.credit_card,
                    onTap: () => onPreview(
                      request.documentUrl!,
                      'Document Proof',
                    ),
                  ),
                if (request.selfieUrl != null && request.selfieUrl!.isNotEmpty)
                  _AttachmentButton(
                    label: 'Selfie',
                    icon: Icons.person,
                    onTap: () => onPreview(
                      request.selfieUrl!,
                      'Selfie Verification',
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F9D58),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB00020),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return const Color(0xFF0F9D58);
      case 'rejected':
        return const Color(0xFFB00020);
      default:
        return const Color(0xFFFFA000);
    }
  }
}

class _AttachmentButton extends StatelessWidget {
  const _AttachmentButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[700], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterMessage extends StatelessWidget {
  const _CenterMessage({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Colors.grey[500]),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
