import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../navigation/widgets/admin_app_drawer.dart';
import '../../subscriptions/presentation/admin_subscriptions_screen.dart';

enum TimeRange { today, week, month, all }

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimeRange selectedRange = TimeRange.all;
  final NumberFormat _currencyFormat =
      NumberFormat.currency(symbol: '₹', decimalDigits: 0);

  DateTime? get _startDate {
    final now = DateTime.now();
    switch (selectedRange) {
      case TimeRange.today:
        return DateTime(now.year, now.month, now.day);
      case TimeRange.week:
        return now.subtract(const Duration(days: 7));
      case TimeRange.month:
        return now.subtract(const Duration(days: 30));
      case TimeRange.all:
        return null;
    }
  }

  Stream<int> _count(String collection, {String? field, String? equals}) {
    Query query = FirebaseFirestore.instance.collection(collection);

    if (_startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(_startDate!),
      );
    }

    if (field != null && equals != null) {
      query = query.where(field, isEqualTo: equals);
    }

    return query.snapshots().map((e) => e.docs.length);
  }

  void _openDetails(String title) {
    final routeMap = {
      'Total Users': '/users',
      'Verified KYC': '/kyc',
      'Rentals': '/orders',
      'Support Tickets': '/support-tickets',
    };

    final route = routeMap[title];
    if (route != null) {
      Navigator.pushNamed(context, route);
    }
  }

  void _openSubscriptionManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AdminSubscriptionsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
      ),
      drawer: const AdminAppDrawer(),
      body: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth;
            final isWide = maxWidth >= 1080;
            final horizontalPadding = maxWidth >= 900
                ? 32.0
                : maxWidth >= 600
                    ? 24.0
                    : 16.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                28,
                horizontalPadding,
                40,
              ),
              children: [
                _header(theme, maxWidth),
                const SizedBox(height: 24),
                _buildKpiGrid(),
                const SizedBox(height: 24),
                _buildRevenueSection(),
                const SizedBox(height: 32),
                if (isWide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(child: _KycPieChart()),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _RentalsLineChart(startDate: _startDate),
                      ),
                    ],
                  )
                else ...[
                  const _KycPieChart(),
                  const SizedBox(height: 24),
                  _RentalsLineChart(startDate: _startDate),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _header(ThemeData theme, double maxWidth) {
    final isStacked = maxWidth < 600;

    final controls = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _rangeButton('Today', TimeRange.today),
        _rangeButton('7 Days', TimeRange.week),
        _rangeButton('30 Days', TimeRange.month),
        _rangeButton('All Time', TimeRange.all),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.secondary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: isStacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Overview',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Monitor product health, user growth, rentals, and support trends in a single glance.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 20),
                controls,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'System Overview',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Monitor product health, user growth, rentals, and support trends in a single glance.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onPrimary
                              .withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                controls,
              ],
            ),
    );
  }

  Widget _rangeButton(String label, TimeRange range) {
    final isSelected = selectedRange == range;
    final theme = Theme.of(context);

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected
            ? theme.colorScheme.onPrimary
            : theme.colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      selectedColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surface,
      side: BorderSide(
        color:
            isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      onSelected: (_) {
        setState(() => selectedRange = range);
      },
    );
  }

  Widget _buildKpiGrid() {
    final cards = [
      _kpi('Total Users', 'users', Icons.people),
      _kpi('Verified KYC', 'kyc', Icons.verified_user, 'status', 'approved'),
      _kpi('Rentals', 'orders', Icons.shopping_bag),
      _kpi('Support Tickets', 'support_tickets', Icons.support_agent),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 1;
        if (width >= 1100) {
          columns = 4;
        } else if (width >= 720) {
          columns = 2;
        }
        final spacing = 16.0;
        final itemWidth =
            columns == 1 ? width : (width - (columns - 1) * spacing) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: itemWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildRevenueSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('plans').snapshots(),
      builder: (context, plansSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('subscriptions')
              .snapshots(),
          builder: (context, snapshot) {
            final report =
                _buildRevenueReport(snapshot.data, plansSnapshot.data);
            final theme = Theme.of(context);

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revenue Overview',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Total stored subscription income',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _currencyFormat.format(report.totalRevenue),
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final cards = [
                        _StatCard(
                          label: 'Monthly Revenue',
                          value: _currencyFormat.format(report.monthlyRevenue),
                          icon: Icons.calendar_month_rounded,
                          color: Colors.green,
                        ),
                        _StatCard(
                          label: 'Annual Income',
                          value: _currencyFormat.format(report.annualRevenue),
                          icon: Icons.stacked_line_chart_rounded,
                          color: Colors.teal,
                        ),
                      ];

                      if (constraints.maxWidth < 760) {
                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: cards
                              .map(
                                (card) => SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  child: card,
                                ),
                              )
                              .toList(),
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 12),
                          Expanded(child: cards[1]),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 980;
                      if (isNarrow) {
                        return Column(
                          children: [
                            SizedBox(
                              height: 260,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _openSubscriptionManagement,
                                child: _RevenueTrendChart(
                                  points: report.monthlyTrend,
                                  currencyFormat: _currencyFormat,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 260,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _openSubscriptionManagement,
                                child: _PlanRevenueBarChart(
                                  entries: report.planBreakdown,
                                ),
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 260,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _openSubscriptionManagement,
                                child: _RevenueTrendChart(
                                  points: report.monthlyTrend,
                                  currencyFormat: _currencyFormat,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 260,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: _openSubscriptionManagement,
                                child: _PlanRevenueBarChart(
                                  entries: report.planBreakdown,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  _RevenueReport _buildRevenueReport(
    QuerySnapshot<Map<String, dynamic>>? snapshot,
    QuerySnapshot<Map<String, dynamic>>? plansSnapshot,
  ) {
    final now = DateTime.now();
    final annualWindowStart = now.subtract(const Duration(days: 365));
    final monthlyBuckets = <DateTime, double>{};
    for (var i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      monthlyBuckets[date] = 0;
    }

    final planTotals = <String, int>{};
    double totalRevenue = 0;
    double monthlyRevenue = 0;
    double annualRevenue = 0;

    final planLookup = _buildPlanLookup(plansSnapshot);
    final orderedPlanNames = _orderedPlanNames(plansSnapshot);

    if (snapshot != null) {
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final status =
            (data['status'] ?? data['subscriptionStatus'] ?? 'active')
                .toString()
                .toLowerCase();

        final amount = _toDouble(
          data['price'] ?? data['amount'] ?? data['subscriptionAmount'],
        );
        if (amount <= 0) continue;

        final timestamp = _extractTimestamp(data);
        final billedAt = timestamp?.toDate();
        final billedWithinAnnualWindow =
            billedAt != null && !billedAt.isBefore(annualWindowStart);

        if (billedWithinAnnualWindow) {
          annualRevenue += amount;
        }

        if (status != 'active') continue;

        totalRevenue += amount;

        final cycle =
            (data['billingCycle'] ?? data['subscriptionCycle'] ?? 'monthly')
                .toString()
                .toLowerCase();
        if (cycle == 'monthly') {
          monthlyRevenue += amount;
        }

        final planName = _resolvePlanName(data, planLookup);
        planTotals[planName] = (planTotals[planName] ?? 0) + 1;

        if (timestamp == null) continue;
        final date = timestamp.toDate();
        final monthKey = DateTime(date.year, date.month, 1);
        if (monthlyBuckets.containsKey(monthKey)) {
          monthlyBuckets[monthKey] = (monthlyBuckets[monthKey] ?? 0) + amount;
        }
      }
    }

    final monthlyTrend = monthlyBuckets.entries
        .map((entry) => _RevenueMonthPoint(entry.key, entry.value))
        .toList();

    final planBreakdown = orderedPlanNames
        .take(3)
        .map((planName) =>
            _PlanRevenueEntry(planName, (planTotals[planName] ?? 0).toDouble()))
        .toList();

    final fallbackPlanBreakdown = [
      const _PlanRevenueEntry('Plan 1', 0),
      const _PlanRevenueEntry('Plan 2', 0),
      const _PlanRevenueEntry('Plan 3', 0),
    ];

    return _RevenueReport(
      totalRevenue: totalRevenue,
      monthlyRevenue: monthlyRevenue,
      annualRevenue: annualRevenue,
      monthlyTrend: monthlyTrend,
      planBreakdown:
          planBreakdown.isEmpty ? fallbackPlanBreakdown : planBreakdown,
    );
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim()) ?? 0;
    return 0;
  }

  Map<String, String> _buildPlanLookup(
    QuerySnapshot<Map<String, dynamic>>? plansSnapshot,
  ) {
    final lookup = <String, String>{};
    if (plansSnapshot == null) return lookup;

    for (final doc in plansSnapshot.docs) {
      final data = doc.data();
      final name = (data['name'] ?? doc.id).toString().trim();
      final code = (data['code'] ?? doc.id).toString().trim();
      if (name.isNotEmpty) {
        lookup[doc.id] = name;
        lookup[name.toLowerCase()] = name;
      }
      if (code.isNotEmpty) {
        lookup[code.toLowerCase()] = name;
      }
    }

    return lookup;
  }

  List<String> _orderedPlanNames(
    QuerySnapshot<Map<String, dynamic>>? plansSnapshot,
  ) {
    if (plansSnapshot == null) return const [];

    final plans = plansSnapshot.docs.map((doc) {
      final data = doc.data();
      final name = (data['name'] ?? doc.id).toString().trim();
      final active = data['active'] != false;
      final isFree =
          _toDouble(data['monthlyPrice'] ?? data['yearlyPrice']) == 0;
      final sortIndex =
          (data['sortIndex'] is num) ? (data['sortIndex'] as num).toInt() : 999;
      return _PlanDisplayName(
        name: name.isEmpty ? doc.id : name,
        sortIndex: sortIndex,
        active: active,
        isFree: isFree,
      );
    }).toList()
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    return plans
        .where((plan) => plan.active && !plan.isFree)
        .map((plan) => plan.name)
        .toList();
  }

  String _resolvePlanName(
    Map<String, dynamic> data,
    Map<String, String> planLookup,
  ) {
    final candidates = [
      data['planId'],
      data['subscriptionTier'],
      data['planName'],
      data['code'],
    ];

    for (final candidate in candidates) {
      final key = candidate?.toString().trim();
      if (key == null || key.isEmpty) continue;

      final resolved = planLookup[key] ?? planLookup[key.toLowerCase()];
      if (resolved != null && resolved.isNotEmpty) {
        return resolved;
      }
    }

    return '';
  }

  Timestamp? _extractTimestamp(Map<String, dynamic> data) {
    final candidates = [
      data['updatedAt'],
      data['startedAt'],
      data['createdAt'],
      data['reviewedAt'],
      data['subscriptionStart'],
    ];

    for (final candidate in candidates) {
      if (candidate is Timestamp) return candidate;
    }
    return null;
  }

  Widget _kpi(String title, String collection, IconData icon,
      [String? field, String? equals]) {
    return StreamBuilder<int>(
      stream: _count(collection, field: field, equals: equals),
      builder: (context, snapshot) {
        final value = snapshot.hasData ? snapshot.data ?? 0 : 0;
        final theme = Theme.of(context);

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openDetails(title),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$value',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.primary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PlanDisplayName {
  const _PlanDisplayName({
    required this.name,
    required this.sortIndex,
    required this.active,
    required this.isFree,
  });

  final String name;
  final int sortIndex;
  final bool active;
  final bool isFree;
}

class _KycPieChart extends StatelessWidget {
  const _KycPieChart();

  static const Color _approvedColor = Color(0xFF1FC77E);
  static const Color _pendingColor = Color(0xFFFFC247);
  static const Color _rejectedColor = Color(0xFFFF5C5C);
  static const Color _notSubmittedColor = Color(0xFF3B82F6);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, usersSnapshot) {
        if (!usersSnapshot.hasData) {
          return _chartCard(
            'KYC Status Distribution',
            const Center(child: CircularProgressIndicator()),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('kyc').snapshots(),
          builder: (context, kycSnapshot) {
            final kycStatusMap = <String, String>{};
            if (kycSnapshot.hasData) {
              for (final doc in kycSnapshot.data!.docs) {
                final data = doc.data();
                final userId = (data['userId'] ?? doc.id).toString();
                kycStatusMap[userId] = data['status']?.toString() ?? '';
              }
            }

            int approved = 0;
            int pending = 0;
            int rejected = 0;
            int notSubmitted = 0;

            for (final doc in usersSnapshot.data!.docs) {
              final data = doc.data();
              String status = _normalizeStatus(data['kycStatus']);
              if (status == 'not_submitted') {
                final fallback = _normalizeStatus(kycStatusMap[doc.id]);
                if (fallback != 'not_submitted') {
                  status = fallback;
                }
              }

              switch (status) {
                case 'approved':
                  approved++;
                  break;
                case 'pending':
                  pending++;
                  break;
                case 'rejected':
                  rejected++;
                  break;
                default:
                  notSubmitted++;
              }
            }

            final total = usersSnapshot.data!.docs.length;
            final approvedPercent = total == 0 ? 0 : (approved / total);

            final sections = total == 0
                ? [
                    PieChartSectionData(
                      value: 1,
                      color: theme.colorScheme.outlineVariant,
                      showTitle: false,
                      radius: 70,
                    ),
                  ]
                : [
                    _buildSection(approved, _approvedColor),
                    _buildSection(pending, _pendingColor),
                    _buildSection(rejected, _rejectedColor),
                    _buildSection(notSubmitted, _notSubmittedColor),
                  ].where((section) => section.value > 0).toList();

            Widget buildPie() {
              return Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      centerSpaceRadius: 68,
                      sectionsSpace: 4,
                      startDegreeOffset: -90,
                      sections: sections.isEmpty
                          ? [
                              PieChartSectionData(
                                value: 1,
                                color: theme.colorScheme.outlineVariant,
                                showTitle: false,
                              ),
                            ]
                          : sections,
                      pieTouchData: PieTouchData(enabled: false),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${(approvedPercent * 100).round()}%',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == 0 ? 'No data' : 'Approved',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        total == 0
                            ? '0 users'
                            : '$approved user${approved == 1 ? '' : 's'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

            Widget buildLegend({required bool wrap}) {
              final rows = [
                _LegendRow(
                  color: _approvedColor,
                  label: 'Approved',
                  value: approved,
                ),
                _LegendRow(
                  color: _pendingColor,
                  label: 'Pending',
                  value: pending,
                ),
                _LegendRow(
                  color: _rejectedColor,
                  label: 'Rejected',
                  value: rejected,
                ),
                _LegendRow(
                  color: _notSubmittedColor,
                  label: 'Not submitted',
                  value: notSubmitted,
                ),
              ];

              if (wrap) {
                return Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  children: rows
                      .map(
                        (row) => SizedBox(
                          width: 150,
                          child: row,
                        ),
                      )
                      .toList(),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    rows[i],
                  ]
                ],
              );
            }

            final content = LayoutBuilder(
              builder: (context, constraints) {
                final isHorizontal = constraints.maxWidth > 520;
                final maxHeight = constraints.maxHeight.isFinite
                    ? constraints.maxHeight
                    : 260.0;

                final chartSize = isHorizontal
                    ? math.max(180.0, math.min(maxHeight, 260.0))
                    : math.max(140.0, math.min(maxHeight * 0.55, 200.0));

                final chartBox = SizedBox(
                  width: chartSize,
                  height: chartSize,
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: SizedBox(
                      width: 320,
                      height: 320,
                      child: buildPie(),
                    ),
                  ),
                );

                final legend = buildLegend(wrap: !isHorizontal);

                if (isHorizontal) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Center(child: chartBox),
                      ),
                      const SizedBox(width: 24),
                      Expanded(flex: 2, child: legend),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: chartBox),
                    const SizedBox(height: 16),
                    legend,
                  ],
                );
              },
            );

            final card = _chartCard(
              'KYC Status Distribution',
              content,
            );

            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => Navigator.pushNamed(context, '/kyc'),
              child: card,
            );
          },
        );
      },
    );
  }

  static String _normalizeStatus(dynamic raw) {
    final value = raw?.toString().trim().toLowerCase() ?? '';
    if (value.isEmpty) return 'not_submitted';
    if (value == 'approved' || value == 'verified') return 'approved';
    if (value == 'rejected' || value == 'declined') return 'rejected';
    if (value == 'pending' || value == 'submitted' || value == 'in_review') {
      return 'pending';
    }
    return 'not_submitted';
  }

  PieChartSectionData _buildSection(int count, Color color) {
    return PieChartSectionData(
      value: count.toDouble(),
      color: color,
      radius: 80,
      showTitle: false,
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.9),
        width: 3,
      ),
    );
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final iconColor =
        color.computeLuminance() > 0.5 ? scheme.onSurface : Colors.white;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color,
            foregroundColor: iconColor,
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
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
}

