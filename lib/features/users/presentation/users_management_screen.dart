import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/widgets/admin_widgets.dart';

class UsersManagementScreen extends StatefulWidget {
  const UsersManagementScreen({super.key});

  @override
  State<UsersManagementScreen> createState() => _UsersManagementScreenState();
}

class _UsersManagementScreenState extends State<UsersManagementScreen> {
  String _searchQuery = '';
  String _filterStatus = 'All';

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
              Icons.people_rounded,
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
                  'Users Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  'Manage platform users',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
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
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.grey,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Active'),
                const SizedBox(width: 8),
                _buildFilterChip('Blocked'),
                const SizedBox(width: 8),
                _buildFilterChip('Trusted'),
                const SizedBox(width: 8),
                _buildFilterChip('Premium'),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _filterStatus == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filterStatus = filter;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Something went wrong',
              subtitle: 'Unable to load users at this time',
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

        // Apply filters
        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['displayName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();

          // Search filter
          if (_searchQuery.isNotEmpty &&
              !name.contains(_searchQuery.toLowerCase()) &&
              !email.contains(_searchQuery.toLowerCase())) {
            return false;
          }

          // Status filter
          if (_filterStatus != 'All') {
            switch (_filterStatus) {
              case 'Active':
                return !(data['isBlocked'] ?? false);
              case 'Blocked':
                return data['isBlocked'] ?? false;
              case 'Trusted':
                return data['isTrusted'] ?? false;
              case 'Premium':
                return (data['role'] ?? 'user') == 'premium';
            }
          }

          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return const Center(
            child: EmptyState(
              icon: Icons.search_off_rounded,
              title: 'No users match filters',
              subtitle: 'Try adjusting your search or filter criteria',
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

  Widget _buildUserCard(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    final displayName = data['displayName'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final role = data['role'] ?? 'user';
    final isBlocked = data['isBlocked'] ?? false;
    final isTrusted = data['isTrusted'] ?? false;
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
                  color: _getRoleColor(role).withOpacity(0.3),
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
                : Icon(_getRoleIcon(role), color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // User Info
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
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    StatusChip(
                      text: isBlocked ? 'Blocked' : 'Active',
                      color: isBlocked ? Colors.red : Colors.green,
                      icon: isBlocked
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      isSmall: true,
                    ),
                    const SizedBox(width: 8),
                    if (isTrusted)
                      const StatusChip(
                        text: 'Trusted',
                        color: Colors.blue,
                        icon: Icons.verified_user_rounded,
                        isSmall: true,
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F6EE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF781C2E),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserDetails(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
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
                    child: _buildUserDetailsContent(doc, data),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserDetailsContent(
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final displayName = data['displayName'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';
    final role = data['role'] ?? 'user';
    final isBlocked = data['isBlocked'] ?? false;
    final isTrusted = data['isTrusted'] ?? false;
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final lastLogin = (data['lastLogin'] as Timestamp?)?.toDate();

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
        // User Info Card
        AdminCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getRoleColor(role),
                          _getRoleColor(role).withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      _getRoleIcon(role),
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          email,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildDetailRow('User ID', doc.id),
              const SizedBox(height: 12),
              _buildDetailRow('Role', role.toUpperCase()),
              const SizedBox(height: 12),
              if (createdAt != null)
                _buildDetailRow('Joined', _formatDate(createdAt)),
              const SizedBox(height: 12),
              if (lastLogin != null)
                _buildDetailRow('Last Login', _formatDate(lastLogin)),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Actions
        Row(
          children: [
            Expanded(
              child: AdminButton(
                text: isBlocked ? 'Unblock User' : 'Block User',
                color: isBlocked ? Colors.green : Colors.red,
                icon: isBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                onPressed: () =>
                    _toggleUserStatus(doc, 'isBlocked', !isBlocked),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AdminButton(
                text: isTrusted ? 'Remove Trust' : 'Mark Trusted',
                color: isTrusted ? Colors.orange : Colors.blue,
                icon: isTrusted
                    ? Icons.verified_user_outlined
                    : Icons.verified_user_rounded,
                isOutlined: true,
                onPressed: () =>
                    _toggleUserStatus(doc, 'isTrusted', !isTrusted),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _toggleUserStatus(
    QueryDocumentSnapshot doc,
    String field,
    bool value,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
        field: value,
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User ${field.replaceAll('is', '').toLowerCase()} updated',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFF781C2E);
      case 'moderator':
        return const Color(0xFF8B2635);
      case 'premium':
        return const Color(0xFF9E2F3C);
      default:
        return const Color(0xFFB13843);
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      case 'moderator':
        return Icons.verified_user_rounded;
      case 'premium':
        return Icons.star_rounded;
      default:
        return Icons.person_rounded;
    }
  }
}
