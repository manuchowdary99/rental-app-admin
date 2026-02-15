import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/admin_profile.dart';
import '../../../core/widgets/admin_widgets.dart';
import '../providers/admin_profile_providers.dart';
import 'admin_profile_edit_screen.dart';
import 'admin_change_password_screen.dart';
import '../../navigation/widgets/admin_app_drawer.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(adminProfileProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Admin Profile'),
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
      ),
      drawer: const AdminAppDrawer(),
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
          top: false,
          child: profileAsync.when(
            data: (profile) => RefreshIndicator(
              onRefresh: () => ref.refresh(adminProfileProvider.future),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  _ProfileHeader(profile: profile),
                  const SizedBox(height: 18),
                  _QuickMeta(profile: profile),
                  const SizedBox(height: 18),
                  _ContactCard(profile: profile),
                  const SizedBox(height: 18),
                  _ActivityCard(profile: profile),
                  const SizedBox(height: 18),
                  AdminButton(
                    text: 'Edit Profile',
                    icon: Icons.edit,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminProfileEditScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  AdminButton(
                    text: 'Change Password',
                    icon: Icons.lock_reset_rounded,
                    isOutlined: true,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const AdminChangePasswordScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            loading: () => const LoadingState(message: 'Loading profile...'),
            error: (error, _) => Center(
              child: EmptyState(
                icon: Icons.person_off_rounded,
                title: 'Unable to load profile',
                subtitle: error.toString(),
                action: AdminButton(
                  text: 'Retry',
                  onPressed: () => ref.invalidate(adminProfileProvider),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final AdminProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            scheme.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.onPrimary.withValues(alpha: 0.15),
            backgroundImage: profile.photoUrl != null
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null
                ? Text(
                    _initial(profile),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.displayName,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profile.title ?? 'Administrator',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimary.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (_) {
                    final bool isSuspended = profile.isSuspended;
                    final Color roleTextColor = scheme.onPrimary;
                    final Color roleBackground =
                        Colors.white.withValues(alpha: 0.18);
                    final Color roleBorder =
                        Colors.white.withValues(alpha: 0.35);

                    final Color statusTextColor = isSuspended
                        ? scheme.error
                        : Colors.greenAccent.shade400;
                    final Color statusBackground = isSuspended
                        ? scheme.error.withValues(alpha: 0.18)
                        : Colors.greenAccent.withValues(alpha: 0.2);
                    final Color statusBorder = isSuspended
                        ? scheme.error.withValues(alpha: 0.35)
                        : Colors.greenAccent.shade400.withValues(alpha: 0.35);

                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusChip(
                          text: profile.role.toUpperCase(),
                          color: roleTextColor,
                          textColor: roleTextColor,
                          backgroundColor: roleBackground,
                          borderColor: roleBorder,
                          icon: Icons.verified_user_rounded,
                        ),
                        StatusChip(
                          text: profile.status.toUpperCase(),
                          color: statusTextColor,
                          textColor: statusTextColor,
                          backgroundColor: statusBackground,
                          borderColor: statusBorder,
                          icon: isSuspended
                              ? Icons.block_rounded
                              : Icons.check_circle_rounded,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickMeta extends StatelessWidget {
  const _QuickMeta({required this.profile});

  final AdminProfile profile;

  @override
  Widget build(BuildContext context) {
    final cards = [
      _MetaTile(
        icon: Icons.phone_rounded,
        label: 'Phone',
        value: profile.phoneNumber ?? 'Add phone',
      ),
      _MetaTile(
        icon: Icons.alternate_email_rounded,
        label: 'Email',
        value: profile.email,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoColumns = constraints.maxWidth > 680;
        if (isTwoColumns) {
          return Row(
            children: cards
                .map(
                  (card) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: card,
                    ),
                  ),
                )
                .toList(),
          );
        }
        return Column(
          children: cards
              .map(
                (card) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: card,
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.profile});

  final AdminProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            profile.bio?.isNotEmpty == true
                ? profile.bio!
                : 'Add a short bio to help other admins understand your focus areas.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.profile});

  final AdminProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AdminCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Activity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          _ActivityRow(
            label: 'Created',
            value: _formatDate(profile.createdAt),
            icon: Icons.event_available_rounded,
          ),
          const SizedBox(height: 12),
          _ActivityRow(
            label: 'Last Login',
            value: _formatDate(profile.lastLoginAt),
            icon: Icons.refresh_rounded,
          ),
        ],
      ),
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AdminCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

String _initial(AdminProfile profile) {
  final text = profile.displayName.trim();
  if (text.isEmpty) {
    return 'A';
  }
  return text.substring(0, 1).toUpperCase();
}

String _formatDate(DateTime? date) {
  if (date == null) {
    return 'Not available';
  }
  return '${date.day.toString().padLeft(2, '0')} '
      '${_monthLabel(date.month)} '
      '${date.year}';
}

String _monthLabel(int month) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return months[(month - 1).clamp(0, months.length - 1)];
}
