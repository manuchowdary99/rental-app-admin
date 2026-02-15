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

  final _usersRef = FirebaseFirestore.instance.collection('users');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              scheme.surface,
              scheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(context)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _StickySearchBarDelegate(
                  minExtent: 92,
                  maxExtent: 108,
                  child: _buildPinnedSearchBar(context),
                ),
              ),
              SliverToBoxAdapter(
                child: _buildFilterSection(context),
              ),
              _buildUsersSliver(context),
              const SliverPadding(
                padding: EdgeInsets.only(bottom: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================
  // USERS LIST
  // ==========================
  Widget _buildUsersSliver(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _usersRef.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'Something went wrong',
                subtitle: 'Unable to load users',
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: LoadingState(message: 'Loading users...'),
          );
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                icon: Icons.people_outline_rounded,
                title: 'No users found',
                subtitle: 'Users will appear here once they register',
              ),
            ),
          );
        }

        final filteredDocs = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final name = (data['displayName'] ?? '').toString().toLowerCase();
          final email = (data['email'] ?? '').toString().toLowerCase();

          final role = (data['role'] ?? 'normal').toString();
          final status = (data['status'] ?? 'active').toString();
          final kycStatus = (data['kycStatus'] ?? 'not_submitted').toString();

          if (_searchQuery.isNotEmpty &&
              !name.contains(_searchQuery.toLowerCase()) &&
              !email.contains(_searchQuery.toLowerCase())) {
            return false;
          }

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
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No users match filters',
                subtitle: 'Try adjusting your search or filters',
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final doc = filteredDocs[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildUserCard(context, doc, data);
              },
              childCount: filteredDocs.length,
            ),
          ),
        );
      },
    );
  }

  // ==========================
  // USER CARD
  // ==========================
  Widget _buildUserCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final displayName = data['displayName'] ?? 'No Name';
    final email = data['email'] ?? 'No Email';

    final role = (data['role'] ?? 'normal').toString();
    final status = (data['status'] ?? 'active').toString();
    final kycStatus = (data['kycStatus'] ?? 'not_submitted').toString();

    final isBlocked = status == 'blocked';
    final photoUrl = data['photoURL'] as String?;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AdminCard(
      color: scheme.surfaceContainerHighest,
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
                  _getRoleColor(role).withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _getRoleColor(role).withValues(alpha: 0.3),
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
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.onSurface,
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    StatusChip(
                      text: isBlocked ? 'BLOCKED' : 'ACTIVE',
                      color: isBlocked ? scheme.error : Colors.green,
                      icon: isBlocked
                          ? Icons.block_rounded
                          : Icons.check_circle_rounded,
                      isSmall: true,
                    ),
                    const SizedBox(width: 8),
                    StatusChip(
                      text: 'KYC: ${kycStatus.toUpperCase()}',
                      color: _getKycColor(kycStatus, scheme),
                      icon: Icons.badge_rounded,
                      isSmall: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: scheme.primary,
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
    final scheme = Theme.of(context).colorScheme;

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
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: scheme.outline.withValues(alpha: 0.2),
              ),
              boxShadow: [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: _buildUserDetailsContent(context, doc, data),
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
    BuildContext context,
    QueryDocumentSnapshot doc,
    Map<String, dynamic> data,
  ) {
    final role = (data['role'] ?? 'normal').toString();
    final status = (data['status'] ?? 'active').toString();
    final kycStatus = (data['kycStatus'] ?? 'not_submitted').toString();

    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
    final lastLogin = (data['lastLoginAt'] as Timestamp?)?.toDate();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Details',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 20),
        _buildDetailRow(context, 'User ID', doc.id),
        _buildDetailRow(context, 'Role', role.toUpperCase()),
        _buildDetailRow(context, 'Status', status.toUpperCase()),
        _buildDetailRow(context, 'KYC', kycStatus.toUpperCase()),
        if (createdAt != null)
          _buildDetailRow(context, 'Joined', _formatDate(createdAt)),
        if (lastLogin != null)
          _buildDetailRow(context, 'Last Login', _formatDate(lastLogin)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: AdminButton(
                text: status == 'blocked' ? 'Unblock User' : 'Block User',
                color: status == 'blocked' ? scheme.primary : scheme.error,
                icon: status == 'blocked'
                    ? Icons.lock_open_rounded
                    : Icons.block_rounded,
                onPressed: () => _updateUser(doc.id, {
                  'status': status == 'blocked' ? 'active' : 'blocked',
                }),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AdminButton(
                text: role == 'premium' ? 'Remove Premium' : 'Make Premium',
                color: scheme.tertiary,
                icon: Icons.star_rounded,
                isOutlined: true,
                onPressed: () => _updateUser(doc.id, {
                  'role': role == 'premium' ? 'normal' : 'premium',
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        AdminButton(
          text: role == 'trusted' ? 'Remove Trusted' : 'Mark Trusted',
          color: scheme.secondary,
          icon: Icons.verified_user_rounded,
          isOutlined: true,
          onPressed: () => _updateUser(doc.id, {
            'role': role == 'trusted' ? 'normal' : 'trusted',
            'kycStatus': role == 'trusted' ? 'not_submitted' : 'approved',
          }),
        ),
      ],
    );
  }

  // ==========================
  // HELPERS
  // ==========================
  Future<void> _updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _usersRef.doc(uid).update(data);

      if (mounted) {
        Navigator.pop(context);
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('User updated successfully'),
            backgroundColor: scheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final scheme = Theme.of(context).colorScheme;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: scheme.error,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface,
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

  Color _getKycColor(String status, ColorScheme scheme) {
    switch (status) {
      case 'approved':
      case 'submitted':
        return Colors.green;
      case 'pending':
        return Colors.amber;
      case 'rejected':
        return Colors.red;
      case 'not_submitted':
        return Colors.red;
      default:
        return scheme.outlineVariant;
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
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary,
                  scheme.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.people_rounded, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Users Management',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage platform users',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedSearchBar(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: scheme.surfaceContainerHigh,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.outlineVariant,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.outlineVariant,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: scheme.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildFilterChip(context, 'All'),
          _buildFilterChip(context, 'Active'),
          _buildFilterChip(context, 'Blocked'),
          _buildFilterChip(context, 'Trusted'),
          _buildFilterChip(context, 'Premium'),
          _buildFilterChip(context, 'KYC Pending'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String filter) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = _filterStatus == filter;

    return ChoiceChip(
      label: Text(filter),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterStatus = filter;
        });
      },
      selectedColor: scheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : scheme.onSurface,
      ),
    );
  }
}

class _StickySearchBarDelegate extends SliverPersistentHeaderDelegate {
  _StickySearchBarDelegate({
    required this.child,
    required this.minExtent,
    required this.maxExtent,
  });

  final Widget child;

  @override
  final double minExtent;

  @override
  final double maxExtent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            scheme.surface,
            scheme.surfaceContainerHighest,
          ],
        ),
        boxShadow: [
          if (shrinkOffset > 0 || overlapsContent)
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: SizedBox.expand(child: child),
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBarDelegate oldDelegate) {
    return minExtent != oldDelegate.minExtent ||
        maxExtent != oldDelegate.maxExtent ||
        child != oldDelegate.child;
  }
}
