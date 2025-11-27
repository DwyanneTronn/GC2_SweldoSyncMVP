import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'payroll_home_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isNewUser;

  const SubscriptionScreen({super.key, this.isNewUser = false});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  List<dynamic> _plans = [];
  Map<String, dynamic>? _currentSubscription;
  bool _isLoading = true;
  String? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final plans = await ApiService.getSubscriptionPlans();
      Map<String, dynamic>? subscription;
      try {
        subscription = await ApiService.getSubscription();
      } catch (e) {
        // No subscription yet
      }

      setState(() {
        _plans = plans;
        _currentSubscription = subscription?['subscription'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleSubscribe(String planId) async {
    setState(() => _isLoading = true);

    try {
      await ApiService.createSubscription(plan: planId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription created! Payment processing...'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PayrollHomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
        automaticallyImplyLeading: !widget.isNewUser,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isNewUser)
                    Card(
                      color: Colors.blue.shade50,
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'Welcome! Please select a subscription plan to get started.',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (_currentSubscription != null) ...[
                    const SizedBox(height: 16),
                    Card(
                      color: Colors.green.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Subscription',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text('Plan: ${_currentSubscription!['plan']}'),
                            Text('Status: ${_currentSubscription!['status']}'),
                            Text('Price: ₱${_currentSubscription!['price']}/month'),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const Text(
                    'Available Plans',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._plans.map((plan) => _buildPlanCard(plan)),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSelected = _selectedPlan == plan['id'];
    final isCurrentPlan = _currentSubscription?['plan'] == plan['id'];

    return Card(
      elevation: isSelected ? 4 : 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isCurrentPlan
            ? null
            : () => setState(() => _selectedPlan = plan['id']),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.blue, width: 2)
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    plan['name'],
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₱${plan['price']}/month',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...(plan['features'] as List).map((feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(feature)),
                      ],
                    ),
                  )),
              const SizedBox(height: 16),
              if (isCurrentPlan)
                const Text(
                  'Current Plan',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (isSelected)
                ElevatedButton(
                  onPressed: () => _handleSubscribe(plan['id']),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: const Text('Subscribe Now'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

