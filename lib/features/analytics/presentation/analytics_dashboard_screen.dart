import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

enum TimeRange { today, week, month, all }

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends State<AnalyticsDashboardScreen> {
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

  Stream<int> _count(String collection,
      {String? field, String? equals}) {
    Query query =
        FirebaseFirestore.instance.collection(collection);

    if (_startDate != null) {
      query = query.where(
        'createdAt',
        isGreaterThanOrEqualTo:
            Timestamp.fromDate(_startDate!),
      );
    }

    if (field != null && equals != null) {
      query = query.where(field, isEqualTo: equals);
    }

    return query.snapshots().map((e) => e.docs.length);
  }

  void _openDetails(String title) {
    switch (title) {
      case "Users":
        Navigator.pushNamed(context, "/users");
        break;
      case "Verified":
        Navigator.pushNamed(context, "/kyc");
        break;
      case "Rentals":
        Navigator.pushNamed(context, "/orders");
        break;
      case "Support":
        Navigator.pushNamed(context, "/support-tickets");
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 24),
              _kpiRow(),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Expanded(child: _KycPieChart()),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _RentalsLineChart(
                        startDate: _startDate),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      children: [
        const Text(
          "System Overview",
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        _rangeButton("Today", TimeRange.today),
        const SizedBox(width: 8),
        _rangeButton("7 Days", TimeRange.week),
        const SizedBox(width: 8),
        _rangeButton("30 Days", TimeRange.month),
        const SizedBox(width: 8),
        _rangeButton("All Time", TimeRange.all),
      ],
    );
  }

  Widget _rangeButton(
      String label, TimeRange range) {
    final isSelected = selectedRange == range;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected
            ? const Color(0xFF781C2E)
            : Colors.white,
        foregroundColor:
            isSelected ? Colors.white : Colors.black87,
      ),
      onPressed: () {
        setState(() {
          selectedRange = range;
        });
      },
      child: Text(label),
    );
  }

  Widget _kpiRow() {
    return Row(
      children: [
        Expanded(
            child: _kpi("Users", "users",
                Icons.people)),
        const SizedBox(width: 16),
        Expanded(
            child: _kpi("Verified", "kyc",
                Icons.verified_user, "status",
                "approved")),
        const SizedBox(width: 16),
        Expanded(
            child: _kpi("Rentals", "orders",
                Icons.shopping_bag)),
        const SizedBox(width: 16),
        Expanded(
            child: _kpi("Support",
                "support_tickets",
                Icons.support_agent)),
      ],
    );
  }

  Widget _kpi(String title, String collection,
      IconData icon,
      [String? field, String? equals]) {
    return StreamBuilder<int>(
      stream:
          _count(collection, field: field, equals: equals),
      builder: (context, snapshot) {
        final value =
            snapshot.hasData ? snapshot.data : 0;

        return InkWell(
          onTap: () => _openDetails(title),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color:
                        Colors.black.withOpacity(0.05),
                    blurRadius: 8)
              ],
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: const Color(0xFF781C2E)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text("$value",
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight:
                                FontWeight.bold)),
                    Text(title,
                        style: const TextStyle(
                            color: Colors.grey)),
                  ],
                )
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("kyc")
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _chartCard(
              "KYC Status Distribution",
              const Center(
                  child:
                      CircularProgressIndicator()));
        }

        int approved = 0;
        int pending = 0;
        int rejected = 0;

        for (var doc in snapshot.data!.docs) {
          final status =
              (doc["status"] ?? "")
                  .toString()
                  .toLowerCase();

          if (status == "approved") approved++;
          if (status == "pending") pending++;
          if (status == "rejected") rejected++;
        }

        List<PieChartSectionData> sections = [];

        if (approved > 0) {
          sections.add(PieChartSectionData(
              value: approved.toDouble(),
              title: "Approved ($approved)",
              color: Colors.green));
        }

        if (pending > 0) {
          sections.add(PieChartSectionData(
              value: pending.toDouble(),
              title: "Pending ($pending)",
              color: Colors.orange));
        }

        if (rejected > 0) {
          sections.add(PieChartSectionData(
              value: rejected.toDouble(),
              title: "Rejected ($rejected)",
              color: Colors.red));
        }

        return _chartCard(
          "KYC Status Distribution",
          PieChart(
            PieChartData(
              centerSpaceRadius: 50,
              sections: sections.isEmpty
                  ? [
                      PieChartSectionData(
                          value: 1,
                          title: "No Data",
                          color: Colors.grey)
                    ]
                  : sections,
            ),
          ),
        );
      },
    );
  }
}

class _RentalsLineChart extends StatelessWidget {
  final DateTime? startDate;

  const _RentalsLineChart({this.startDate});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance
        .collection("orders")
        .orderBy("createdAt");

    if (startDate != null) {
      query = query.where(
        "createdAt",
        isGreaterThanOrEqualTo:
            Timestamp.fromDate(startDate!),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return _chartCard(
              "Rentals Growth",
              const Center(
                  child:
                      CircularProgressIndicator()));
        }

        Map<DateTime, int> grouped = {};

        for (var doc in snapshot.data!.docs) {
          if (doc["createdAt"] == null) continue;

          DateTime date =
              (doc["createdAt"] as Timestamp)
                  .toDate();

          DateTime day = DateTime(
              date.year, date.month, date.day);

          grouped[day] =
              (grouped[day] ?? 0) + 1;
        }

        final sorted =
            grouped.keys.toList()..sort();

        List<FlSpot> spots = [];

        for (int i = 0;
            i < sorted.length;
            i++) {
          spots.add(FlSpot(
              i.toDouble(),
              grouped[sorted[i]]!
                  .toDouble()));
        }

        return _chartCard(
          "Rentals Growth (Daily)",
          LineChart(
            LineChartData(
              borderData:
                  FlBorderData(show: false),
              gridData:
                  FlGridData(show: true),
              titlesData:
                  FlTitlesData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: spots.isEmpty
                      ? [const FlSpot(0, 0)]
                      : spots,
                  isCurved: true,
                  color:
                      const Color(0xFF781C2E),
                  barWidth: 4,
                  belowBarData:
                      BarAreaData(
                          show: true,
                          color: const Color(
                                  0xFF781C2E)
                              .withOpacity(
                                  0.15)),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget _chartCard(
    String title, Widget child) {
  return Container(
    height: 320,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius:
          BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
            color:
                Colors.black.withOpacity(0.05),
            blurRadius: 10)
      ],
    ),
    child: Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontWeight:
                    FontWeight.bold)),
        const SizedBox(height: 20),
        Expanded(child: child),
      ],
    ),
  );
}
