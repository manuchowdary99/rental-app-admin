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

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  TimeRange selectedRange = TimeRange.all;

  // =============================
  // DATE FILTER
  // =============================
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

  // =============================
  // FIRESTORE COUNT STREAM
  // =============================
  Stream<int> _count(
    String collection, {
    String? field,
    String? equals,
  }) {
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

    return query.snapshots().map((s) => s.docs.length);
  }

  // =============================
  // NAVIGATION
  // =============================
  void _openDetails(String title) {
    switch (title) {
      case "Users":
        Navigator.pushNamed(context, "/users");
        break;
      case "Verified":
        Navigator.pushNamed(context, "/kyc");
        break;
      case "Rentals":
        Navigator.pushNamed(context, "/rentals");
        break;
      case "Complaints":
        Navigator.pushNamed(context, "/complaints");
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
              _kpiBar(),
              const SizedBox(height: 32),
              _analyticsRow(),
            ],
          ),
        ),
      ),
    );
  }

  // =============================
  // HEADER
  // =============================
  Widget _header() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF781C2E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.analytics_rounded,
            color: Color(0xFF781C2E),
          ),
        ),
        const SizedBox(width: 12),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "System Overview",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              "Live operational and business metrics",
              style: TextStyle(color: Colors.grey),
            ),
          ],
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

  // =============================
  // RANGE BUTTON
  // =============================
  Widget _rangeButton(String label, TimeRange range) {
    final isSelected = selectedRange == range;

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF781C2E) : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        side: BorderSide(
          color: isSelected ? const Color(0xFF781C2E) : Colors.grey.shade300,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      onPressed: () {
        setState(() {
          selectedRange = range;
        });
      },
      child: Text(label),
    );
  }

  // =============================
  // KPI BAR
  // =============================
  Widget _kpiBar() {
    return Row(
      children: [
        Expanded(child: _kpi("Users", "users", Icons.people)),
        const SizedBox(width: 16),
        Expanded(
          child: _kpi(
            "Verified",
            "kyc",
            Icons.verified_user,
            "status",
            "approved",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _kpi("Rentals", "orders", Icons.shopping_bag)),
        const SizedBox(width: 16),
        Expanded(
          child: _kpi(
            "Active",
            "orders",
            Icons.local_shipping,
            "status",
            "active",
          ),
        ),
        const SizedBox(width: 16),
        Expanded(child: _kpi("Complaints", "complaints", Icons.support_agent)),
      ],
    );
  }

  // =============================
  // KPI CARD
  // =============================
  Widget _kpi(
    String title,
    String collection,
    IconData icon, [
    String? field,
    String? equals,
  ]) {
    return StreamBuilder<int>(
      stream: _count(
        collection,
        field: field,
        equals: equals,
      ),
      builder: (context, snapshot) {
        final value = snapshot.hasData ? snapshot.data.toString() : "...";

        return InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openDetails(title),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF781C2E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF781C2E),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // =============================
  // ANALYTICS ROW
  // =============================
  Widget _analyticsRow() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _KycPieChart()),
        SizedBox(width: 24),
        Expanded(child: _RentalsLineChart()),
      ],
    );
  }
}

// =============================
// KYC PIE CHART
// =============================
class _KycPieChart extends StatelessWidget {
  const _KycPieChart();

  Stream<Map<String, int>> _kycStats() {
    return FirebaseFirestore.instance
        .collection("kyc")
        .snapshots()
        .map((snapshot) {
      int approved = 0;
      int pending = 0;
      int rejected = 0;

      for (var doc in snapshot.docs) {
        final status = doc["status"];
        if (status == "approved") approved++;
        if (status == "pending") pending++;
        if (status == "rejected") rejected++;
      }

      return {
        "approved": approved,
        "pending": pending,
        "rejected": rejected,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, int>>(
      stream: _kycStats(),
      builder: (context, snapshot) {
        final data =
            snapshot.data ?? {"approved": 1, "pending": 1, "rejected": 1};

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.pushNamed(context, '/kyc'),
          child: _card(
            "KYC Status Distribution",
            PieChart(
              PieChartData(
                centerSpaceRadius: 50,
                sectionsSpace: 4,
                sections: [
                  PieChartSectionData(
                    value: data["approved"]!.toDouble(),
                    title: "Approved",
                    color: Colors.green,
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: data["pending"]!.toDouble(),
                    title: "Pending",
                    color: Colors.orange,
                    radius: 60,
                  ),
                  PieChartSectionData(
                    value: data["rejected"]!.toDouble(),
                    title: "Rejected",
                    color: Colors.red,
                    radius: 60,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================
// RENTALS LINE CHART
// =============================
class _RentalsLineChart extends StatelessWidget {
  const _RentalsLineChart();

  @override
  Widget build(BuildContext context) {
    return _card(
      "Rentals Growth",
      LineChart(
        LineChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 2),
                FlSpot(1, 4),
                FlSpot(2, 6),
                FlSpot(3, 8),
                FlSpot(4, 11),
                FlSpot(5, 15),
              ],
              isCurved: true,
              color: const Color(0xFF781C2E),
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF781C2E).withOpacity(0.15),
              ),
              dotData: FlDotData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================
// CARD WRAPPER
// =============================
Widget _card(String title, Widget child) {
  return Container(
    height: 320,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),
        Expanded(child: child),
      ],
    ),
  );
}
