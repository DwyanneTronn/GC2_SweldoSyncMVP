// This is your entire Flutter application.
// It replaces your index.html file.
// It handles the UI, and calls your backend server for calculations.

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb; // To check if web

// --- Configuration ---
// This URL must match the port your backend server is running on.
// For web, 'localhost' works. For Android emulator, use '10.0.2.2'.
const String baseApiUrl = 'https://gc2-sweldosyncmvp.onrender.com/api'
const String calculateApiUrl = '$baseApiUrl/calculate';
const String holidaysApiUrl = '$baseApiUrl/holidays'; // <-- NEW

void main() {
  runApp(const SweldoSyncApp());
}

// ... (SweldoSyncApp StatelessWidget remains the same) ...
// ... (Data Models: Employee, Payslip remain the same) ...
// ... (Enums: AppView, Industry remain the same) ...

class SweldoSyncApp extends StatelessWidget {
  const SweldoSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SweldoSync MVP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter', // Make sure you add Inter font to pubspec.yaml if you want it
        scaffoldBackgroundColor: const Color(0xFFF8FAFC), // slate-50
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 1,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Color(0xFF1E293B), // slate-800
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const PayrollHomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --- Data Models ---
// These classes define the "shape" of our data, just like in the HTML.

enum AppView { dashboard, input, summary }
enum Industry { standard, bpo, airline }

class Employee {
  int id;
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

  // Used to send data to the server
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'basic': basic,
        'inputs': inputs,
      };
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

  // Used to parse data from the server
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

// NEW: Holiday Data Model
class Holiday {
  final String date;
  final String name;
  Holiday({required this.date, required this.name});
  
  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(date: json['date'], name: json['name']);
  }
}

// --- Main App State Management ---
class PayrollHomeScreen extends StatefulWidget {
  const PayrollHomeScreen({super.key});

  @override
  State<PayrollHomeScreen> createState() => _PayrollHomeScreenState();
}

class _PayrollHomeScreenState extends State<PayrollHomeScreen> {
  // This is the "STATE" object from your index.html
  AppView _currentView = AppView.dashboard;
  Industry _industry = Industry.standard;
  bool _isLoading = false;
  bool _isFetchingHolidays = false; // <-- NEW

  final String _payPeriod = "October 16-31, 2025";

  List<Employee> _employees = [
    Employee(id: 1, name: "Juan Dela Cruz", role: "Staff", basic: 25000, inputs: {'val1': 0, 'val2': 0, 'val3': 0}), // <-- NEW
    Employee(id: 2, name: "Maria Santos", role: "Manager", basic: 45000, inputs: {'val1': 0, 'val2': 0, 'val3': 0}), // <-- NEW
    Employee(id: 3, name: "Capt. Ri", role: "Senior Pilot", basic: 80000, inputs: {'val1': 0, 'val2': 0, 'val3': 0}), // <-- NEW
  ];

  List<Payslip> _calculatedPayslips = [];
  List<Holiday> _holidays = []; // <-- NEW

  // This is the "Strategy" config, but only for UI labels.
  // The *calculation* logic is now on the server.
  Map<Industry, Map<String, dynamic>> get _industryConfig {
    return {
      Industry.standard: {
        'label1': 'Days Worked',
        'label2': 'Overtime (Hrs)',
        'label3': 'Holiday OT (Hrs)', // <-- NEW
        'color': Colors.blue.shade700,
      },
      Industry.bpo: {
        'label1': 'Days Worked',
        'label2': 'Night Diff (Hrs)',
        'label3': 'Holiday OT (Hrs)', // <-- NEW
        'color': Colors.purple.shade700,
      },
      Industry.airline: {
        'label1': 'Base Pay % (1=100%)',
        'label2': 'Flight Hours',
        'label3': 'Holiday Flight (Hrs)', // <-- NEW
        'color': Colors.lightBlue.shade700,
      },
    };
  }

  @override
  void initState() {
    super.initState();
    _fetchHolidays(); // <-- NEW: Fetch holidays on app start
  }

  // --- API Call Functions ---

