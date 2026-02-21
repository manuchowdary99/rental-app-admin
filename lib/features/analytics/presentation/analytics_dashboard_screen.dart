import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../navigation/widgets/admin_app_drawer.dart';

enum TimeRange { today, week, month, all }

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimeRange selectedRange = TimeRange.all;

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

            return Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    theme.colorScheme.surface,
                    theme.colorScheme.surfaceContainerHighest,
                  ],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KYC Status Distribution',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AspectRatio(
                    aspectRatio: 1,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            centerSpaceRadius: 72,
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
                    ),
                  ),
                  const SizedBox(height: 24),
                  _LegendRow(
                    color: _approvedColor,
                    label: 'Approved',
                    value: approved,
                  ),
                  const SizedBox(height: 12),
                  _LegendRow(
                    color: _pendingColor,
                    label: 'Pending',
                    value: pending,
                  ),
                  const SizedBox(height: 12),
                  _LegendRow(
                    color: _rejectedColor,
                    label: 'Rejected',
                    value: rejected,
                  ),
                  const SizedBox(height: 12),
                  _LegendRow(
                    color: _notSubmittedColor,
                    label: 'Not submitted',
                    value: notSubmitted,
                  ),
                ],
              ),
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
