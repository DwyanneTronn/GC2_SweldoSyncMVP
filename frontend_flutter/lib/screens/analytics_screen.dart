import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _analytics;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await ApiService.getDashboardAnalytics();
      setState(() {
        _analytics = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading analytics: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error', style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _analytics == null
                  ? const Center(child: Text('No data available'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(),
                          const SizedBox(height: 24),
                          _buildMonthlyTrendsChart(),
                          const SizedBox(height: 24),
                          _buildPayrollByStatus(),
                          const SizedBox(height: 24),
                          _buildPayrollByIndustry(),
                          const SizedBox(height: 24),
                          _buildRecentActivity(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildSummaryCards() {
    final payroll = _analytics!['payroll'] as Map<String, dynamic>;
    final employees = _analytics!['employees'] as Map<String, dynamic>;
    final subscription = _analytics!['subscription'] as Map<String, dynamic>?;

    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Total Payroll Cost',
            value: '₱${(payroll['totalCost'] as num).toStringAsFixed(2)}',
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Total Runs',
            value: '${payroll['totalRuns']}',
            icon: Icons.receipt_long,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Employees',
            value: '${employees['total']}',
            icon: Icons.people,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Subscription',
            value: subscription != null ? subscription['plan'].toString().toUpperCase() : 'None',
            icon: Icons.subscriptions,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyTrendsChart() {
    final trends = _analytics!['payroll']['monthlyTrends'] as List;
    
    if (trends.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(child: Text('No payroll data available')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Payroll Trends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: trends.map((t) => (t['total'] as num).toDouble()).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < trends.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                trends[value.toInt()]['month'],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text('₱${(value / 1000).toStringAsFixed(0)}k');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: true),
                  borderData: FlBorderData(show: true),
                  barGroups: trends.asMap().entries.map((entry) {
                    final index = entry.key;
                    final trend = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: (trend['total'] as num).toDouble(),
                          color: Colors.blue,
                          width: 20,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollByStatus() {
    final byStatus = _analytics!['payroll']['byStatus'] as Map<String, dynamic>;
    
    if (byStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll by Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...byStatus.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key.toUpperCase()),
                      Chip(
                        label: Text('${entry.value}'),
                        backgroundColor: _getStatusColor(entry.key),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPayrollByIndustry() {
    final byIndustry = _analytics!['payroll']['byIndustry'] as Map<String, dynamic>;
    
    if (byIndustry.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Payroll by Industry',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: byIndustry.entries.map((entry) {
                    final total = byIndustry.values.reduce((a, b) => (a as num) + (b as num)) as num;
                    final percentage = ((entry.value as num) / total * 100);
                    return PieChartSectionData(
                      value: (entry.value as num).toDouble(),
                      title: '${entry.key}\n${percentage.toStringAsFixed(1)}%',
                      color: _getIndustryColor(entry.key),
                      radius: 80,
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activity = _analytics!['recentActivity'] as List;
    
    if (activity.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...activity.map((item) => ListTile(
                  title: Text(item['payPeriod']),
                  subtitle: Text('${item['employeeCount']} employees • ${item['status']}'),
                  trailing: Text(
                    '₱${(item['totalCost'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.shade100;
      case 'calculated':
        return Colors.blue.shade100;
      case 'disbursed':
        return Colors.purple.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  Color _getIndustryColor(String industry) {
    switch (industry.toLowerCase()) {
      case 'standard':
        return Colors.blue;
      case 'bpo':
        return Colors.purple;
      case 'airline':
        return Colors.lightBlue;
      default:
        return Colors.grey;
    }
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  Color get _lightColor {
    if (color == Colors.blue) return Colors.blue.shade50;
    if (color == Colors.green) return Colors.green.shade50;
    if (color == Colors.orange) return Colors.orange.shade50;
    if (color == Colors.purple) return Colors.purple.shade50;
    return Colors.grey.shade50;
  }

  Color get _darkColor {
    if (color == Colors.blue) return Colors.blue.shade900;
    if (color == Colors.green) return Colors.green.shade900;
    if (color == Colors.orange) return Colors.orange.shade900;
    if (color == Colors.purple) return Colors.purple.shade900;
    return Colors.grey.shade900;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _lightColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

