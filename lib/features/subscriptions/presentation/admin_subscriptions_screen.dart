import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../users/presentation/users_detail_screen.dart';
import '../models/subscription_plan.dart';
import '../models/user_subscription.dart';
import '../services/subscription_service.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  State<AdminSubscriptionsScreen> createState() =>
      _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends State<AdminSubscriptionsScreen> {
  final SubscriptionService _service = SubscriptionService();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _priceFormat =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  String _statusFilter = 'active';
  String _planFilter = 'all';
  bool _showOnlyActivePlans = true;
  bool _autoExpireInProgress = false;

  @override
  void initState() {
    super.initState();
    _service.ensureDefaultPlans();
    _runAutoExpire();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F4EC),
      child: StreamBuilder<List<SubscriptionPlan>>(
        stream: _service.watchPlans(),
        builder: (context, planSnapshot) {
          if (planSnapshot.hasError) {
            return _buildError('Unable to load plans');
          }

          final plans = planSnapshot.data ?? [];

          return StreamBuilder<List<UserSubscription>>(
            stream: _service.watchSubscriptions(),
            builder: (context, subsSnapshot) {
              if (subsSnapshot.hasError) {
                return _buildError('Unable to load subscriptions');
              }

              if (!planSnapshot.hasData || !subsSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final subscriptions = subsSnapshot.data ?? [];

              return SafeArea(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(plans, subscriptions),
                      const SizedBox(height: 20),
                      _buildPlanSection(plans),
                      const SizedBox(height: 24),
                      _buildSubscriberSection(plans, subscriptions),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 32, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _service.ensureDefaultPlans,
            child: const Text('Retry'),
          )
        ],
      ),
    );
  }

  Widget _buildHeader(
    List<SubscriptionPlan> plans,
    List<UserSubscription> subscriptions,
  ) {
    final activePlans = plans.where((plan) => plan.active).length;
    final activeSubs =
        subscriptions.where((sub) => sub.status == 'active').length;
    final canceledSubs =
        subscriptions.where((sub) => sub.status == 'canceled').length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Subscription Management',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F1F1F),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Create plans, manage pricing, and control active subscribers.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Active Plans',
                value: activePlans.toString(),
                icon: Icons.view_week_rounded,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Active Subscribers',
                value: activeSubs.toString(),
                icon: Icons.verified_user_rounded,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Canceled',
                value: canceledSubs.toString(),
                icon: Icons.cancel_schedule_send_rounded,
                color: Colors.redAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _autoExpireInProgress
                ? null
                : () => _runAutoExpire(showStatus: true),
            icon: _autoExpireInProgress
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.timer_off_rounded),
            label: const Text('Run auto-expire scan'),
          ),
        ),
        const SizedBox(height: 8),
        _buildRevenueBar(plans, subscriptions),
        const SizedBox(height: 12),
        _buildExpiringAlert(plans, subscriptions),
      ],
    );
  }

  Widget _buildPlanSection(List<SubscriptionPlan> plans) {
    final visiblePlans = _showOnlyActivePlans
        ? plans.where((plan) => plan.active).toList()
        : plans;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Plans',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _openPlanEditor(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New plan'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Only active'),
                  selected: _showOnlyActivePlans,
                  onSelected: (value) {
                    setState(() => _showOnlyActivePlans = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (visiblePlans.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No plans match this filter'),
              )
            else
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: visiblePlans
                    .map((plan) => _PlanCard(
                          plan: plan,
                          priceFormat: _priceFormat,
                          onEdit: () => _openPlanEditor(plan: plan),
                          onToggleActive: (value) =>
                              _service.setPlanActive(plan.id, value),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriberSection(
    List<SubscriptionPlan> plans,
    List<UserSubscription> subscriptions,
  ) {
    final planMap = {for (final plan in plans) plan.id: plan};
    final filtered = subscriptions.where((subscription) {
      final matchesStatus =
          _statusFilter == 'all' ? true : subscription.status == _statusFilter;
      final matchesPlan =
          _planFilter == 'all' ? true : subscription.planId == _planFilter;
      final search = _searchController.text.trim().toLowerCase();
      final linkedPlanName = planMap[subscription.planId]?.name;
      final matchesSearch = search.isEmpty
          ? true
          : [
              subscription.userName,
              subscription.userEmail,
              subscription.planName,
              linkedPlanName,
            ]
              .whereType<String>()
              .map((value) => value.toLowerCase())
              .any((value) => value.contains(search));
      return matchesStatus && matchesPlan && matchesSearch;
    }).toList();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Subscribers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Chip(
                  label: Text('${filtered.length} showing'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildSubscriberFilters(plans),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('No subscriptions match the current filters'),
                ),
              )
            else
              ListView.separated(
                itemCount: filtered.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final subscription = filtered[index];
                  final plan = planMap[subscription.planId];
                  final planDisplayName =
                      _effectivePlanName(subscription, plan);
                  final userLabel = _subscriberLabel(subscription);
                  final startDate = _dateFromTimestamp(subscription.startedAt);
                  final renewDate = _dateFromTimestamp(subscription.renewsAt);
                  final daysLeft = _daysUntil(renewDate);
                  final resolvedAmount =
                      _resolveSubscriptionAmount(subscription, plan);
                  final priceLabel = _formatPriceLabel(resolvedAmount);
                  final isPaidPlan = resolvedAmount > 0;
                  final isExpiringSoon = subscription.isActive &&
                      daysLeft != null &&
                      daysLeft >= 0 &&
                      daysLeft <= 5;
                  final canCancel = subscription.isActive;
                  final canExpire = subscription.isActive && isPaidPlan;

                  return _SubscriberCard(
                    subscription: subscription,
                    userLabel: userLabel,
                    planDisplayName: planDisplayName,
                    billingLabel: _resolveBillingLabel(subscription),
                    priceLabel: priceLabel,
                    startLabel: _formatDate(startDate),
                    renewLabel: renewDate != null
                        ? _formatDate(renewDate)
                        : 'No expiry',
                    isExpiringSoon: isExpiringSoon,
                    daysLeft: daysLeft,
                    showInvoiceButton: isPaidPlan,
                    onViewProfile: () => _viewProfile(subscription),
                    onInvoice: isPaidPlan
                        ? () => _generateInvoice(
                              subscription,
                              plan: plan,
                              priceLabel: priceLabel,
                            )
                        : null,
                    onNotify: isExpiringSoon && isPaidPlan
                        ? () => _handleNotify(subscription, daysLeft)
                        : null,
                    onCancel:
                        canCancel ? () => _handleCancel(subscription) : null,
                    onExpire:
                        canExpire ? () => _handleExpire(subscription) : null,
                    onUpgrade: () => _handleUpgrade(
                        subscription: subscription, plans: plans),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriberFilters(List<SubscriptionPlan> plans) {
    final searchField = Expanded(
      flex: 2,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search subscriber or plan',
          border: OutlineInputBorder(),
        ),
      ),
    );

    final planDropdown = Expanded(
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Plan',
          border: OutlineInputBorder(),
        ),
        initialValue: _planFilter,
        items: [
          const DropdownMenuItem<String>(
            value: 'all',
            child: Text('All plans'),
          ),
          ...plans.map(
            (plan) => DropdownMenuItem<String>(
              value: plan.id,
              child: Text(plan.name),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _planFilter = value ?? 'all'),
      ),
    );

    final statusDropdown = Expanded(
      child: DropdownButtonFormField<String>(
        decoration: const InputDecoration(
          labelText: 'Status',
          border: OutlineInputBorder(),
        ),
        initialValue: _statusFilter,
        items: const [
          DropdownMenuItem(value: 'active', child: Text('Active')),
          DropdownMenuItem(value: 'canceled', child: Text('Canceled')),
          DropdownMenuItem(value: 'expired', child: Text('Expired')),
          DropdownMenuItem(value: 'all', child: Text('All statuses')),
        ],
        onChanged: (value) => setState(() => _statusFilter = value ?? 'all'),
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        if (isNarrow) {
          return Column(
            children: [
              searchField,
              const SizedBox(height: 12),
              planDropdown,
              const SizedBox(height: 12),
              statusDropdown,
            ],
          );
        }

        return Row(
          children: [
            searchField,
            const SizedBox(width: 12),
            planDropdown,
            const SizedBox(width: 12),
            statusDropdown,
          ],
        );
      },
    );
  }

  Future<void> _openPlanEditor({SubscriptionPlan? plan}) async {
    final nameController = TextEditingController(text: plan?.name ?? '');
    final codeController = TextEditingController(text: plan?.code ?? '');
    final descriptionController =
        TextEditingController(text: plan?.description ?? '');
    final monthlyController = TextEditingController(
      text: plan != null ? plan.monthlyPrice.toString() : '0',
    );
    final yearlyController = TextEditingController(
      text: plan != null ? plan.yearlyPrice.toString() : '0',
    );
    final currencyController =
        TextEditingController(text: plan?.currency ?? 'INR');

    String audience = plan?.audience ?? 'all';
    bool isActive = plan?.active ?? true;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan == null ? 'Create Plan' : 'Edit Plan',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Plan name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: codeController,
                      decoration: const InputDecoration(
                        labelText: 'Code / identifier',
                        helperText: 'Used for integrations. Keep it unique.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Audience',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: audience,
                      items: const [
                        DropdownMenuItem(
                            value: 'all', child: Text('All users')),
                        DropdownMenuItem(
                            value: 'lender', child: Text('Lenders only')),
                        DropdownMenuItem(
                            value: 'renter', child: Text('Renters only')),
                      ],
                      onChanged: (value) =>
                          setModalState(() => audience = value ?? 'all'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: monthlyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Monthly price',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: yearlyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Yearly price',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: currencyController,
                      decoration: const InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: isActive,
                      title: const Text('Plan is active'),
                      onChanged: (value) =>
                          setModalState(() => isActive = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          final monthly =
                              int.tryParse(monthlyController.text.trim()) ?? 0;
                          final yearly =
                              int.tryParse(yearlyController.text.trim()) ?? 0;

                          final updatedPlan = SubscriptionPlan(
                            id: plan?.id ?? '',
                            name: nameController.text.trim(),
                            code: codeController.text.trim(),
                            audience: audience,
                            currency: currencyController.text.trim(),
                            monthlyPrice: monthly,
                            yearlyPrice: yearly,
                            description:
                                descriptionController.text.trim().isEmpty
                                    ? null
                                    : descriptionController.text.trim(),
                            active: isActive,
                            sortIndex: plan?.sortIndex ??
                                _deriveSortIndex(audience, plan?.sortIndex),
                            createdAt: plan?.createdAt,
                            updatedAt: plan?.updatedAt,
                          );

                          await _service.upsertPlan(updatedPlan);
                          if (mounted) Navigator.pop(context);
                        },
                        child:
                            Text(plan == null ? 'Create plan' : 'Save changes'),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  int _deriveSortIndex(String audience, int? previousIndex) {
    if (previousIndex != null) return previousIndex;
    switch (audience) {
      case 'lender':
        return 1;
      case 'renter':
        return 2;
      default:
        return 0;
    }
  }

  Future<void> _handleCancel(UserSubscription subscription) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel subscription'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason (optional)',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel subscription'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _service.cancelSubscription(
      subscription,
      reason: controller.text.trim().isEmpty ? null : controller.text.trim(),
    );
  }

  Future<void> _handleUpgrade({
    required UserSubscription subscription,
    required List<SubscriptionPlan> plans,
  }) async {
    if (plans.isEmpty) return;
    final activePlans = plans.where((plan) => plan.active).toList();
    SubscriptionPlan selectedPlan =
        activePlans.isNotEmpty ? activePlans.first : plans.first;
    String billingCycle = 'monthly';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'Move ${subscription.userName ?? subscription.userEmail ?? subscription.userId}'),
        content: StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<SubscriptionPlan>(
                  initialValue: selectedPlan,
                  decoration: const InputDecoration(
                    labelText: 'Plan',
                  ),
                  items: plans
                      .map((plan) => DropdownMenuItem(
                            value: plan,
                            child: Text(plan.name),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => selectedPlan = value);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: billingCycle,
                  decoration: const InputDecoration(
                    labelText: 'Billing cycle',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => billingCycle = value);
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  "Charge ${_priceFormat.format(billingCycle == 'yearly' ? selectedPlan.yearlyPrice : selectedPlan.monthlyPrice)} ${billingCycle == 'yearly' ? 'per year' : 'per month'}",
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await _service.switchSubscriptionPlan(
      subscription: subscription,
      newPlan: selectedPlan,
      billingCycle: billingCycle,
    );
  }

  Future<void> _runAutoExpire({bool showStatus = false}) async {
    if (_autoExpireInProgress) return;
    setState(() => _autoExpireInProgress = true);
    try {
      final updated = await _service.expireOverdueSubscriptions();
      if (!mounted || !showStatus) return;
      final text = updated == 0
          ? 'All subscriptions are up to date'
          : 'Marked $updated subscription(s) as expired';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(text)),
      );
    } catch (error) {
      if (mounted && showStatus) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Auto-expire failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _autoExpireInProgress = false);
      }
    }
  }

  DateTime? _dateFromTimestamp(Timestamp? timestamp) => timestamp?.toDate();

  int? _daysUntil(DateTime? date) {
    if (date == null) return null;
    return date.difference(DateTime.now()).inDays;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy').format(date);
  }

  Future<void> _handleExpire(UserSubscription subscription) async {
    await _service.expireSubscription(subscription);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription expired')),
    );
  }

  void _viewProfile(UserSubscription subscription) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => UserDetailScreen(userId: subscription.userId),
      ),
    );
  }

  Future<void> _handleNotify(
    UserSubscription subscription,
    int daysLeft,
  ) async {
    await _service.enqueueExpiringNotification(
      subscription,
      daysLeft: daysLeft,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder queued for delivery')),
    );
  }

  Future<void> _generateInvoice(
    UserSubscription subscription, {
    SubscriptionPlan? plan,
    required String priceLabel,
  }) async {
    final pdf = pw.Document();
    final start = _dateFromTimestamp(subscription.startedAt);
    final end = _dateFromTimestamp(subscription.renewsAt);
    final planName = _effectivePlanName(subscription, plan);
    final billingLabel = _resolveBillingLabel(subscription).toUpperCase();
    final userLabel = _subscriberLabel(subscription);

    pdf.addPage(
      pw.Page(
        build: (context) => pw.Padding(
          padding: const pw.EdgeInsets.all(24),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'SUBSCRIPTION INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Invoice ID: ${subscription.id}'),
              pw.Text('User: $userLabel'),
              pw.Text('Plan: $planName'),
              pw.Text('Billing: $billingLabel'),
              pw.Text('Price: $priceLabel'),
              pw.Text('Start Date: ${_formatDate(start)}'),
              pw.Text('End Date: ${_formatDate(end)}'),
              pw.SizedBox(height: 30),
              pw.Divider(),
              pw.Text(
                'Generated from Rental Admin Panel',
                style: pw.TextStyle(color: PdfColors.grey600),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildRevenueBar(
    List<SubscriptionPlan> plans,
    List<UserSubscription> subscriptions,
  ) {
    final planMap = _planMap(plans);
    final activePaid = subscriptions.where((sub) {
      if (!sub.isActive) return false;
      final amount = _resolveSubscriptionAmount(sub, planMap[sub.planId]);
      return amount > 0;
    });
    final total = activePaid.fold<int>(
      0,
      (sum, sub) => sum + _resolveSubscriptionAmount(sub, planMap[sub.planId]),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.bar_chart, color: Colors.green),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Active Revenue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Paid subscriptions currently active'),
            ],
          ),
          const Spacer(),
          Text(
            _priceFormat.format(total),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiringAlert(
    List<SubscriptionPlan> plans,
    List<UserSubscription> subscriptions,
  ) {
    final planMap = _planMap(plans);
    final expiringSoon = subscriptions.where((sub) {
      final daysLeft = _daysUntil(_dateFromTimestamp(sub.renewsAt));
      final amount = _resolveSubscriptionAmount(sub, planMap[sub.planId]);
      return sub.isActive &&
          amount > 0 &&
          daysLeft != null &&
          daysLeft >= 0 &&
          daysLeft <= 5;
    }).length;

    if (expiringSoon == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.notifications_active, color: Colors.orange),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$expiringSoon subscription(s) expiring within 5 days',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _subscriberLabel(UserSubscription subscription) {
    final name = subscription.userName?.trim();
    if (name != null && name.isNotEmpty) return name;
    final email = subscription.userEmail?.trim();
    if (email != null && email.isNotEmpty) return email;
    return subscription.userId;
  }

  Map<String, SubscriptionPlan> _planMap(List<SubscriptionPlan> plans) {
    return {for (final plan in plans) plan.id: plan};
  }

  int _resolveSubscriptionAmount(
    UserSubscription subscription,
    SubscriptionPlan? plan,
  ) {
    if (subscription.price > 0) return subscription.price;
    if (plan == null) return 0;
    final cycle = subscription.billingCycle.toLowerCase();
    final isYearly = cycle == 'yearly';
    final amount = isYearly ? plan.yearlyPrice : plan.monthlyPrice;
    return amount;
  }

  String _formatPriceLabel(int amount) {
    if (amount <= 0) return '₹0 (Free)';
    return _priceFormat.format(amount);
  }

  String _resolveBillingLabel(UserSubscription subscription) {
    final normalized = subscription.billingCycle.trim().toLowerCase();
    if (normalized == 'yearly') return 'Yearly';
    if (normalized == 'monthly') return 'Monthly';
    if (normalized.isEmpty) return 'Not provided';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _effectivePlanName(
    UserSubscription subscription,
    SubscriptionPlan? plan,
  ) {
    return plan?.name ?? subscription.planName;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: Colors.white,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(color: Colors.black54),
              ),
            ],
          )
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.priceFormat,
    required this.onEdit,
    required this.onToggleActive,
  });

  final SubscriptionPlan plan;
  final NumberFormat priceFormat;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;

  @override
  Widget build(BuildContext context) {
    final monthly =
        plan.isFree ? 'Free' : '${priceFormat.format(plan.monthlyPrice)}/mo';
    final yearly =
        plan.isFree ? '' : '${priceFormat.format(plan.yearlyPrice)}/yr';

    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: plan.active ? const Color(0xFF781C2E) : Colors.grey[300]!,
          width: 1.4,
        ),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: plan.active,
                onChanged: onToggleActive,
              ),
            ],
          ),
          Text(
            plan.audience == 'all'
                ? 'All users'
                : plan.audience == 'lender'
                    ? 'Lender tier'
                    : 'Renter tier',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 12),
          Text(
            plan.isFree ? '₹0' : monthly,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (yearly.isNotEmpty)
            Text(
              yearly,
              style: const TextStyle(color: Colors.black54),
            ),
          if (plan.description != null && plan.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                plan.description!,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Edit'),
            ),
          )
        ],
      ),
    );
  }
}

