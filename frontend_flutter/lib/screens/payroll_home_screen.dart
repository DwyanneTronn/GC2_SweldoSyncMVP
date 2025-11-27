import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'analytics_screen.dart';
import 'payroll_history_screen.dart';

enum AppView { dashboard, input, summary }
enum Industry { standard, bpo, airline }

class Employee {
  String id;
  String name;
  String role;
  double basic;
  Map<String, double> inputs;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.basic,
    required this.inputs,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'basic': basic,
        'inputs': inputs,
      };

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['_id'] ?? json['id'].toString(),
      name: json['name'],
      role: json['role'],
      basic: (json['basicSalary'] ?? json['basic']).toDouble(),
      inputs: {'val1': 0, 'val2': 0, 'val3': 0},
    );
  }
}

class Payslip {
  final String name;
  final double basicEarned;
  final double variablePay;
  final String variableLabel;
  final double deductions;
  final double netPay;

  Payslip({
    required this.name,
    required this.basicEarned,
    required this.variablePay,
    required this.variableLabel,
    required this.deductions,
    required this.netPay,
  });

  factory Payslip.fromJson(Map<String, dynamic> json) {
    return Payslip(
      name: json['name'],
      basicEarned: (json['basicEarned'] as num).toDouble(),
      variablePay: (json['variablePay'] as num).toDouble(),
      variableLabel: json['variableLabel'],
      deductions: (json['deductions'] as num).toDouble(),
      netPay: (json['netPay'] as num).toDouble(),
    );
  }
}

class Holiday {
  final String date;
  final String name;
  Holiday({required this.date, required this.name});

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(date: json['date'], name: json['name']);
  }
}

class PayrollHomeScreen extends StatefulWidget {
  const PayrollHomeScreen({super.key});

  @override
  State<PayrollHomeScreen> createState() => _PayrollHomeScreenState();
}

class _PayrollHomeScreenState extends State<PayrollHomeScreen> {
  AppView _currentView = AppView.dashboard;
  Industry _industry = Industry.standard;
  bool _isLoading = false;
  bool _isFetchingHolidays = false;
  bool _isLoadingEmployees = false;

  final String _payPeriod = "October 16-31, 2025";
  List<Employee> _employees = [];
  List<Payslip> _calculatedPayslips = [];
  List<Holiday> _holidays = [];