  // NEW: Fetch Holidays API Call
  Future<void> _fetchHolidays() async {
    setState(() => _isFetchingHolidays = true);
    try {
      final response = await http.get(Uri.parse(holidaysApiUrl));
      if (response.statusCode == 200) {
        final List<dynamic> holidayData = json.decode(response.body);
        setState(() {
          _holidays = holidayData.map((json) => Holiday.fromJson(json)).toList();
        });
      } else {
         _showErrorDialog('Failed to load holidays: ${response.body}');
      }
    } catch (e) {
      _showErrorDialog('Network Error: Could not fetch holidays. Is the backend server running?');
    } finally {
      setState(() => _isFetchingHolidays = false);
    }
  }

  Future<void> _calculatePayroll() async {
    setState(() => _isLoading = true);

    try {
      final body = json.encode({
        'industry': _industry.name, // "standard", "bpo", or "airline"
        'employees': _employees.map((e) => e.toJson()).toList(),
      });

      final response = await http.post(
        Uri.parse(calculateApiUrl), // <-- Updated URL
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> payslipList = data['payslips'];
        setState(() {
          _calculatedPayslips = payslipList.map((json) => Payslip.fromJson(json)).toList();
          _currentView = AppView.summary;
          _isLoading = false;
        });
      } else {
        // Handle server error
        _showErrorDialog('Server Error: ${response.body}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      // Handle network error (e.g., backend server is not running)
      _showErrorDialog(
          'Network Error: Could not connect to backend. Is the server running on $calculateApiUrl?');
      setState(() => _isLoading = false);
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Calculation Failed'),
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

  // --- UI Building ---

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
          // This is the Industry Switcher Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: DropdownButton<Industry>(
              value: _industry,
              underline: Container(), // Removes underline
              icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
              onChanged: (Industry? newValue) {
                if (newValue != null) {
                  setState(() {
                    _industry = newValue;
                    // Reset inputs
                    for (var emp in _employees) {
                      emp.inputs = {'val1': 0, 'val2': 0, 'val3': 0}; // <-- NEW
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
          constraints: const BoxConstraints(maxWidth: 1200), // max-w-7xl
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            // This is the "View" switcher
            child: _buildCurrentView(),
          ),
        ),
      ),
    );
  }

  // This function decides which screen to show
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

  // --- View 1: Dashboard ---
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
            const Text('Upcoming Payroll', style: TextStyle(fontSize: 18, color: Colors.grey)),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _industryConfig[_industry]!['color'],
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => setState(() => _currentView = AppView.input),
              child: const Text('Start Payroll Run',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // --- View 2: Input Form ---
  Widget _buildInputView() {
    final config = _industryConfig[_industry]!;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header
          Container(
            color: Colors.grey.shade50,
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Input Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                OutlinedButton.icon(
                  icon: const Icon(Icons.file_upload, size: 16),
                  label: const Text('Simulate Import'),
                  onPressed: () {
                     // This is the "Simulate Bulk Import" logic from your prototype
                     setState(() {
                       _employees = List.generate(50, (i) {
                         final randomBasic = 20000 + (i * 1000) % 30000;
                         return Employee(
                           id: i + 1,
                           name: 'Employee $i',
                           role: 'Associate',
                           basic: randomBasic.toDouble(),
                           inputs: {'val1': _industry == Industry.airline ? 1 : 11, 'val2': (i % 5).toDouble(), 'val3': (i % 10).toDouble()}, // <-- NEW
                         );
                       });
                     });
                  },
                ),
              ],
            ),
          ),

          // NEW: Holiday Banner
          _buildHolidayBanner(),
          
          // Table Header
          Container(
             color: Colors.grey.shade100,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             child: Row(
               children: [
                 const Expanded(flex: 3, child: Text('Employee', style: TextStyle(fontWeight: FontWeight.bold))), // <-- Adjusted flex
                 const Expanded(flex: 2, child: Text('Basic', style: TextStyle(fontWeight: FontWeight.bold))), // <-- Adjusted flex
                 Expanded(flex: 2, child: Text(config['label1'], style: TextStyle(fontWeight: FontWeight.bold, color: config['color']))), // <-- Adjusted flex
                 Expanded(flex: 2, child: Text(config['label2'], style: TextStyle(fontWeight: FontWeight.bold, color: config['color']))), // <-- Adjusted flex
                 Expanded(flex: 2, child: Text(config['label3'], style: TextStyle(fontWeight: FontWeight.bold, color: config['color']))), // <-- NEW
               ],
             ),
          ),

          // Table Body (Employee List)
          Expanded(
            child: ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (context, index) {
                final emp = _employees[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3, // <-- Adjusted flex
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(emp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(emp.role, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(flex: 2, child: Text('₱${emp.basic.toStringAsFixed(0)}')), // <-- Adjusted flex
                      Expanded(
                        flex: 2, // <-- Adjusted flex
                        child: _InputBox(
                          initialValue: emp.inputs['val1']!,
                          onChanged: (val) => emp.inputs['val1'] = val,
                        ),
                      ),
                      Expanded(
                        flex: 2, // <-- Adjusted flex
                        child: _InputBox(
                          initialValue: emp.inputs['val2']!,
                          onChanged: (val) => emp.inputs['val2'] = val,
                        ),
                      ),
                      // NEW: Holiday Input Box
                      Expanded(
                        flex: 2, // <-- Adjusted flex
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
          
          // Footer / Actions
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
                  style: ElevatedButton.styleFrom(backgroundColor: config['color'], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  onPressed: _calculatePayroll,
                  child: const Text('Calculate Payroll', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // NEW: Holiday Banner Widget
  Widget _buildHolidayBanner() {
    if (_isFetchingHolidays) {
      return Container(
        color: Colors.blue.shade50,
        padding: const EdgeInsets.all(12),
        child: const Center(child: Text('Loading Holidays...')),
      );
    }
    if (_holidays.isEmpty) {
      return Container(); // Don't show if empty or failed
    }

    // Get the next 2-3 holidays
    final upcoming = _holidays.where((h) {
      try {
        return DateTime.parse(h.date).isAfter(DateTime.now());
      } catch (e) { return false; }
    }).take(3).map((h) => "${h.name} (${h.date})").join(', ');

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


  // --- View 3: Summary ---
  Widget _buildSummaryView() {
    final totalCost = _calculatedPayslips.fold<double>(0, (sum, p) => sum + p.netPay);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Summary Header
           Container(
             color: const Color(0xFFF0FDF4), // green-50
             padding: const EdgeInsets.all(20),
             child: Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 const Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     Text('Calculation Complete', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                     Text('Review before disbursement.', style: TextStyle(color: Color(0xFF15803D))),
                   ],
                 ),
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     const Text('Total Payroll Cost', style: TextStyle(color: Color(0xFF15803D))),
                     Text('₱${totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                   ],
                 )
               ],
             ),
           ),
          
          // Table Header
          Container(
             color: Colors.grey.shade100,
             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
             child: Row(
               children: [
                 const Expanded(flex: 2, child: Text('Employee', style: TextStyle(fontWeight: FontWeight.bold))),
                 Expanded(flex: 1, child: Text('Basic', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                 Expanded(flex: 1, child: Text(_calculatedPayslips.isNotEmpty ? _calculatedPayslips[0].variableLabel : 'Variable', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)), // <-- Safer
                 Expanded(flex: 1, child: Text('Deductions', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                 Expanded(flex: 1, child: Text('Net Pay', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
               ],
             ),
          ),
          
          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: _calculatedPayslips.length,
              itemBuilder: (context, index) {
                final p = _calculatedPayslips[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(flex: 1, child: Text('₱${p.basicEarned.toStringAsFixed(2)}', textAlign: TextAlign.right)),
                      Expanded(flex: 1, child: Text('+₱${p.variablePay.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green), textAlign: TextAlign.right)),
                      Expanded(flex: 1, child: Text('-₱${p.deductions.toStringAsFixed(2)}', style: const TextStyle(color: Colors.red), textAlign: TextAlign.right)),
                      Expanded(flex: 1, child: Text('₱${p.netPay.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                );
              },
            ),
          ),
          
          // Footer / Actions
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
                  onPressed: () {
                     // This would trigger the final step (e.g., bank integration)
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('This would trigger bank disbursement API!')),
                     );
                  },
                  child: const Text('Approve & Disburse', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// A small helper widget for the input text boxes
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

  // NEW: Update controller if the initial value changes (e.g., on Simulate)
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