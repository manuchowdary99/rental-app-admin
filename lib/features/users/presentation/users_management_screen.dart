import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() =>
      _UsersManagementScreenState();
}

class _UsersManagementScreenState
    extends State<UsersManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';

  final _usersRef =
      FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F6EE),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchAndFilter(),
            Expanded(child: _buildUsersList()),
          ],
        ),
      ),
    );
  }

  // ==========================
  // USERS LIST
  // ==========================
  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              subtitle: 'Unable to load users',
            ),
          );
        }

        if (!snapshot.hasData) {
          return const LoadingState(message: 'Loading users...');
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.people_outline_rounded,
              title: 'No users found',
              subtitle: 'Users will appear here once they register',
            ),
          );
        }

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name =
              (data['displayName'] ?? '').toString().toLowerCase();
          final email =
              (data['email'] ?? '').toString().toLowerCase();

          final role = (data['role'] ?? 'normal').toString();
          final status =
              (data['status'] ?? 'active').toString();
          final kycStatus =
              (data['kycStatus'] ?? 'not_submitted').toString();

          // Search
          if (_searchQuery.isNotEmpty &&
              !name.contains(_searchQuery.toLowerCase()) &&
              !email.contains(_searchQuery.toLowerCase())) {
            return false;
          }

          // Filters
          if (_filterStatus != 'All') {
            switch (_filterStatus) {
              case 'Active':
                return status == 'active';
              case 'Blocked':
                return status == 'blocked';
              case 'Trusted':
                return role == 'trusted';
              case 'Premium':
                return role == 'premium';
              case 'KYC Pending':
                return kycStatus == 'pending';
            }
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No users match filters',
              subtitle: 'Try adjusting your search or filters',
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: filteredDocs.length,
          itemBuilder: (context, index) {
            final doc = filteredDocs[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildUserCard(doc, data);
          },
        );
      },
    );
  }

  // ==========================
  // USER CARD
  // ==========================
  Widget _buildUserCard(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final displayName = data['displayName'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';

    final role = (data['role'] ?? 'normal').toString();
    final status = (data['status'] ?? 'active').toString();
    final kycStatus =
        (data['kycStatus'] ?? 'not_submitted').toString();

    final isBlocked = status == 'blocked';
    final photoUrl = data['photoURL'] as String?;

    return AdminCard(
      onTap: () {
        _showUserDetails(doc, data);
      },
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getRoleColor(role),
                  _getRoleColor(role).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color:
                      _getRoleColor(role).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(
                        _getRoleIcon(role),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  )
                : Icon(
                    _getRoleIcon(role),
                    color: Colors.white,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusChip(
                      text: role.toUpperCase(),
                      color: _getRoleColor(role),
                      isSmall: true,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusChip(
                      text: isBlocked ? 'BLOCKED' : 'ACTIVE',
                      color: isBlocked
                          ? Colors.red
                          : Colors.green,
                      icon: isBlocked
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      isSmall: true,
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      text: 'KYC: ${kycStatus.toUpperCase()}',
                      color: _getKycColor(kycStatus),
                      icon: Icons.badge_rounded,
                      isSmall: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Color(0xFF781C2E),
          ),
        ],
      ),
    );
  }

  // ==========================
  // USER DETAILS MODAL
  // ==========================
  void _showUserDetails(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: _buildUserDetailsContent(doc, data),
            ),
          );
        },
      ),
    );
  }

  // ==========================
  // DETAILS CONTENT
  // ==========================
  Widget _buildUserDetailsContent(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final role = (data['role'] ?? 'normal').toString();
    final status = (data['status'] ?? 'active').toString();
    final kycStatus =
        (data['kycStatus'] ?? 'not_submitted').toString();

    final createdAt =
        (data['createdAt'] as Timestamp?)?.toDate();
    final lastLogin =
        (data['lastLoginAt'] as Timestamp?)?.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'User Details',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),

        _buildDetailRow('User ID', doc.id),
        _buildDetailRow('Role', role.toUpperCase()),
        _buildDetailRow('Status', status.toUpperCase()),
        _buildDetailRow('KYC', kycStatus.toUpperCase()),

        if (createdAt != null)
          _buildDetailRow(
              'Joined', _formatDate(createdAt)),
        if (lastLogin != null)
          _buildDetailRow(
              'Last Login', _formatDate(lastLogin)),

        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: AdminButton(
                text: status == 'blocked'
                    ? 'Unblock User'
                    : 'Block User',
                color: status == 'blocked'
                    ? Colors.green
                    : Colors.red,
                icon: status == 'blocked'
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                onPressed: () => _updateUser(doc.id, {
                  'status': status == 'blocked'
                      ? 'active'
                      : 'blocked',
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminButton(
                text: role == 'premium'
                    ? 'Remove Premium'
                    : 'Make Premium',
                color: Colors.amber,
                icon: Icons.star_rounded,
                isOutlined: true,
                onPressed: () => _updateUser(doc.id, {
                  'role': role == 'premium'
                      ? 'normal'
                      : 'premium',
                }),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        AdminButton(
          text: role == 'trusted'
              ? 'Remove Trusted'
              : 'Mark Trusted',
          color: Colors.blue,
          icon: Icons.verified_user_rounded,
          isOutlined: true,
          onPressed: () => _updateUser(doc.id, {
            'role': role == 'trusted'
                ? 'normal'
                : 'trusted',
            'kycStatus': role == 'trusted'
                ? 'not_submitted'
                : 'approved',
          }),
        ),
      ],
    );
  }

  // ==========================
  // HELPERS
  // ==========================
  Future<void> _updateUser(
      String uid, Map<String, dynamic> data) async {
    try {
      await _usersRef.doc(uid).update(data);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
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
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF781C2E);
      case 'trusted':
        return Colors.blue;
      case 'premium':
        return Colors.amber;
      default:
        return const Color(0xFFB13843);
    }
  }

  Color _getKycColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'trusted':
        return Icons.verified_user_rounded;
      case 'premium':
        return Icons.star_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  // ==========================
  // HEADER + FILTER UI
  // ==========================
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
                colors: [
                  Color(0xFF781C2E),
                  Color(0xFF5A1521)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.people_rounded,
                color: Colors.white),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Users Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Manage platform users',
                  style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Search users...',
              prefixIcon: Icon(Icons.search_rounded),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('All'),
              _buildFilterChip('Active'),
              _buildFilterChip('Blocked'),
              _buildFilterChip('Trusted'),
              _buildFilterChip('Premium'),
              _buildFilterChip('KYC Pending'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _filterStatus == filter;

    return ChoiceChip(
      label: Text(filter),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterStatus = filter;
        });
      },
      selectedColor: const Color(0xFF781C2E),
      labelStyle: TextStyle(
        color: isSelected
            ? Colors.white
            : Colors.black,
      ),
    );
  }
}