  Map<Industry, Map<String, dynamic>> get _industryConfig {
    return {
      Industry.standard: {
        'label1': 'Days Worked',
        'label2': 'Overtime (Hrs)',
        'label3': 'Holiday OT (Hrs)',
        'color': Colors.blue.shade700,
      },
      Industry.bpo: {
        'label1': 'Days Worked',
        'label2': 'Night Diff (Hrs)',
        'label3': 'Holiday OT (Hrs)',
        'color': Colors.purple.shade700,
      },
      Industry.airline: {
        'label1': 'Base Pay % (1=100%)',
        'label2': 'Flight Hours',
        'label3': 'Holiday Flight (Hrs)',
        'color': Colors.lightBlue.shade700,
      },
    };
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _fetchHolidays(),
      _fetchEmployees(),
    ]);
  }

  Future<void> _fetchHolidays() async {
    setState(() => _isFetchingHolidays = true);
    try {
      final holidayData = await ApiService.getHolidays();
      setState(() {
        _holidays = holidayData.map((json) => Holiday.fromJson(json)).toList();
      });
    } catch (e) {
      // Silently fail for holidays
    } finally {
      setState(() => _isFetchingHolidays = false);
    }
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoadingEmployees = true);
    try {
      final employeeData = await ApiService.getEmployees();
      setState(() {
        _employees = employeeData
            .map((json) => Employee.fromJson(json))
            .toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load employees: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isLoadingEmployees = false);
    }
  }

  void _showAddEmployeeDialog() {
    final employeeIdController = TextEditingController();
    final nameController = TextEditingController();
    final roleController = TextEditingController();
    final basicSalaryController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Employee'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID',
                        hintText: 'e.g., EMP001',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        hintText: 'e.g., Juan Dela Cruz',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: roleController,
                      decoration: const InputDecoration(
                        labelText: 'Role/Position',
                        hintText: 'e.g., Staff, Manager',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: basicSalaryController,
                      decoration: const InputDecoration(
                        labelText: 'Basic Salary (₱)',
                        hintText: 'e.g., 25000',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // Validate inputs
                          if (employeeIdController.text.trim().isEmpty ||
                              nameController.text.trim().isEmpty ||
                              roleController.text.trim().isEmpty ||
                              basicSalaryController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all fields'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          final basicSalary =
                              double.tryParse(basicSalaryController.text);
                          if (basicSalary == null || basicSalary <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a valid salary amount'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);

                          try {
                            await ApiService.createEmployee(
                              employeeId: employeeIdController.text.trim(),
                              name: nameController.text.trim(),
                              role: roleController.text.trim(),
                              basicSalary: basicSalary,
                            );

                            if (mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Employee added successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              // Refresh employee list
                              _fetchEmployees();
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add Employee'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _calculatePayroll() async {
    setState(() => _isLoading = true);

    try {
      final employeesData = _employees.map((e) => e.toJson()).toList();
      final response = await ApiService.calculatePayroll(
        industry: _industry.name,
        employees: employeesData,
        payPeriod: _payPeriod,
      );

      final List<dynamic> payslipList = response['payslips'];
      setState(() {
        _calculatedPayslips =
            payslipList.map((json) => Payslip.fromJson(json)).toList();
        _currentView = AppView.summary;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error: ${e.toString()}');
      }
      setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('Okay'),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.monetization_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('SweldoSync'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PayrollHistoryScreen()),
              );
            },
            tooltip: 'Payroll History',
          ),
          IconButton(
            icon: const Icon(Icons.subscriptions),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
              );
            },
            tooltip: 'Subscription',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
            tooltip: 'Logout',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<Industry>(
              value: _industry,
              underline: Container(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              onChanged: (Industry? newValue) {
                if (newValue != null) {
                  setState(() {
                    _industry = newValue;
                    for (var emp in _employees) {
                      emp.inputs = {'val1': 0, 'val2': 0, 'val3': 0};
                    }
                  });
                }
              },
              items: Industry.values.map((Industry industry) {
                return DropdownMenuItem<Industry>(
                  value: industry,
                  child: Text(
                    industry.name[0].toUpperCase() + industry.name.substring(1),
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Calculating Payroll...'),
          ],
        ),
      );
    }

    switch (_currentView) {
      case AppView.dashboard:
        return _buildDashboardView();
      case AppView.input:
        return _buildInputView();
      case AppView.summary:
        return _buildSummaryView();
    }
  }

  Widget _buildDashboardView() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Upcoming Payroll',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text(_payPeriod,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Chip(
                  label: Text('Active', style: TextStyle(color: Colors.green)),
                  backgroundColor: Color(0xFFD1FAE5),
                ),
                const SizedBox(width: 8),
                Text('${_employees.length} Employees queued',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('Add Employee'),
                    onPressed: _showAddEmployeeDialog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.analytics),
                    label: const Text('Analytics'),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _industryConfig[_industry]!['color'],
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _employees.isEmpty
                        ? null
                        : () => setState(() => _currentView = AppView.input),
                    child: Text(
                      _employees.isEmpty
                          ? 'No Employees - Add employees first'
                          : 'Start Payroll Run',
                      style: const TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoadingEmployees)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputView() {
    final config = _industryConfig[_industry]!;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Input Data',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Employee'),
                      onPressed: _showAddEmployeeDialog,
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                      onPressed: _fetchEmployees,
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildHolidayBanner(),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                    flex: 3,
                    child: Text('Employee',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const Expanded(
                    flex: 2,
                    child: Text('Basic',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text(config['label1'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: config['color']))),
                Expanded(
                    flex: 2,
                    child: Text(config['label2'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: config['color']))),
                Expanded(
                    flex: 2,
                    child: Text(config['label3'],
                        style: TextStyle(
                            fontWeight: FontWeight.bold, color: config['color']))),
              ],
            ),
          ),
          Expanded(
            child: _employees.isEmpty
                ? const Center(child: Text('No employees found'))
                : ListView.builder(
                    itemCount: _employees.length,
                    itemBuilder: (context, index) {
                      final emp = _employees[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(emp.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  Text(emp.role,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                            Expanded(
                                flex: 2,
                                child: Text('₱${emp.basic.toStringAsFixed(0)}')),
                            Expanded(
                              flex: 2,
                              child: _InputBox(
                                initialValue: emp.inputs['val1']!,
                                onChanged: (val) => emp.inputs['val1'] = val,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _InputBox(
                                initialValue: emp.inputs['val2']!,
                                onChanged: (val) => emp.inputs['val2'] = val,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _InputBox(
                                initialValue: emp.inputs['val3']!,
                                onChanged: (val) => emp.inputs['val3'] = val,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => setState(() => _currentView = AppView.dashboard),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: config['color'],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16)),
                  onPressed: _calculatePayroll,
                  child: const Text('Calculate Payroll',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHolidayBanner() {
    if (_isFetchingHolidays) {
      return Container(
        color: Colors.blue.shade50,
        padding: const EdgeInsets.all(12),
        child: const Center(child: Text('Loading Holidays...')),
      );
    }
    if (_holidays.isEmpty) {
      return Container();
    }

    final upcoming = _holidays
        .where((h) {
          try {
            return DateTime.parse(h.date).isAfter(DateTime.now());
          } catch (e) {
            return false;
          }
        })
        .take(3)
        .map((h) => "${h.name} (${h.date})")
        .join(', ');

    return Container(
      color: Colors.blue.shade50,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Upcoming Holidays: $upcoming. Remember to input Holiday OT.',
              style: TextStyle(color: Colors.blue.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryView() {
    final totalCost =
        _calculatedPayslips.fold<double>(0, (sum, p) => sum + p.netPay);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: const Color(0xFFF0FDF4),
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Calculation Complete',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534))),
                    Text('Review before disbursement.',
                        style: TextStyle(color: Color(0xFF15803D))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total Payroll Cost',
                        style: TextStyle(color: Color(0xFF15803D))),
                    Text('₱${totalCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF166534))),
                  ],
                )
              ],
            ),
          ),
          Container(
            color: Colors.grey.shade100,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const Expanded(
                    flex: 2,
                    child: Text('Employee',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('Basic',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 1,
                    child: Text(
                        _calculatedPayslips.isNotEmpty
                            ? _calculatedPayslips[0].variableLabel
                            : 'Variable',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 1,
                    child: Text('Deductions',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
                Expanded(
                    flex: 1,
                    child: Text('Net Pay',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _calculatedPayslips.length,
              itemBuilder: (context, index) {
                final p = _calculatedPayslips[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(
                          flex: 1,
                          child: Text('₱${p.basicEarned.toStringAsFixed(2)}',
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 1,
                          child: Text('+₱${p.variablePay.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.green),
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 1,
                          child: Text('-₱${p.deductions.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.red),
                              textAlign: TextAlign.right)),
                      Expanded(
                          flex: 1,
                          child: Text('₱${p.netPay.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.right)),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton(
                  onPressed: () => setState(() => _currentView = AppView.input),
                  child: const Text('Back to Edit'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 16)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('This would trigger bank disbursement API!')),
                    );
                  },
                  child: const Text('Approve & Disburse',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _InputBox extends StatefulWidget {
  final double initialValue;
  final ValueChanged<double> onChanged;

  const _InputBox({required this.initialValue, required this.onChanged});

  @override
  State<_InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<_InputBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue.toString());
  }

  @override
  void didUpdateWidget(_InputBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue.toString() != _controller.text) {
      _controller.text = widget.initialValue.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 8),
        ),
        onChanged: (value) {
          widget.onChanged(double.tryParse(value) ?? 0);
        },
      ),
    );
  }
}