class _SubscriberCard extends StatelessWidget {
  const _SubscriberCard({
    required this.subscription,
    required this.userLabel,
    required this.planDisplayName,
    required this.billingLabel,
    required this.priceLabel,
    required this.onUpgrade,
    required this.onViewProfile,
    required this.startLabel,
    required this.renewLabel,
    required this.showInvoiceButton,
    required this.isExpiringSoon,
    this.daysLeft,
    this.onCancel,
    this.onExpire,
    this.onInvoice,
    this.onNotify,
  });

  final UserSubscription subscription;
  final String userLabel;
  final String planDisplayName;
  final String billingLabel;
  final String priceLabel;
  final VoidCallback onUpgrade;
  final VoidCallback onViewProfile;
  final String startLabel;
  final String renewLabel;
  final bool showInvoiceButton;
  final bool isExpiringSoon;
  final int? daysLeft;
  final VoidCallback? onCancel;
  final VoidCallback? onExpire;
  final VoidCallback? onInvoice;
  final VoidCallback? onNotify;

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall;
    final email = subscription.userEmail?.trim();
    final showEmail = email != null &&
        email.isNotEmpty &&
        email.toLowerCase() != userLabel.trim().toLowerCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo.withOpacity(0.1),
                foregroundColor: Colors.indigo,
                child: Text(
                  _initials(userLabel),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('ID: ${subscription.userId}', style: secondary),
                    if (showEmail) Text(email, style: secondary),
                  ],
                ),
              ),
              Chip(
                label: Text(subscription.status.toUpperCase()),
                backgroundColor: subscription.isActive
                    ? Colors.green.withOpacity(0.15)
                    : Colors.grey.withOpacity(0.15),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _infoRow('Plan', planDisplayName),
              _infoRow('Cycle', billingLabel),
              _infoRow('Price', priceLabel),
              _infoRow('Auto-renew', subscription.autoRenew ? 'Yes' : 'No'),
              _infoRow('Started', startLabel),
              _infoRow('Renews', renewLabel),
            ],
          ),
          if (isExpiringSoon && daysLeft != null)
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Expires in $daysLeft day(s)',
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (subscription.cancelReason?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Last reason: ${subscription.cancelReason}',
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.person_outline),
                label: const Text('View profile'),
              ),
              if (showInvoiceButton && onInvoice != null)
                OutlinedButton.icon(
                  onPressed: onInvoice,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Invoice'),
                ),
              if (isExpiringSoon && onNotify != null)
                OutlinedButton.icon(
                  onPressed: onNotify,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: const Text('Notify user'),
                ),
              TextButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
              ),
              TextButton.icon(
                onPressed: onExpire,
                icon: const Icon(Icons.timer_off_outlined),
                label: const Text('Expire'),
              ),
              FilledButton(
                onPressed: onUpgrade,
                child: const Text('Upgrade / Move'),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(value),
      ],
    );
  }

  static String _initials(String source) {
    final trimmed = source.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(' ');
    if (parts.length == 1) return trimmed[0].toUpperCase();
    return parts.take(2).map((e) => e[0].toUpperCase()).join();
  }
}