class _RevenueTrendChart extends StatelessWidget {
  const _RevenueTrendChart({
    required this.points,
    required this.currencyFormat,
  });

  final List<_RevenueMonthPoint> points;
  final NumberFormat currencyFormat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chartPoints = points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.revenue))
        .toList();

    final maxY = points.isEmpty
        ? 100.0
        : points
                .map((point) => point.revenue)
                .reduce(math.max)
                .clamp(100.0, double.infinity) *
            1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Revenue Trend',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      currencyFormat.format(value),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= points.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          DateFormat('MMM').format(points[index].month),
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots:
                      chartPoints.isEmpty ? const [FlSpot(0, 0)] : chartPoints,
                  isCurved: true,
                  barWidth: 3,
                  color: const Color(0xFF781C2E),
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF781C2E).withValues(alpha: 0.14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanRevenueBarChart extends StatelessWidget {
  const _PlanRevenueBarChart({
    required this.entries,
  });

  final List<_PlanRevenueEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data =
        entries.isEmpty ? const [_PlanRevenueEntry('No data', 0)] : entries;
    final maxY = data
            .map((entry) => entry.revenue)
            .reduce(math.max)
            .clamp(100.0, double.infinity) *
        1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue by Plan',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              gridData: FlGridData(show: true),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 52,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => Text(
                      value.toInt().toString(),
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final label = data[index].planName;
                      final short = label.length > 10
                          ? '${label.substring(0, 10)}…'
                          : label;
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          short,
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: data.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.revenue,
                      width: 20,
                      borderRadius: BorderRadius.circular(6),
                      color: const Color(0xFF129A8E),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _RevenueReport {
  const _RevenueReport({
    required this.totalRevenue,
    required this.monthlyRevenue,
    required this.annualRevenue,
    required this.monthlyTrend,
    required this.planBreakdown,
  });

  final double totalRevenue;
  final double monthlyRevenue;
  final double annualRevenue;
  final List<_RevenueMonthPoint> monthlyTrend;
  final List<_PlanRevenueEntry> planBreakdown;
}

class _RevenueMonthPoint {
  const _RevenueMonthPoint(this.month, this.revenue);

  final DateTime month;
  final double revenue;
}

class _PlanRevenueEntry {
  const _PlanRevenueEntry(this.planName, this.revenue);

  final String planName;
  final double revenue;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$value',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _RentalsLineChart extends StatelessWidget {
  const _RentalsLineChart({this.startDate});

  final DateTime? startDate;

  @override
  Widget build(BuildContext context) {
    Query query =
        FirebaseFirestore.instance.collection('orders').orderBy('createdAt');

    if (startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startDate!),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _chartCard(
            'Rentals Growth',
            const Center(child: CircularProgressIndicator()),
          );
        }

        final grouped = <DateTime, int>{};
        for (final doc in snapshot.data!.docs) {
          final ts = doc['createdAt'] as Timestamp?;
          if (ts == null) continue;
          final date = ts.toDate();
          final day = DateTime(date.year, date.month, date.day);
          grouped[day] = (grouped[day] ?? 0) + 1;
        }

        final sorted = grouped.keys.toList()..sort();
        final spots = <FlSpot>[];
        for (var i = 0; i < sorted.length; i++) {
          spots.add(FlSpot(i.toDouble(), grouped[sorted[i]]!.toDouble()));
        }

        return _chartCard(
          'Rentals Growth (Daily)',
          LineChart(
            LineChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: true),
              titlesData: FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots.isEmpty ? [const FlSpot(0, 0)] : spots,
                  isCurved: true,
                  color: const Color(0xFF781C2E),
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF781C2E).withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _chartCard(String title, Widget child) {
  return Builder(
    builder: (context) {
      final theme = Theme.of(context);
      return Container(
        height: 320,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 18,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(child: child),
          ],
        ),
      );
    },
  );
}
