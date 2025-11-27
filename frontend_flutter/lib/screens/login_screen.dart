import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'subscription_screen.dart';
import 'payroll_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true; // Toggle between login and register

  // Registration fields
  final _nameController = TextEditingController();
  final _companyNameController = TextEditingController();
  String _selectedIndustry = 'standard';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await AuthService.saveAuthData(response['token'], response['user']);
      ApiService.setAuthToken(response['token']);

      if (mounted) {
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

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await ApiService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        companyName: _companyNameController.text.trim(),
        industry: _selectedIndustry,
      );

      await AuthService.saveAuthData(response['token'], response['user']);
      ApiService.setAuthToken(response['token']);

      if (mounted) {
        // Navigate to subscription screen after registration
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const SubscriptionScreen(isNewUser: true),
          ),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.monetization_on, size: 64, color: Colors.blue),
                  const SizedBox(height: 16),
                  Text(
                    _isLogin ? 'Welcome to SweldoSync' : 'Create Account',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (!_isLogin) ...[
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Company name is required' : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedIndustry,
                      decoration: const InputDecoration(
                        labelText: 'Industry',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'standard', child: Text('Standard')),
                        DropdownMenuItem(value: 'bpo', child: Text('BPO')),
                        DropdownMenuItem(value: 'airline', child: Text('Airline')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedIndustry = value);
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Email is required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Password is required' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : (_isLogin ? _handleLogin : _handleRegister),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isLogin ? 'Login' : 'Register'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _isLogin = !_isLogin),
                    child: Text(_isLogin
                        ? 'Don\'t have an account? Register'
                        : 'Already have an account? Login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

