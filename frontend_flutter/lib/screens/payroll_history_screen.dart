import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PayrollHistoryScreen extends StatefulWidget {
  const PayrollHistoryScreen({super.key});

  @override
  State<PayrollHistoryScreen> createState() => _PayrollHistoryScreenState();
}

class _PayrollHistoryScreenState extends State<PayrollHistoryScreen> {
  List<dynamic> _payrollRuns = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await ApiService.getPayrollHistory();
      setState(() {
        _payrollRuns = response['payrollRuns'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payroll History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistory,
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
                        onPressed: _loadHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _payrollRuns.isEmpty
                  ? const Center(child: Text('No payroll history available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _payrollRuns.length,
                      itemBuilder: (context, index) {
                        final run = _payrollRuns[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ExpansionTile(
                            leading: _getStatusIcon(run['status']),
                            title: Text(
                              run['payPeriod'] ?? 'Unknown Period',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${run['payslips']?.length ?? 0} employees • ${run['industry']?.toUpperCase() ?? ''}',
                            ),
                            trailing: Text(
                              '₱${(run['totalCost'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildInfoRow('Status', run['status']?.toUpperCase() ?? ''),
                                    _buildInfoRow('Industry', run['industry']?.toUpperCase() ?? ''),
                                    _buildInfoRow('Total Cost', '₱${(run['totalCost'] as num?)?.toStringAsFixed(2) ?? '0.00'}'),
                                    _buildInfoRow('Employees', '${run['payslips']?.length ?? 0}'),
                                    if (run['createdBy'] != null)
                                      _buildInfoRow('Created By', run['createdBy']['name'] ?? ''),
                                    if (run['createdAt'] != null)
                                      _buildInfoRow(
                                        'Created',
                                        DateTime.parse(run['createdAt']).toLocal().toString().split('.')[0],
                                      ),
                                    if (run['approvedAt'] != null)
                                      _buildInfoRow(
                                        'Approved',
                                        DateTime.parse(run['approvedAt']).toLocal().toString().split('.')[0],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade600),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return const Icon(Icons.check_circle, color: Colors.green);
      case 'calculated':
        return const Icon(Icons.calculate, color: Colors.blue);
      case 'disbursed':
        return const Icon(Icons.payment, color: Colors.purple);
      default:
        return const Icon(Icons.pending, color: Colors.orange);
    }
  }
}

